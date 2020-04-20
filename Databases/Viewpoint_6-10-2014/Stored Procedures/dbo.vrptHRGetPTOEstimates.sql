SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--CREATE PROCEDURE [dbo].[vrptHRGetPTOEstimates]
CREATE PROCEDURE [dbo].[vrptHRGetPTOEstimates]
/**************************************************
* Created:  Charles Wirtz 05/14/08
* Modified: GF 09/05/2010 - issue #141031 changed to use function vfDateOnly
*			HH 09/10/2013 - TFS Bug 61148 removed stored proc exit since Crystal Runtime 2008 will fail on that kind of exit
*
* Used by HR Leave Requests report
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
* 
* Inputs
*   @HRCo			- Company
*	@HRRes			- HRRef
*	@PTOCode		- PTO/Leave Code in HRES table
*
* Output
*	@LastPostDate	- Last Payroll Date
*	@TotalAvailHrs	- Total Available PTO/Leave hours for a specific leave code since last Payroll post date
*	@TotPendHrs		- Total Pending PTO/Leave hours
*	@TotBalHrs		- Total Balance PTO/Leave hours
*   @rcode			- return code
*	@errmsg			- error message
*
****************************************************/
--	(@HRCo bCompany = 1
--	, @HRRes bHRRef = 1
--	, @PTOCode VARCHAR(10) = 'PTO'
--	, @LastPRPostDate bDate output,
--     @TotAvailHrs bHrs output, @TotPendHrs bHrs output, @TotBalHrs bHrs output,
--     @errmsg varchar(255) output) 
	(@HRCo bCompany = 1, @HRRes bHRRef = 99699, @PTOCode VARCHAR(10) = 'SICK')
     
 

AS
SET NOCOUNT ON
 

DECLARE @PRCo			bCompany,
		@PREmp			bEmployee,
		@Today			bDate,
		@NewPendHrs		bHrs,
		@AppPendHrs		bHrs,
		@AppTakenHrs	bHrs,
		@rcode			int,
		@LastPRPostDate bDate,
		@TotAvailHrs	bHrs, 
		@TotPendHrs		bHrs,
		@TotBalHrs		bHrs,
		@errmsg			varchar(255);

	----------------
	-- SET VALUES --
	----------------
	SET @rcode = 0
    SET @TotAvailHrs = 0
	SET @TotPendHrs = 0
	SET @TotBalHrs = 0
	----#141031
	SET @Today = dbo.vfDateOnly()
	SET @TotAvailHrs = 0
	SET @NewPendHrs = 0
	SET @AppPendHrs = 0
	SET @AppTakenHrs = 0


	----------------------------
	-- GET CORRECT PR Company -- 
	----------------------------
	SELECT @PRCo = PRCo, @PREmp = PREmp 
	  FROM HRRM WITH (NOLOCK)
	 WHERE HRCo = @HRCo
	   AND HRRef = @HRRes

	-----------------------------------------------------------------
	-- GET TOTAL HOURS AVAILABLE FROM THE LATEST PAYROLL POST DATE --
	-----------------------------------------------------------------
	  SELECT @TotAvailHrs = l.AvailBal, @LastPRPostDate = MAX(h.PostDate)
		FROM PREL l WITH (NOLOCK)
		JOIN PRLH h WITH (NOLOCK)
		  ON l.PRCo = h.PRCo AND l.Employee = h.Employee AND l.LeaveCode = h.LeaveCode
		JOIN HRCM m WITH (NOLOCK)
		  ON m.PRLeaveCode = h.LeaveCode	  
	   WHERE l.PRCo = @PRCo
		 AND l.Employee = @PREmp
		 AND m.Code = @PTOCode
		 AND m.PTOTypeYN = 'Y'
	GROUP BY h.LeaveCode, l.AvailBal

	--------------------------------------- --
	-- GET NEW REQUESTS NOT YET APPROVED    --
	-- ------------------------------------ --
	-- DO NOT HAVE TO WORRY ABOUT NAY DATES --
	------------------------------------------
	SELECT @NewPendHrs = ISNULL(SUM(Hours), 0)
	  FROM HRES 
	 WHERE ScheduleCode = @PTOCode
	   AND HRCo = @HRCo
	   AND HRRef = @HRRes
	   AND [Status] = 'N'	

	--	------------------------------------------
	--	GET APPROVED REQUESTS NOT YET TAKEN     --
	--	(Request Date > Today's Date)           --
	--  --------------------------------------- --
	--  DO NOT HAVE TO WORRY ABOUT PR POST DATE --
	--	------------------------------------------
	SELECT @AppPendHrs = ISNULL(SUM(Hours), 0)
	  FROM HRES 
	 WHERE ScheduleCode = @PTOCode
	   AND HRCo = @HRCo
	   AND HRRef = @HRRes
	   AND [Status] = 'A'
	   AND Date > @Today

	--	---------------------------------
	--	GET APPROVED REQUESTS TAKEN    --
	--	(Request Date <= Today's Date) --
	--  ------------------------------ --
	--  MUST WORRY ABOUT PR POST DATE  --
	--  --------------------------------------------------------------------------------
	--  EVEN THOUGH PTO/LEAVE MAY HAVE BEEN TAKEN IT WILL BE COUNTED AS PENDING UNTIL --
	--  THE PR POST DATE > PTO/LEAVE DATE.											  --	
    --	--------------------------------------------------------------------------------
	SELECT @AppTakenHrs = ISNULL(SUM(Hours), 0)
	  FROM HRES 
	 WHERE ScheduleCode = @PTOCode
	   AND HRCo = @HRCo
	   AND HRRef = @HRRes
	   AND [Status] = 'A'
	   AND Date <= @Today
       AND Date > ISNULL(@LastPRPostDate, '1980-01-01') ---- NO IDEA WHAT TO PUT HERE IF NULL - ANYTHING?


	--------------------------
	-- PERFORM CALCULATIONS --
	--------------------------
	SET @TotPendHrs = cast((@NewPendHrs + @AppPendHrs + @AppTakenHrs) as varchar(20))
	SET @TotBalHrs = cast((@TotAvailHrs - @TotPendHrs) as varchar(20))

select    @PTOCode as PTOCode
		, @TotAvailHrs as TotAvailHrs
		, @TotPendHrs as TotPendHrs
		, @TotBalHrs as TotBalHr
		, @AppTakenHrs as AppTakenHrs
		, @LastPRPostDate as LastPRPostDate
vspexit:
--	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vrptHRGetPTOEstimates] TO [public]
GO
