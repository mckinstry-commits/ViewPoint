SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/13/2010
-- Description:	Validation for SM Customer.

	Modifications:
	07/16/2010: MarkH  
		Need to support sort name entry.  Will let existing val proc bspARCustomerVal handle that.
		Also need to support calling this procedure from SM Customer and any other form that has
		a Customer input.  Added the '@MustExist' flag for that.  If the value is 'Y' then the
		Customer must exist in SM Customer or an error will be returned.  Any other value will
		assume you are adding the Customer to SM Customer.
	01/10/11: Eric V
		Added ServiceSite to the parameters.  If a ServiceSite is provided, then only the Customer
		of the ServiceSite is a valid choice.
	8/5/11	Jeremiah B	-	Added the Is On Credit Hold output param.
	08/16/11 Lane G - Added SMTechPrefAdvExist
	 TRL 10/25/2011 TK-88966 Renamed @IsOnHoldYN parameter to @Status to return actual AR Custumer Status
	2/6/13 Jacob VH TFS-39301 Modified to work with changes made to support company copy on rate overrides
	05/28/13 Dan K TFS-50954 Modified to return NonBillable value 
=============================================*/
CREATE PROCEDURE [dbo].[vspSMCustomerVal]
	@SMCo as bCompany,
	@CustomerGroup AS bGroup,
	@Customer AS bSortName,
	@MustExist AS bYN,
	@CustomerOutput AS bCustomer = NULL OUTPUT,
	@ARCustomerKeyID AS bigint = NULL OUTPUT,
	@CustomerAddress AS varchar(60) = NULL OUTPUT,
	@CustomerCity AS varchar(30) = NULL OUTPUT,
	@CustomerState AS varchar(5) = NULL OUTPUT,
	@CustomerZip AS varchar(15) = NULL OUTPUT,
	@CustomerCountry AS varchar(2) = NULL OUTPUT,
   	@SMRateOverridesExist bYN = NULL OUTPUT,	
   	@SMStandardItemDefaultsExist bYN = NULL OUTPUT,
   	@SMTechPrefAdvExist bYN = NULL OUTPUT,
   	@Status char(1) = NULL OUTPUT,
   	@CustomerAddressFormatted as varchar(240) = NULL OUTPUT,
	@NonBillable bYN = NULL OUTPUT,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int, @Active bYN
	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'SM Company is required.'
		RETURN 1
	END

	EXEC @rcode = dbo.bspARCustomerVal @CustGroup = @CustomerGroup, @Customer = @Customer, @CustomerOutput = @CustomerOutput OUTPUT, @msg = @msg OUTPUT
	
	IF @rcode <> 0
	BEGIN
		SET @msg = 'Customer ' + dbo.vfToString(@Customer) + ' does not exist and must be created in AR Customers before it can be used in SM Customers.'
		RETURN @rcode
	END

	SELECT @Active = Active,
			@SMRateOverridesExist = dbo.vfSMRateOverridesExist(SMEntity.SMCo, SMEntity.EntitySeq),
			@SMStandardItemDefaultsExist = dbo.vfSMStandardItemDefaultsExist(SMEntity.SMCo, SMEntity.EntitySeq),
			@SMTechPrefAdvExist = TechPrefExits, 
			@NonBillable = SMCustomer.NonBillable
	FROM SMCustomer 
		CROSS APPLY dbo.vfSMTechPrefAdvExist(SMCo,CustGroup,Customer,NULL)
		LEFT JOIN dbo.SMEntity ON SMCustomer.SMCo = SMEntity.SMCo AND SMCustomer.CustGroup = SMEntity.CustGroup AND SMCustomer.Customer = SMEntity.Customer
	WHERE SMCustomer.SMCo = @SMCo AND SMCustomer.CustGroup = @CustomerGroup AND SMCustomer.Customer = @CustomerOutput
	
	IF @@rowcount = 0 AND @MustExist = 'Y'
	BEGIN 
		SET @msg = 'Customer must be setup in SM Customer.'
		RETURN 1
	END

	SELECT 
		@ARCustomerKeyID = KeyID,
		@CustomerAddress = ARCM.[Address], 
		@CustomerCity = ARCM.City, 
		@CustomerState = ARCM.[State], 
		@CustomerZip = ARCM.Zip, 
		@CustomerCountry = ARCM.Country,
		@CustomerAddressFormatted = dbo.vfSMAddressFormat(ARCM.[Address], ARCM.Address2, ARCM.City, ARCM.[State], ARCM.Zip, ARCM.Country),
		@Status = [Status]
	FROM dbo.ARCM
	WHERE CustGroup = @CustomerGroup AND Customer = @CustomerOutput
	
	IF @Active <> 'Y'
	BEGIN
		SET @msg = 'SM Customer is inactive.'
		RETURN 1
	END
	
	RETURN 0
END

/* Testing Framework
	
	Declare @rcode int,					@SMCo as bCompany, 	
		@CustomerGroup AS bGroup, 		@MustExist AS bYN,
		@Customer AS bSortName,			@CustomerOutput AS bCustomer,
		@ARCustomerKeyID AS bigint,		@CustomerAddress AS varchar(60),
		@CustomerCity AS varchar(30),	@CustomerState AS varchar(5),
		@CustomerZip AS varchar(15),	@CustomerCountry AS varchar(2),
		@CustomerAddressFormatted as varchar(240),	@msg AS varchar(255)

	Select @SMCo= 1, @CustomerGroup = 1, @MustExist = 'N', @Customer='55'
	
	exec @rcode = vspSMCustomerVal @SMCo, @CustomerGroup, @MustExist, @Customer,
	@CustomerOutput OUTPUT, @ARCustomerKeyID OUTPUT, @CustomerAddress OUTPUT,
	@CustomerCity OUTPUT, @CustomerState OUTPUT, @CustomerZip OUTPUT,
	@CustomerCountry OUTPUT, @CustomerAddressFormatted OUTPUT,
	@msg OUTPUT
	
	Select @rcode ReturnCode, @CustomerOutput CustomerOut, @ARCustomerKeyID ARKey, @CustomerAddress Address,
	@CustomerCity City, @CustomerState State, @CustomerZip Zip,
	@CustomerCountry Country, @CustomerAddressFormatted FormattedAddr,
	@msg Message
	
*/
GO
GRANT EXECUTE ON  [dbo].[vspSMCustomerVal] TO [public]
GO
