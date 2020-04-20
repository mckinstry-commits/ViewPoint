SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPR_AU_ETP_CapAmtsGet]
/************************************************************************
* CREATED:	DAN SO 03/07/2013 - TFS: User Story 39860:PR ETP Redundancy Tax Calculations - 1
*							  - Co-developed with Ellen BN   
* MODIFIED:
*
* Purpose of Stored Procedure
*
*    Get AU ETP Cap Amts
*    
* 
* INPUT
*	@ATOETPType			- ATO Type 
*   @SubjectAmt			- Subject Amount
*	@ETPAmt				- ETP Standard portion of the ETP
*	@ETPCapAmt			- ETP Cap Amount
*	@WholeIncomeCapAmt	- Whole Income Cap Amount
*	
*
* OUTPUT
*	@UpToCapAmt			- Up To Cap Amount (ETP or Whole of Income Cap)
*	@AboveCapAmt		- Above Cap Amount (ETP or Whole of Income Cap)
*	@CapAmt				- ETP or Whole of Income Cap Amount (the amount used in calculations)
*	@rcode				- Return Code - (0)Successful, (1)Failure
*	@ErrorMsg			- Error Message
*************************************************************************/
(@ATOETPType VARCHAR(4) = NULL, 
 @SubjectAmt bDollar = NULL, @ETPAmt bDollar = NULL, 
 @ETPCapAmt bDollar = NULL, @WholeIncomeCapAmt bDollar = NULL,
 @UpToCapAmt bDollar OUTPUT, @AboveCapAmt bDollar OUTPUT, @CapAmt bDollar OUTPUT,	
 @ErrorMsg VARCHAR(255) OUT)

AS

BEGIN TRY

	SET NOCOUNT ON

    DECLARE @cWIC bDollar,	-- calculated Whole Income Cap
			@RetVal INT,
			@rcode INT


	------------------
	-- PRIME VALUES --
	------------------
	SET @UpToCapAmt = 0.00
	SET @AboveCapAmt = 0.00
	SET @CapAmt = 0.00
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

	IF @SubjectAmt IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Subject Amount!'
			GOTO vspExit
		END

	IF @ETPAmt IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing ETP Amount!'
			GOTO vspExit
		END
				
	IF @ETPCapAmt IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing ETP Cap!'
			GOTO vspExit
		END
				
	IF @WholeIncomeCapAmt IS NULL
		BEGIN
			SET @rcode = 1
			SET @ErrorMsg = 'Missing Whole Income Cap!'
			GOTO vspExit
		END	
	
		
	--------------------------
	-- DETERMINE CAP TO USE --
	--------------------------
	SET @CapAmt = @ETPCapAmt

	-- FOR ETP Category - USE THE SMALLER OF THE TWO CAPS --
	IF (@ATOETPType = 'ETP') -- ONLY FOR STANDARD ETPs
		BEGIN

			SET @cWIC = (@WholeIncomeCapAmt - @SubjectAmt) 
		
			-------------------------
			-- USE CALCULATED CAP? --   
			-------------------------
			IF (@cWIC < @ETPCapAmt)
				BEGIN
					
					-- IF CALCULATE AMT IS NEGATIVE - SET TO ZERO --
					IF @cWIC < 0 SET @CapAmt = 0
					ELSE		 SET @CapAmt = @cWIC  

				END
		END

	--------------------------------------
	-- DETERMINE OVER/UNDER CAP AMOUNTS --
	--------------------------------------
	IF @CapAmt > @ETPAmt
		BEGIN
			SET @UpToCapAmt = @ETPAmt
		END
	ELSE
		BEGIN
			SET @UpToCapAmt = @CapAmt
			SET @AboveCapAmt = (@ETPAmt - @CapAmt)
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
GRANT EXECUTE ON  [dbo].[vspPR_AU_ETP_CapAmtsGet] TO [public]
GO
