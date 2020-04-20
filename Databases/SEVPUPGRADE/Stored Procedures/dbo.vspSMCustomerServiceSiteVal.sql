SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMCustomerServiceSiteVal]
	/******************************************************
	* CREATED BY:  EricV 
	* MODIFIED By: 
	*
	* Usage:  Validates Service Site against SMServiceSite for a specific Customer.
	*		
	*
	* Input params:
	*	
	*	@SMCo          - SM Company
	*	@CustGroup	   - SM CustGroup
	*   @Customer      - SM Customer
	*	@SMServiceSite - SM Service Site
	*	
	*
	* Output params:
	*	@msg		SM Service Site Description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@SMCo bCompany, 
   	@CustGroup bGroup,
   	@Customer bCustomer,
   	@ServiceSite varchar(20),
   	@msg varchar(255) = NULL OUTPUT
AS 
BEGIN

	SET NOCOUNT ON
	
	SELECT @msg = 
	CASE 
		WHEN @SMCo IS NULL THEN 'Missing SM Company!'
		WHEN @CustGroup IS NULL THEN 'Missing SM CustGroup!'
		WHEN @Customer IS NULL THEN 'Missing SM Customer!'
		WHEN @ServiceSite IS NULL THEN 'Missing SM Service Site!'
	END
	
	IF @msg IS NOT NULL
	BEGIN
		RETURN 1
	END
	
	DECLARE @rcode int, @ServiceSiteCustGroup bGroup, @ServiceSiteCustomer bCustomer
	
	EXEC @rcode = dbo.vspSMServiceSiteVal @SMCo = @SMCo, @ServiceSite = @ServiceSite, @msg = @msg OUTPUT
	
	IF @rcode <> 0
	BEGIN
		RETURN @rcode
	END
	
	SELECT @ServiceSiteCustGroup = CustGroup, @ServiceSiteCustomer = Customer 
	FROM dbo.SMServiceSite 
	WHERE SMCo = @SMCo AND ServiceSite = @ServiceSite
	
	IF dbo.vfIsEqual(@CustGroup, @ServiceSiteCustGroup) = 0 OR dbo.vfIsEqual(@Customer, @ServiceSiteCustomer) = 0
	BEGIN
		SET @msg = 'The owner of this service site is ' + dbo.vfToString(@ServiceSiteCustomer)
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMCustomerServiceSiteVal] TO [public]
GO
