SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspAPCOOnCostInvNmbrVal]
/***************************************************
* CREATED BY:		CHS	03/15/2012	B-09107
* Modified by:
*
* Usage: 
*	Validates the AP On-Cost Invoice Number to make sure that is is numeric and a whole number.	
*
* Input:
*	@apco			AP Company
*	@InvoiceNumber	AP On-Cost Invoice Number
*
* Output:
*   @msg          error message
*
* Returns:
*	0             success
*   1             error
*************************************************/
(@APCo bCompany = NULL,
 @InvoiceNumber varchar(15) = NULL,
 @msg varchar(255) OUTPUT)
 
AS
SET NOCOUNT ON

DECLARE @InvoiceNumeric numeric(15,6)

--Validate apco, cmco and cmacct inputs
IF @APCo IS NULL
	BEGIN
	SELECT @msg = 'Missing AP Company '
	RETURN 1
	END

IF @InvoiceNumber IS NULL
	BEGIN
	SELECT @msg = 'Missing On-Cost Invoice Number '
	RETURN 1
	END

IF NOT ISNUMERIC(@InvoiceNumber) = 1 
	BEGIN
	SELECT @msg = 'Invoice # must be a whole number greater than zero'
	RETURN 1	
	END

ELSE
	BEGIN
	SELECT @InvoiceNumeric = CAST(@InvoiceNumber AS NUMERIC(15,6))
	
	IF @InvoiceNumeric < 0 OR @InvoiceNumeric > ROUND(@InvoiceNumeric,0)
		BEGIN
		SELECT @msg = 'Invoice # must be a whole number greater than zero'
		RETURN 1		
		END		
	END


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspAPCOOnCostInvNmbrVal] TO [public]
GO
