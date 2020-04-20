SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROCEDURE [dbo].[vspHQCOInfoGetVal]
/************************************************************
* CREATED:		CHS 12/14/2010
* MODIFIED:		CHS 03/10/2010
* 
* USAGE:
*   Returns the HQCO table
*	
* INPUT PARAMETERS
*	HQCO
* 
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@TaxYear varchar(4), @hqco bCompany, @CoName varchar(60) output, @Address varchar(60) output, 
	@Address2 varchar(60) output, @City varchar(30) output, @State varchar(4) output, 
	@Zip varchar(12) output, @FedTaxId varchar(20) output, @Phone bPhone output,
	@msg varchar(60) output)

  	AS
  	SET NOCOUNT ON
  	
  	DECLARE @rcode int
  	SELECT @rcode = 0
  	
IF LEN(ISNULL(@TaxYear, '')) NOT IN (0,4)
  	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END
	
IF ISNUMERIC(@TaxYear) = 0
  	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END
	
IF SUBSTRING(@TaxYear, 1, 1) not in ('1','2','3','4','5','6','7','8','9')
  	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END
	
IF SUBSTRING(@TaxYear, 2, 1) not in ('1','2','3','4','5','6','7','8','9','0')
	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END

IF SUBSTRING(@TaxYear, 3, 1) not in ('1','2','3','4','5','6','7','8','9','0')
	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END

IF SUBSTRING(@TaxYear, 4, 1) not in ('1','2','3','4','5','6','7','8','9','0')
	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END
  	  	  	
  	
IF @hqco IS NULL
	BEGIN
	SELECT @msg = 'Missing HQ Company', @rcode = 1
	RETURN @rcode
	END

SELECT @CoName = Name, @Address = Address, @Address2 = Address2, @City= City,  @State = State,
	@Zip = Zip, @FedTaxId = FedTaxId, @Phone = Phone

FROM HQCO
WHERE HQCo = @hqco

GO
GRANT EXECUTE ON  [dbo].[vspHQCOInfoGetVal] TO [public]
GO
