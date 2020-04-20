SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAUFBTGenerateAddlItemsInit    Script Date: 8/28/99 9:35:27 AM ******/
CREATE   proc [dbo].[bspPRAUFBTGenerateAddlItemsInit]
/***********************************************************
* CREATED BY:	CHS 01/06/2011	- #142027
* MODIFIED By:
*
* Usage:
*	insert values into PRAUEmployerFBTItems -
*	1) found in PREC and PRDL to have been entered since last year
*	2) from PREC and PRDL when there is no previous tax year to copy from
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
*GRANT EXECUTE ON bspPRAUFBTGenerateAddlItemsInit TO public;
************************************************************/
(@PRCo bCompany, @TaxYear char(4), @msg varchar(255) output)  
   	
AS
SET NOCOUNT ON

DECLARE @rcode int, @ECCount int, @DLCount int
SELECT @rcode = 0, @msg = '', @ECCount = 0, @DLCount = 0
	
-- look for any earn codes added since last initialization
INSERT INTO PRAUEmployerFBTItems (PRCo, TaxYear, FBTType, EDLType, EDLCode)
SELECT @PRCo as [PRCo], @TaxYear as [TaxYear], ATOCategory as [FBTType], 'E' as [EDLType], EarnCode as [EDLCode] 
FROM PREC (nolock) e
WHERE PRCo = @PRCo 
	AND ATOCategory in ('FBT1', 'FBT2') 
	AND NOT EXISTS (SELECT TOP 1 1 
						FROM PRAUEmployerFBTItems 
						WHERE PRCo = @PRCo 
							AND TaxYear = @TaxYear 
							AND EDLType = 'E'
							AND EDLCode = e.EarnCode)
							
select @ECCount	= @@ROWCOUNT
							

-- look for and deduction/liability codes added since last initialization
INSERT INTO PRAUEmployerFBTItems (PRCo, TaxYear, FBTType, EDLType, EDLCode)
SELECT @PRCo as [PRCo], @TaxYear as [TaxYear], ATOCategory as [FBTType], DLType as [EDLType], DLCode as [EDLCode] 
FROM PRDL (nolock) d
WHERE PRCo = @PRCo 
	AND ATOCategory in ('FBT1', 'FBT2')
	AND NOT EXISTS (SELECT TOP 1 1 
						FROM PRAUEmployerFBTItems 
						WHERE PRCo = @PRCo 
							AND TaxYear = @TaxYear 
							AND EDLType IN ('D', 'L')
							AND EDLCode = d.DLCode)


select @DLCount	= @@ROWCOUNT	

IF (@ECCount > 0) OR (@DLCount > 0)
	BEGIN
	IF (@ECCount > 0)
		BEGIN
		SELECT @msg = cast(@ECCount as varchar(10)) + ' Earnings codes have been added from PREC'
		END
		
	IF (@ECCount > 0) AND (@DLCount > 0)
		BEGIN
		SELECT @msg = @msg + ' and '
		END		
		
	IF (@DLCount > 0)
		BEGIN
		SELECT @msg = @msg + cast(@DLCount as varchar(10)) + ' Deduction/Liability codes have been added from PRDL'
		END
		
	SELECT @msg = @msg + '.'
	
	END
	
Else
	BEGIN
	SELECT @msg = 'No Earnings, Deductions, or Liability codes were added.'
	END	
								
   
   bspexit:
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAUFBTGenerateAddlItemsInit] TO [public]
GO
