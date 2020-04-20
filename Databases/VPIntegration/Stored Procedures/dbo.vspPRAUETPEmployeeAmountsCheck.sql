SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  procedure [dbo].[vspPRAUETPEmployeeAmountsCheck]
/******************************************************
* CREATED BY:	MV	03/29/2011 - PR AU ETP Epic
* MODIFIED By:	
*
* Usage: Checks for existence of records in vPRAUEmployeeETPAmounts.
*		 Returns 'Y' if true.
*		 Called from PRAUEmployerETPProcess form.	
*
* Input params:
*
*	@PRCo - PR Company
*	@Taxyear - Tax Year
*	@Employee
*
* Output params:
*	@Exists
*	@Msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
(@PRCo bCompany,@TaxYear char(4), @Employee bEmployee, @Exists bYN OUTPUT,@Msg varchar(100) output)
   	
AS
SET NOCOUNT ON
DECLARE @rcode INT
	
SELECT @rcode=0, @Exists = 'N'


-- Check for the existence of this employee by taxyear
IF EXISTS(
			SELECT * 
			FROM dbo.PRAUEmployeeETPAmounts
			WHERE PRCo=@PRCo AND TaxYear=@TaxYear AND Employee=@Employee
		 )
BEGIN
	SELECT  @Exists = 'Y'       
END
			

RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUETPEmployeeAmountsCheck] TO [public]
GO
