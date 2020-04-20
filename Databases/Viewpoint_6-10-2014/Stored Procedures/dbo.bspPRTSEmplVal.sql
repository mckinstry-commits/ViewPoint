SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSEmplVal    Script Date: 8/28/99 9:33:19 AM ******/
CREATE            proc [dbo].[bspPRTSEmplVal]

/***********************************************************
* CREATED BY: EN 2/25/03
* MODIFIED By :	EN 04/09/04 - #23514 return empl PRGroup and pass in crew PRGroup for comparison validation
*				mh 06/01/07 - 6.x recode issue 28073 
*				mh 01/25/08 - #126856
*				mh 01/21/10 - #133161 - Change Active Parameter passed into bspPREmplVal from 'X' to 'Y'
*				KK 06/11/12 - B07986/#138868 - Change val proc call from bspPREmplVal to bspPREmplValName so we can use the view 
*											   PREHName validate an employee without violating security perms.
*
* Usage:
*	Used to validate employees being assigned to a crew by either Sort Name or number.
*	Verifies that employee's PR Group matches that of crew if crew's group is set.
*   Otherwise crew group default's from returned employee PR Group (ie. typically 
*   first employee assigned to the crew).
*
* Input params:
*	@prco		PR company
*	@empl		Employee sort name or number
*	@crew		Crew code
*	@jcco		JC Company
*	@job		Job
*	@postdate	Posting Date
*	@shift		Shift Code
*	@tsprgroup	PRGroup assigned to timesheet (usually same as crew pr group)
*
* Output params:
*	@emplout	Employee number
*	@craft		Employee craft
*	@class		Employee class
*	@regrate	Regular pay rate
*	@otrate		Overtime pay rate
*	@dblrate	Doubletime pay rate
*	@prgroup	Employee PR Group
*	@msg		Employee Name or error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
(@prco bCompany, 
 @empl varchar(15), 
 @crew varchar(10)= NULL, 
 @jcco bCompany, 
 @job bJob,
 @postdate bDate, 
 @shift tinyint, 
 @tsprgroup bGroup, 
 @crafttemplate int, 
 @emplout bEmployee = NULL OUTPUT,
 @craft bCraft OUTPUT, 
 @class bClass OUTPUT, 
 @regrate bUnitCost OUTPUT, 
 @otrate bUnitCost OUTPUT, 
 @dblrate bUnitCost OUTPUT, 
 @prgroup bGroup OUTPUT, 
 @msg varchar(60) OUTPUT)
     
AS
SET NOCOUNT ON
     
DECLARE @rcode int, 
		@errmsg varchar(60), 
		@lastname varchar(30), 
		@firstname varchar(30),
     	@crewprgroup bGroup,
     	@regearncode bEDLCode, 
     	@otearncode bEDLCode, 
     	@dblearncode bEDLCode,
     	@crewregec bEDLCode, 
     	@crewotec bEDLCode, 
     	@crewdblec bEDLCode, 
     	@jobcraft bCraft
     
SELECT @rcode = 0
     
/* check required input params */
IF @empl IS NULL
BEGIN
     SELECT @msg = 'Missing Employee.'
     RETURN 1
END

/* B-07986 validate employee bypassing security via the view used in this valproc*/
EXEC @rcode = bspPREmplValName @prco, @empl,'Y',
							   @emplout = @emplout OUTPUT, 
							   @lastname = @lastname OUTPUT,
     						   @firstname = @firstname OUTPUT, 
     						   @msg = @msg OUTPUT
IF @rcode = 1 RETURN 1

