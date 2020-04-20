SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMAgreementServiceSiteVal]
	/******************************************************
	* CREATED BY:  EricV 
	* MODIFIED By: 
	*
	* Usage:  Validates Service Site on an Agreement Service record.
	*		
	*
	* Input params:
	*	
	*	@SMCo          - SM Company
	*	@CustGroup	   - SM CustGroup
	*   @Customer      - SM Customer
	*	@SMServiceSite - SM Service Site
	*	@Agreement     - SM Agreement
	*	@Revision      - SM Agreement Revision
	*	@Service       - SM Agreement Service
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
   	@Agreement varchar(15),
   	@Revision int,
   	@Service int,
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
		WHEN @Agreement IS NULL THEN 'Missing SM Agreement!'
		WHEN @Revision IS NULL THEN 'Missing SM Agreement Revision!'
		WHEN @Service IS NULL THEN 'Missing SM Agreement Service!'
	END
	
	IF @msg IS NOT NULL
	BEGIN
		RETURN 1
	END
	
	DECLARE @rcode int
	
	EXEC @rcode = dbo.vspSMCustomerServiceSiteVal @SMCo = @SMCo, @CustGroup = @CustGroup, @Customer = @Customer, @ServiceSite = @ServiceSite, @msg = @msg OUTPUT
	
	IF @rcode <> 0
	BEGIN
		RETURN @rcode
	END
	
	IF EXISTS(SELECT 1 FROM dbo.SMAgreementServiceTask	
				INNER JOIN dbo.SMAgreementService 
					ON SMAgreementServiceTask.SMCo = SMAgreementService.SMCo
					AND SMAgreementServiceTask.Agreement = SMAgreementService.Agreement
					AND SMAgreementServiceTask.Revision = SMAgreementService.Revision
					AND SMAgreementServiceTask.[Service] = SMAgreementService.[Service]
				WHERE SMAgreementServiceTask.SMCo = @SMCo AND SMAgreementServiceTask.Agreement = @Agreement
				AND SMAgreementServiceTask.Revision = @Revision AND SMAgreementServiceTask.Service = @Service 
				AND NOT SMAgreementService.ServiceSite = @ServiceSite
				AND SMAgreementServiceTask.ServiceItem IS NOT NULL)
	BEGIN
		SET @msg = 'Agreement Service Tasks exists for a different site.'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementServiceSiteVal] TO [public]
GO
