SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/20/10
-- Description:	This is special validation that is used to validate service sites for the service site form.
--				The reason we need this validation is because if a user is creating a service site in the context
--				of a contact then we want to display if a service site already exists for some other customer.
--
-- Modifications: 08/16/11 Lane G - Added SMTechPrefAdvExist
--					2/6/13 Jacob VH TFS-39301 Modified to work with changes made to support company copy on rate overrides
-- =============================================
CREATE PROCEDURE [dbo].[vspSMServiceSiteServiceSiteVal]
	@SMCo bCompany, 
   	@ServiceSite varchar(20),
   	@CustGroup bGroup,
   	@Customer bCustomer,
   	@InCustomerFormContext bYN,
   	@SMRateOverridesExist bYN OUTPUT,
   	@SMStandardItemDefaultsExist bYN OUTPUT,
   	@SMTechPrefAdvExist bYN OUTPUT,
   	@msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END	

	IF @ServiceSite IS NULL
	BEGIN
		SET @msg = 'Missing SM Service Site!'
		RETURN 1
	END
	
	IF @InCustomerFormContext IS NULL
	BEGIN
		SET @msg = 'Missing SM In Customer Form Context!'
		RETURN 1
	END
	
	DECLARE @ServiceSiteCustGroup bGroup, @ServiceSiteCustomer bCustomer
	
	SELECT	@msg = [Description], 
			@ServiceSiteCustGroup = SMServiceSite.CustGroup, 
			@ServiceSiteCustomer = SMServiceSite.Customer, 
			@SMRateOverridesExist = dbo.vfSMRateOverridesExist(SMEntity.SMCo, SMEntity.EntitySeq),
			@SMStandardItemDefaultsExist = dbo.vfSMStandardItemDefaultsExist(SMEntity.SMCo, SMEntity.EntitySeq),
			@SMTechPrefAdvExist = TechPrefExits
	FROM dbo.SMServiceSite
		CROSS APPLY dbo.vfSMTechPrefAdvExist(SMCo,NULL,NULL,ServiceSite)
		LEFT JOIN dbo.SMEntity ON SMServiceSite.SMCo = SMEntity.SMCo AND SMServiceSite.ServiceSite = SMEntity.ServiceSite
	WHERE SMServiceSite.SMCo = @SMCo AND SMServiceSite.ServiceSite = @ServiceSite
	
	IF @InCustomerFormContext = 'Y' AND @@rowcount <> 0 AND (@CustGroup <> @ServiceSiteCustGroup OR @Customer <> @ServiceSiteCustomer)
	BEGIN
		SELECT @msg = 'Service site already exists and is owned by customer ' + CAST(@ServiceSiteCustomer AS VARCHAR)
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMServiceSiteServiceSiteVal] TO [public]
GO