--126856 - If @tsprgroup is null check PR Crews(PRCR) and make sure it was entered there.  If there is 
--no PR Group there then raise error. Normally when a Crew TS is created the PRGroup from PR Crews
--defaults in to PRRH.  However, prior to this change you could create a crew with no employees and when
--you create a Crew TS, there was no PR Group to restrict Crew TS Employees to.  
IF @tsprgroup IS NULL
BEGIN
	SELECT @tsprgroup = PRGroup FROM dbo.PRCR (NOLOCK) WHERE PRCo = @prco AND Crew = @crew
	IF @tsprgroup IS NULL
	BEGIN
		SELECT @msg = 'PR Group has not been entered in PR Crews.  Cannot add Employee.'
		RETURN 1
	END
END       

--validate Employee's PR Group against Timesheet's PR Group
SELECT @prgroup = PRGroup, 
	   @craft = Craft, 
	   @class = Class 
FROM PREH WHERE PRCo = @prco AND Employee = @emplout
     
IF @prgroup <> @tsprgroup AND @tsprgroup IS NOT NULL
BEGIN
    SELECT @msg = 'Employee ' + CONVERT(varchar, @emplout) + ' PR Group does not match timesheet PR Group.'
    RETURN 1
END

-- get pay rates
--mh 4/9/2008 - Reviewed with Gary. If CraftTemplate is null coming in leaving it null.
--mh 6.x recode - CraftTemplate from JCJM is passed in as @crafttemplate.  We do not need 
--@template. Altering to only pull from JCJM if for some reason @crafttemplate is null since
--we are not validating input params.

SELECT @regearncode = CrewRegEC, 
	   @otearncode = CrewOTEC, 
	   @dblearncode = CrewDblEC 
FROM PRCO WHERE PRCo = @prco --read company earn codes
     
SELECT @crewregec = RegECOvride, 
	   @crewotec=OTECOvride, 
	   @crewdblec=DblECOvride --check for crew earn code overrides
FROM PRCR WHERE PRCo = @prco AND Crew = @crew
     
IF @crewregec IS NOT NULL SELECT @regearncode=@crewregec --apply overrides if found
IF @crewotec IS NOT NULL SELECT @otearncode=@crewotec
IF @crewdblec IS NOT NULL SELECT @dblearncode=@crewdblec	

--6.x recode.  We only use hours, not rates in Crew Timesheet. No reason to return these. Calling routine just drops
--the output params.  We return a Craft from PREH then in the calling code check for a recip craft based on the Job Craft
--Template.  

--Altering procedure make the check for recip craft.
IF @crafttemplate IS NOT NULL
BEGIN
	EXEC bspPRJobCraftDflt @prco, @craft, @crafttemplate, @jobcraft OUTPUT, @msg
	IF @jobcraft IS NOT NULL
	BEGIN
		SELECT @craft = @jobcraft
		--6.x recode - validate Class against JobCraft.
		IF NOT EXISTS(SELECT 1 FROM PRCC WHERE PRCo = @prco AND Craft = @jobcraft AND Class = @class)
		BEGIN
			SELECT @msg = @class + ' class does not exist for reciprocal craft ' + @jobcraft
			RETURN 1
		END
	END
END

--6.x recode.  Swapped @template for @crafttemplate.  see notes above.
EXEC @rcode = bspPRRateDefault @prco, @emplout, @postdate, @craft, @class, @crafttemplate, @shift,
							   @regearncode, @rate = @regrate OUTPUT, --get regular pay rate
							   @msg = @msg OUTPUT
 IF @rcode <> 0 RETURN 1

EXEC @rcode = bspPRRateDefault @prco, @emplout, @postdate, @craft, @class, @crafttemplate, @shift, 
							   @otearncode, @rate = @otrate OUTPUT, --get overtime pay rate
							   @msg = @msg OUTPUT
 IF @rcode <> 0 RETURN 1

EXEC @rcode = bspPRRateDefault @prco, @emplout, @postdate, @craft, @class, @crafttemplate, @shift, 
							   @dblearncode, @rate = @dblrate OUTPUT, --get doubletime pay rate
							   @msg = @msg OUTPUT
 IF @rcode <> 0 RETURN 1
     
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPRTSEmplVal] TO [public]
GO
