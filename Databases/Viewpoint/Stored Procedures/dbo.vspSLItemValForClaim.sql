SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[vspSLItemValForClaim]
/***********************************************************
* CREATED BY:	GF 09/18/2012 TK-17944
* MODIFIED BY:	
* 
*
* USAGE:
* called from SL Subcontract Claim Items to validate the SL Item to SLIT
* and return info needed for the claim.
*
*
* INPUT PARAMETERS
* @SLCo				SL Company to validate
* @Subcontract		Subcontract to validate
* @ClaimNo			Subcontract Claim No to validate
* @SLItem			Subcontract Item to validate
*
*
* OUTPUT PARAMETERS
* @Description		item description
* @UM				UM
* @CurUnits			Units
* @CurUnitCost		Unit Cost
* @CurCost			Amount
* @TaxType			Tax Type
* @TaxCode			Tax Code
* @TaxGroup			Tax Group
* @TaxRate			Tax Rate from HQTX
* @GSTRate			GST Rate from HQTX
* @WCRetPct			WC Retention Pct
* @PrevClaimUnits
* @PrevClaimAmt
* @PrevApproveUnits
* @PrevApproveAmt
* @PrevApproveRet
* @ClaimToDatePct
* @ClaimToDateUnits
* @ClaimToDateAmt
* @TaxBasisNetRet	AP Company Tax basis net retention flag
* @DefaultCountry	HQ Default Country used for tax basis net retention
* @msg				error message IF error occurs otherwise Description of SL Item
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@SLCo bCompany = 0, @Subcontract varchar(30) = NULL,
 @ClaimNo INT = NULL, @SLItem SMALLINT = NULL,
 @Description bItemDesc = NULL OUTPUT, @UM bUM = NULL OUTPUT,
 @CurUnits bUnits = NULL OUTPUT, @CurUnitCost bUnitCost = NULL OUTPUT,
 @CurCost bDollar = NULL OUTPUT, @TaxType TINYINT = NULL OUTPUT,
 @TaxCode bTaxCode = NULL OUTPUT, @TaxGroup bGroup = NULL OUTPUT,
 @TaxRate bRate = 0 OUTPUT, @GSTRate bRate = 0 OUTPUT,
 @PSTRate bRate = 0 OUTPUT, @WCRetPct bPct = 0 OUTPUT,
 @PrevClaimUnits bUnits = 0 OUTPUT,
 @PrevClaimAmt bDollar = 0 OUTPUT,
 @PrevApproveUnits bUnits = 0 OUTPUT,
 @PrevApproveAmt bDollar = 0 OUTPUT,
 @PrevClaimRet bDollar = 0 OUTPUT,
 @PrevApproveRet bDollar = 0 OUTPUT,
 @ClaimToDatePct bPct = 0 OUTPUT,
 @ClaimToDateUnits bUnits = 0 OUTPUT,
 @ClaimToDateAmt bDollar = 0 OUTPUT,
 @TaxBasisNetRet bYN = 'N' OUTPUT,
 @DefaultCountry CHAR(2) = NULL OUTPUT,
 @Msg varchar(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @retcode INT, @ClaimDate bDate

SET @rcode = 0
SET @retcode = 0

SET @PrevClaimUnits = 0
SET @PrevClaimAmt = 0
SET	@PrevClaimRet = 0
SET @PrevApproveUnits = 0
SET @PrevApproveAmt = 0
SET	@PrevApproveRet = 0
SET @ClaimToDatePct = 0
SET @ClaimToDateUnits = 0
SET @ClaimToDateAmt = 0

---------------------
-- VALIDATE VALUES --
---------------------
IF @SLCo IS NULL
	BEGIN
	SELECT @Msg = 'Missing SL Company!', @rcode = 1
	GOTO vspexit
	END

IF @Subcontract IS NULL
	BEGIN
	SELECT @Msg = 'Missing Subcontract!', @rcode = 1
	GOTO vspexit
	END

IF @ClaimNo IS NULL
	BEGIN
	SELECT @Msg = 'Missing Subcontract Claim No!', @rcode = 1
	GOTO vspexit
	END

IF @SLItem IS NULL
	BEGIN
	SELECT @Msg = 'Missing Subcontract Item!', @rcode = 1
	GOTO vspexit
	END

---- validate subcontract
IF NOT EXISTS(SELECT 1 FROM dbo.bSLHD WHERE SLCo=@SLCo AND SL=@Subcontract)
	BEGIN
	SELECT @Msg = 'Invalid Subcontract!', @rcode = 1
	GOTO vspexit
	END

---- validate claim no and get claim date
SELECT @ClaimDate = ISNULL(ClaimDate, dbo.vfDateOnly())
FROM dbo.vSLClaimHeader
WHERE SLCo=@SLCo
	AND SL=@Subcontract
	AND ClaimNo=@ClaimNo
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @Msg = 'Invalid Subcontract Claim No!', @rcode = 1
	GOTO vspexit
	END

---- get tax basis net retention flag
SET @TaxBasisNetRet = 'N'
SET @DefaultCountry = 'US'
SELECT @TaxBasisNetRet = a.TaxBasisNetRetgYN,
		@DefaultCountry = h.DefaultCountry
FROM dbo.bAPCO a
INNER JOIN dbo.bHQCO h ON h.HQCo = a.APCo
WHERE a.APCo = @SLCo


---- validate SL item
SELECT @Description = [Description]
		,@UM = UM
		,@CurUnits = CurUnits
		,@CurUnitCost = CurUnitCost
		,@CurCost = CurCost
		,@TaxType = TaxType
		,@TaxCode = TaxCode
		,@TaxGroup = TaxGroup
		,@WCRetPct = WCRetPct
FROM dbo.bSLIT
WHERE SLCo = @SLCo
	AND SL = @Subcontract
	AND SLItem = @SLItem
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @Msg = 'Invalid Subcontract Item!', @rcode = 1
	GOTO vspexit
	END

---- SET TAX VALUES
SET @TaxRate = 0
SET @GSTRate = 0
SET @PSTRate = 0

IF @TaxCode IS NOT NULL
	BEGIN
	EXEC @retcode = dbo.vspHQTaxRateGet @TaxGroup, @TaxCode, @ClaimDate, NULL, @TaxRate OUTPUT, NULL, NULL,
				@GSTRate OUTPUT, @PSTRate OUTPUT, NULL, NULL, NULL, NULL, NULL, NULL, @Msg OUTPUT				
	IF @retcode <> 0
		BEGIN
		SELECT @TaxRate = 0, @GSTRate = 0, @PSTRate = 0
		END	
	END	

---- get claim previous values
SELECT @PrevClaimUnits = PrevClaimUnits
		,@PrevClaimAmt = PrevClaimAmt
		,@PrevApproveUnits = PrevApproveUnits
		,@PrevApproveAmt = PrevApproveAmt
		,@PrevApproveRet = PrevApproveRet
FROM dbo.vfSLClaimItemPriorTotals (@SLCo, @Subcontract, @ClaimNo, @SLItem, @ClaimDate)

---- SET CLAIM TO DATE VALUES
SET @ClaimToDateUnits = @PrevClaimUnits
SET @ClaimToDateAmt = @PrevClaimAmt
---- CALCULATE PCT CLAIM TO DATE
SELECT @ClaimToDatePct = 
	CASE @UM WHEN 'LS' THEN
		CASE @CurCost WHEN 0 THEN 0
			ELSE @ClaimToDateAmt / @CurCost END
		ELSE
		CASE @CurUnits WHEN 0 THEN 0 
			ELSE @ClaimToDateUnits / @CurUnits END
	END




vspexit:
	RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspSLItemValForClaim] TO [public]
GO
