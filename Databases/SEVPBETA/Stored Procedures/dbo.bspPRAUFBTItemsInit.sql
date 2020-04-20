SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAUFBTItemsInit    Script Date: 8/28/99 9:35:27 AM ******/
CREATE   proc [dbo].[bspPRAUFBTItemsInit]
/***********************************************************
* CREATED BY:	CHS 01/06/2011	- #142027
* MODIFIED By:	CHS	01/25/2011	- #142027
*
* Usage:
*	insert values into PRAUEmployerFBTItems -
*	1) copied from previous tax year
*	2) found in PREC and PRDL to have been entered since last year
*	3) from PREC and PRDL when there is no previous tax year to copy from
*
* Input params:
*	@PRCo		PR company
*	@TaxYear	Tax Year
*
* Output params:
*	@msg		Earnings code description or error message
*
* Return code:
*	0 = success, 1 = failure
*
*GRANT EXECUTE ON bspPRAUFBTItemsInit TO public;
************************************************************/
(@PRCo bCompany, @TaxYear char(4), @msg varchar(60) output)  
   	
AS
SET NOCOUNT ON

DECLARE @rcode int, @PrevTaxYear char(4)
SELECT @rcode = 0, @PrevTaxYear = ''
   
-- note - if previous tax year exists then default from that.  

SELECT @PrevTaxYear = max(isnull(TaxYear, ''))
FROM PRAUEmployerFBTItems (NOLOCK)
WHERE PRCo = @PRCo and isnull(TaxYear, '') < @TaxYear

IF @PrevTaxYear <> ''
	BEGIN
	-- default lines from previous tax year
	INSERT INTO PRAUEmployerFBTItems (PRCo, TaxYear, FBTType, EDLType, EDLCode, Category)
	SELECT @PRCo AS [PRCo], @TaxYear AS [TaxYear], FBTType, EDLType, EDLCode, Category
	FROM PRAUEmployerFBTItems (NOLOCK)
	WHERE PRCo = @PRCo AND TaxYear = @PrevTaxYear
	
	-- delete those items from PREC that are no longer valid i.e. - the FBT Type - EDL Type - EDL Code combination no longer exists
	DELETE FROM PRAUEmployerFBTItems 
	WHERE PRCo = @PRCo 
		AND TaxYear = @TaxYear
		AND EDLType = 'E'
		AND FBTType NOT IN (SELECT PREC.ATOCategory 
								FROM PREC (NOLOCK)
								WHERE PRAUEmployerFBTItems.PRCo = PREC.PRCo 
									AND PRAUEmployerFBTItems.EDLCode = PREC.EarnCode 
									AND PREC.ATOCategory IN ('FBT1','FBT2'))
									
	
	-- delete those items from PRDL that are no longer valid i.e. - the FBT Type - EDL Type - EDL Code combination no longer exists
	DELETE FROM PRAUEmployerFBTItems
	WHERE PRCo = @PRCo 
		AND TaxYear = @TaxYear
		AND EDLType in ('D','L')
		AND FBTType NOT IN (SELECT PRDL.ATOCategory 
								FROM PRDL (NOLOCK)
								WHERE PRAUEmployerFBTItems.PRCo = PRDL.PRCo 
									AND PRAUEmployerFBTItems.EDLCode = PRDL.DLCode 
									AND PRDL.ATOCategory IN ('FBT1','FBT2'))
									
	
	-- look for any earn codes added since last year
	INSERT INTO PRAUEmployerFBTItems (PRCo, TaxYear, FBTType, EDLType, EDLCode)
	SELECT @PRCo as [PRCo], @TaxYear as [TaxYear], ATOCategory as [FBTType], 'E' as [EDLType], EarnCode as [EDLCode] 
	FROM PREC (nolock) e
	WHERE PRCo = @PRCo 
		AND ATOCategory in ('FBT1', 'FBT2') 
		AND NOT EXISTS (SELECT TOP 1 1 
							FROM PRAUEmployerFBTItems 
							WHERE PRCo = @PRCo 
								AND TaxYear = @PrevTaxYear 
								AND EDLType = 'E'
								AND EDLCode = e.EarnCode)
								

	-- look for and deduction/liability codes added since last year
	INSERT INTO PRAUEmployerFBTItems (PRCo, TaxYear, FBTType, EDLType, EDLCode)
	SELECT @PRCo as [PRCo], @TaxYear as [TaxYear], ATOCategory as [FBTType], DLType as [EDLType], DLCode as [EDLCode] 
	FROM PRDL (nolock) d
	WHERE PRCo = @PRCo 
		AND ATOCategory in ('FBT1', 'FBT2')
		AND NOT EXISTS (SELECT TOP 1 1 
							FROM PRAUEmployerFBTItems 
							WHERE PRCo = @PRCo 
								AND TaxYear = @PrevTaxYear 
								AND EDLType IN ('D', 'L')
								AND EDLCode = d.DLCode)
								
	END
	
-- when there is no pre-existing tax year data to copy from, look in PREC and PRDL and create it.
ELSE
	BEGIN
	INSERT INTO PRAUEmployerFBTItems (PRCo, TaxYear, FBTType, EDLType, EDLCode)
	SELECT @PRCo as [PRCo], @TaxYear as [TaxYear], ATOCategory as [FBTType], 'E' as [EDLType], EarnCode as [EDLCode] 
	FROM PREC (nolock)
	WHERE PRCo = @PRCo AND ATOCategory in ('FBT1', 'FBT2')
	   
	INSERT INTO PRAUEmployerFBTItems (PRCo, TaxYear, FBTType, EDLType, EDLCode)
	SELECT @PRCo as [PRCo], @TaxYear as [TaxYear], ATOCategory as [FBTType], DLType as [EDLType], DLCode as [EDLCode] 
	FROM PRDL (nolock)
	WHERE PRCo = @PRCo AND ATOCategory in ('FBT1', 'FBT2')

	END

   
   bspexit:
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAUFBTItemsInit] TO [public]
GO
