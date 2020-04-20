SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPR_AU_ETP_TaxRatesGet]
/************************************************************************
* CREATED:	DAN SO 03/07/2013 - TFS: User Story 39860:PR ETP Redundancy Tax Calculations - 1
*							  - Co-developed with Ellen BN
* MODIFIED:
*
* Purpose of Stored Procedure
*
*    Get AU ETP Tax Rates 
*    
* 
* INPUT
*	@ATOETPType			- ATO ETP Type (ETPR, ETPV, ETP, ETPD, ETPU)
*	@UnderPresAgePct	- Under Preservation Age Percent
*	@OverPresAgePct		- Over Preservation Age Percent
*	@ExcessCapPct		- Above Cap Percent
*	@DelayPayPct		- Delayed Payment Percent
*	@NoTFNPct			- No Employee TFN Percent
*	@UnderPresAgeYN		- Employee Under the Preservation Age YN
*	@TFNProvidedYN		- Was a TFN provided by the Employee YN
*	@ForeignResYN		- Is the Employee a prescribed Foreign Resident YN
*   @PREndDate		    - Employee Last Payroll Date 
*
* OUTPUT
*	@UpToCapPct			- Rate up to Cap amount
*	@AboveCapPct		- Rate above Cap amount
*	@rcode				- Return Code - (0)Successful, (1)Failure
*	@ErrorMsg			- Error Message
*************************************************************************/
(@ATOETPType CHAR(4) = NULL,
 @UnderPresAgePct bPct = NULL, @OverPresAgePct bPct = NULL, 
 @ExcessCapPct bPct = NULL, @NoTFNPct bPct = NULL, 
 @ForeignResPct bPct = NULL, @DelayPayPct bPct = NULL,
 @UnderPresAgeYN bYN = NULL,  @TFNProvidedYN bYN = NULL, 
 @ForeignResYN bYN = NULL,  @PREndDate bDate = NULL,
 @UpToCapPct bPct OUTPUT, @AboveCapPct bPct OUTPUT, 
 @ErrorMsg VARCHAR(255) OUTPUT)

AS

BEGIN TRY

	SET NOCOUNT ON

    DECLARE 
			@rcode INT


	------------------
	-- PRIME VALUES --
	------------------
    SET @rcode = 0
    SET @ErrorMsg = ''


	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @ATOETPType IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing ATO ETP Type!'
			GOTO vspExit
		END
		
	IF @UnderPresAgePct IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Under Preservation Age Percent!'
			GOTO vspExit
		END
		
	IF @OverPresAgePct IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Over Preservation Age Percent!'
			GOTO vspExit
		END
			
	IF @ExcessCapPct IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Excessive Cap Percent!'
			GOTO vspExit
		END
		
	IF @NoTFNPct IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing No TFN Percent!'
			GOTO vspExit
		END
		
	IF @ForeignResPct IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Foreign Resident Percent!'
			GOTO vspExit
		END
		
	IF @DelayPayPct IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Delayed Payment Percent!'
			GOTO vspExit
		END
			
	IF @UnderPresAgeYN IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Under Preservation Age YN!'
			GOTO vspExit
		END

	IF @TFNProvidedYN IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing TFN Supplied YN!'
			GOTO vspExit
		END
		
	IF @ForeignResYN IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Foreign Resident YN!'
			GOTO vspExit
		END	

	IF @PREndDate IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Last Payroll Ending Date!'
			GOTO vspExit
		END

		
	------------------
	-- SET PERCENTS --
	------------------
	
	-- JUST SETTING THESE PERCENTS - WANTED TO KEEP ALL PERCENT LOGIC IN THIS SP --
	SET @AboveCapPct = @ExcessCapPct
	
	-- PRESERVATION AGE RATE SET --
	SET @UpToCapPct = @OverPresAgePct
	IF UPPER(@UnderPresAgeYN) = 'Y'  SET @UpToCapPct = @UnderPresAgePct
	
	-- DEATH PAY --    
	IF @ATOETPType = 'ETPD'  SET @UpToCapPct = 0.0
		
	-- DETERMINE "Delayed Termimnation Payment -- A PAYMENT MADE OUTSIDE 12 MONTHS -- USED DAYS BECAUSE DATEDIFF IS KIND OF LAME --
	-- OVERRIDE ALL RATES --
	IF DATEDIFF(DAY, @PREndDate, GETDATE()) >= 365 
		BEGIN
			-- BASIC RATE --
			SET @UpToCapPct = @DelayPayPct
			SET @OverPresAgePct = @DelayPayPct
	
			-- TFN/FOREIGN RESIDENT RATE SET --
			IF @TFNProvidedYN = 'N'
				BEGIN
					SET @UpToCapPct = @NoTFNPct
					SET @OverPresAgePct = @NoTFNPct
				
					IF @ForeignResYN = 'Y'
						BEGIN
							SET @UpToCapPct = @ForeignResPct
							SET @OverPresAgePct = @ForeignResPct
						END
				END
		END

END TRY

--------------------
-- ERROR HANDLING --
--------------------
BEGIN CATCH
	SET @rcode = 1
	SET @ErrorMsg = ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE()	
END CATCH

------------------
-- EXIT ROUTINE --
------------------
vspExit:
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPR_AU_ETP_TaxRatesGet] TO [public]
GO
