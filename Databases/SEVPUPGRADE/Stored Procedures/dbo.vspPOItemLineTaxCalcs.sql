SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Stored Procedure dbo.vspPOItemLineTaxCalcs  ******/
CREATE procedure [dbo].[vspPOItemLineTaxCalcs]
/************************************************************************
 * Created By:	GF 08/11/2011 TK-07438 TK-07439 TK-07440
 * Modified By:	DAN SO 04/24/2012 TK-14139 - Committed costs for SM PO w/job
 *
 *
 *
 *
 * PURPOSE:
 * Calculate the tax values for PO Item Lines.
 * Called from PO Item Line insert, update, and delete triggers currently.
 *    
 *
 * INPUTS
 *  @SMJobExistsYN - for ItemType 6 = SM PO - is there an associated Job?
 *
 * RETURNS:
 *	0 - Success 
 *	1 - Failure
 *
 *************************************************************************/
(@TaxGroup INT = NULL, @ItemType TINYINT = NULL,  @SMJobExistsYN bYN = 'N', @PostedDate bDate = NULL,
 @TaxCode bTaxCode = NULL, @TaxRate bRate = 0, @GSTRate bRate = 0,
 @TotalCost bDollar = 0, @RemCost bDollar = 0,
 @TotalTax bDollar = NULL OUTPUT, @RemTax bDollar = NULL OUTPUT,
 @JCCmtdTax bDollar = NULL OUTPUT, @JCRemCmtdTax bDollar = NULL OUTPUT,
 @HQTXdebtGLAcct bGLAcct = NULL OUTPUT, @ErrMsg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON


declare @rcode INT, @ValueAdd CHAR(1), @PSTRate bRate, @GSTTaxAmt bDollar,
		@PSTTaxAmt bDollar
		
---- inititalize variables
SET @rcode = 0
SET @HQTXdebtGLAcct = NULL
SET @PSTRate = 0
SET @ValueAdd = 'N'
SET @TotalTax = 0
SET @RemTax = 0
SET @GSTTaxAmt = 0
SET @JCCmtdTax = 0
SET @JCRemCmtdTax = 0
SET @PSTTaxAmt = 0

---- Calculate PO Item Line Tax amounts
---- get tax rate
EXEC @rcode = dbo.vspHQTaxRateGet @TaxGroup, @TaxCode, @PostedDate, @ValueAdd OUTPUT,
			NULL, NULL, NULL, NULL, @PSTRate OUTPUT, NULL, NULL, @HQTXdebtGLAcct OUTPUT,
			NULL, NULL, NULL, @ErrMsg OUTPUT				
if @rcode <> 0
	BEGIN
	SET @ErrMsg = 'Tax Rates could not be determined.'
	SET @rcode = 0
	GOTO vspexit
	END

if @GSTRate = 0 and @PSTRate = 0 and @ValueAdd = 'Y'
	BEGIN
	---- We have an Intl VAT code being used as a Single Level Code
	if (select GST from dbo.bHQTX  where TaxGroup = @TaxGroup and TaxCode = @TaxCode) = 'Y'
		BEGIN
		select @GSTRate = @TaxRate
		END
	END



---- calculate Tax
SELECT @TotalTax	= @TotalCost * @TaxRate ----Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only  1000 * .155 = 155
SELECT @GSTTaxAmt	= CASE @TaxRate  WHEN 0	THEN 0 ELSE CASE @ValueAdd WHEN 'Y' THEN (@TotalTax * @GSTRate) / @TaxRate ELSE 0 END END	
select @PSTTaxAmt	= CASE @ValueAdd WHEN 'Y' THEN @TotalTax - @GSTTaxAmt ELSE 0 END			--PST Tax Amount.  (Rounding errors to PST)

SELECT @RemTax		= @RemCost * @TaxRate
---- calculate JCCmtdTax
--SELECT @GSTTaxAmt = CASE @TaxRate  WHEN 0 THEN 0 ELSE CASE @ValueAdd WHEN 'Y' THEN (@TotalTax * @GSTRate) / @TaxRate ELSE 0 END END	
SELECT @JCCmtdTax = CASE @ItemType 
							WHEN 1 THEN @TotalTax - (CASE WHEN @HQTXdebtGLAcct IS NULL THEN 0 ELSE @GSTTaxAmt END) 
							-- TK-14139 --
							WHEN 6 THEN
								CASE @SMJobExistsYN
									WHEN 'Y' THEN @TotalTax - (CASE WHEN @HQTXdebtGLAcct IS NULL THEN 0 ELSE @GSTTaxAmt END)
									ELSE 0 END 
							ELSE 0 END

---- calculate JCRemCmtdTax
SELECT @GSTTaxAmt	 = CASE @TaxRate  WHEN 0 THEN 0 ELSE CASE @ValueAdd WHEN 'Y' THEN (@RemTax * @GSTRate) / @TaxRate ELSE 0 END END
SELECT @JCRemCmtdTax = CASE @ItemType 
							WHEN 1 THEN @RemTax - (CASE WHEN @HQTXdebtGLAcct IS NULL THEN 0 ELSE @GSTTaxAmt END) 
							-- TK-14139 --
							WHEN 6 THEN
								CASE @SMJobExistsYN
									WHEN 'Y' THEN @RemTax - (CASE WHEN @HQTXdebtGLAcct IS NULL THEN 0 ELSE @GSTTaxAmt END)
									ELSE 0 END 							
							ELSE 0 END  


vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineTaxCalcs] TO [public]
GO
