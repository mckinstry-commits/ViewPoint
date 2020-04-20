SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:	  TRL
-- Create date:   10/25/2011 TK-88966
-- Description:	 Create Customer Val for Work Order Entry
=============================================*/
CREATE PROCEDURE [dbo].[vspSMWorkOrderCustomerVal]
	@SMCo bCompany,
	@CustomerGroup bGroup, 
	@Customer bSortName,
	@ServiceSite varchar(20),
	@CustomerOutput bCustomer = NULL OUTPUT,
	@CustomerAddressFormatted as varchar(240) = NULL OUTPUT,
   	@Status char(1) = NULL OUTPUT,
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int

	EXEC @rcode = dbo.vspSMCustomerVal @SMCo = @SMCo, @CustomerGroup = @CustomerGroup, @Customer = @Customer, @MustExist = 'Y',
		@CustomerOutput = @CustomerOutput OUTPUT, @CustomerAddressFormatted = @CustomerAddressFormatted OUTPUT,
		@Status = @Status OUTPUT, @msg = @msg OUTPUT

	IF @rcode <> 0
	BEGIN
		RETURN @rcode
	END

	IF @Status = 'I'
	BEGIN
		SET @msg = 'AR Customer is inactive.'
		RETURN 1
	END
	
	IF NOT EXISTS(SELECT 1 FROM dbo.SMServiceSite WHERE SMCo = @SMCo AND ServiceSite = @ServiceSite AND CustGroup = @CustomerGroup AND Customer = @CustomerOutput)
	BEGIN
		SET @msg = 'Only the Customer for current Service Site is valid.'
		RETURN 1
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderCustomerVal] TO [public]
GO
