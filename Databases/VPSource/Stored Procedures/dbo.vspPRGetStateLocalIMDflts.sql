SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPRGetStateLocalIMDflts]
/****************************************************************
* CREATED: EN 03/01/10 - D-01065 / #142912 version of vspPRGetStateLocalDflts but just for bspIMBidtekDefaultsPRTB
* MODIFIED:	 
*	
*
* USAGE:
*	Called from "bspIMBidtekDefaultsPRTB" which needed a version of vspPRGetStateLocalDflts that does not
*	throw an invalid job/phase error when the Job is invalid but rather will return blank State and Local Code defaults.
*
* INPUT:
*	@prco
*	@employee
*	@jcco
*	@job
*	
* OUTPUT:
*	@taxstate		Tax State from Job, PR Company Office, or Employee
*	@localcode		LocalCode from Job, PR Company Office, or Employee
*	@unempstate		Unemployment State from Job or Employee
*	@insstate		Insurance State from Job or Employee
*   @errmsg		Error message
*
* RETURN:
*   0		Sucess
*   1		Failure
********************************************************/
(@prco bCompany = null,
 @employee bEmployee = null,
 @jcco bCompany = null,
 @job bJob = null,
 @localcode bLocalCode = null output, 
 @taxstate varchar(4) = null output,
 @unempstate varchar(4) = null output,
 @insstate varchar(4) = null output, 
 @errmsg varchar(200) output
)
	
AS
SET NOCOUNT ON

DECLARE @prtaxstateopt bYN,  
		@prunempstateopt bYN,  
		@prinsstateopt bYN,  
		@prlocalopt bYN,
		@profficestate varchar(4),  
		@profficelocal bLocalCode,  
		@jobstate varchar(4),  
		@joblocal bLocalCode,
		@emptaxstate varchar(4),  
		@empunempstate varchar(4),  
		@empinsstate varchar(4), 
		@emplocalcode bLocalCode,  
		@useempstateopt bYN,  
		@useempunempstateopt bYN,
		@useempinsstateopt bYN,  
		@useemplocalopt bYN

SELECT	@localcode = null,  
		@taxstate = null,  
		@unempstate = null,  
		@insstate = null 

IF @prco IS NULL				
BEGIN
	SELECT @errmsg = 'Missing PR Company.'
	RETURN 1
END
IF ISNULL(@employee, '') = ''		--An empty string past in for Employee would be 0 but evaluates this correctly
BEGIN
	SELECT @errmsg = 'Missing PR Employee.'
	RETURN 1
END
IF @job = ''
BEGIN
	--Issue #140781
	--An empty string past in for Job is bad data coming from the text file.  It happens.
	--It is easier to reset the value to NULL now rather than adjust each occurrance of 
	--@job later and have to retest each condition.
	SET @job = null
END
	
/* Get PR Company information */
SELECT	@prtaxstateopt=TaxStateOpt, 
		@prunempstateopt=UnempStateOpt, 
		@prinsstateopt=InsStateOpt, 
		@prlocalopt=LocalOpt, 
		@profficestate=OfficeState, 
		@profficelocal=OfficeLocal
FROM dbo.bPRCO WITH (NOLOCK) WHERE PRCo=@prco
IF @@ROWCOUNT = 0
BEGIN
	SELECT @errmsg = 'Missing PR Company Info.  Cannot determine State/Local defaults.'
	RETURN 1
END
	
/* Get Job information */
IF ISNULL(@jcco, '') <> '' AND @job IS NOT NULL
BEGIN
	SELECT @jobstate=PRStateCode, @joblocal=PRLocalCode
	FROM dbo.bJCJM WITH (NOLOCK) WHERE JCCo=@jcco AND Job=@job
	IF @@ROWCOUNT = 0
	BEGIN
		--Job is invalid ... return blank state/local values
		RETURN 0
	END
END
	
/* Get Employee information */
SELECT @emptaxstate=ISNULL(WOTaxState,TaxState), @empunempstate=UnempState, @empinsstate=InsState,
	@emplocalcode=ISNULL(WOLocalCode,LocalCode), @useempstateopt=UseState, @useempunempstateopt=UseUnempState,
	@useempinsstateopt=UseInsState, @useemplocalopt=UseLocal
FROM dbo.bPREH WITH (NOLOCK) WHERE PRCo=@prco AND Employee=@employee
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @errmsg = 'Missing PR Employee Info.  Cannot determine State/Local defaults.'
	RETURN 1
	END
	
/*Determine States and LocalCode default values */
-- Tax State
IF @prtaxstateopt = 'Y'
	BEGIN
	IF @job IS NOT NULL SELECT @taxstate = @jobstate		-- use Job State
	IF @job IS NULL SELECT @taxstate = @profficestate		-- use Company Office State when there is no Job

	IF @taxstate IS NOT NULL AND @emptaxstate IS NOT NULL
		BEGIN
		IF @taxstate <> @emptaxstate
			BEGIN
			/* Reciprocal check */
			IF EXISTS(SELECT TOP 1 1 FROM dbo.HQRS WHERE JobState=@taxstate AND ResidentState=@emptaxstate)
				BEGIN
				SELECT @taxstate=@emptaxstate
				END
			END
		END
	END
IF @taxstate IS NULL OR @useempstateopt = 'Y' SELECT @taxstate = @emptaxstate  -- use Employee Tax State

-- Local Code - #132752 revised code to default null local if job posted but no job local specified
IF @prlocalopt = 'Y' 
BEGIN
	IF @job IS NOT NULL SELECT @localcode = @joblocal		-- use Job LocalCode
	IF @job IS NULL SELECT @localcode = @profficelocal		-- use Company Office LocalCode when there is no Job
END

IF (@prlocalopt = 'N' AND @localcode IS NULL) 
	OR (@prlocalopt = 'Y' and @job IS NULL AND @localcode IS NULL) 
	OR @useemplocalopt = 'Y' 
BEGIN
	SELECT @localcode = @emplocalcode  -- use Employee LocalCode
END
	
-- Unemployment State
IF @prunempstateopt = 'Y' SELECT @unempstate = @jobstate	-- use Job State
IF @unempstate IS NULL OR @useempunempstateopt = 'Y' 
BEGIN
	SELECT @unempstate = @empunempstate  -- use Employee Unempl State
END

-- Insurance State and Code
IF @prinsstateopt = 'Y' SELECT @insstate = @jobstate		-- use Job State
IF @insstate IS NULL OR @useempinsstateopt = 'Y' 
BEGIN
	SELECT @insstate = @empinsstate -- use Employee Insur State
END
 
                    	
RETURN 0




GO
GRANT EXECUTE ON  [dbo].[vspPRGetStateLocalIMDflts] TO [public]
GO
