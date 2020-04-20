SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE  procedure [dbo].[vspSMServiceSiteVal]
	/******************************************************
	* CREATED BY:  Markh 
	* MODIFIED By:	Jacob		8/22/10 - Updated to follow sql style guide.
	*				Jeremiah	1/11/11	- Modified how we get the default contact
	*				Jason		1/06/12 - TK-11609 - Added code to get the Job
	*				Jason		2/02/12 - TK-12298 - Returning the Costing Method.
	*				Jeremiah	8/2/12	- TK-16789 - Removed unneeded work order validation and param.
	*
	* Usage:  Validates Service Site against SMServiceSite.
	*		SMServiceSite setup form and forms with a Service Site input.
	*
	* Input params:
	*	
	*	@SMCo - SMCompany
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
   	@ServiceSite varchar(20),
   	@FormattedAddress varchar(240) = NULL OUTPUT,
   	@Customer bCustomer = NULL OUTPUT,
   	@DefaultServiceCenter varchar(10) = NULL OUTPUT,
   	@DefaultContactName varchar(61) = NULL OUTPUT,
   	@DefaultContactPhone varchar(20) = NULL OUTPUT,
   	@JCCo bCompany = NULL OUTPUT,
   	@Job dbo.bJob = NULL OUTPUT,
   	@CostingMethod VARCHAR(10) = NULL OUTPUT,
   	@msg varchar(255) = NULL OUTPUT
AS 
BEGIN

	SET NOCOUNT ON

	SELECT @msg = 
	CASE 
		WHEN @SMCo IS NULL THEN 'Missing SM Company!'
		WHEN @ServiceSite IS NULL THEN 'Missing SM Service Site!'
	END
	
	IF @msg IS NOT NULL
	BEGIN
		RETURN 1
	END
	
	DECLARE @IsActive bYN
	
	SELECT 
		@msg = [Description], 
		@IsActive = Active, 
		@FormattedAddress = dbo.vfSMAddressFormat(SMServiceSite.Address1, SMServiceSite.Address2, SMServiceSite.City, SMServiceSite.[State], SMServiceSite.Zip, SMServiceSite.Country),
		@Customer = CASE WHEN SMServiceSite.[Type] = 'Customer' THEN SMServiceSite.Customer ELSE NULL END,
		@JCCo = CASE WHEN SMServiceSite.[Type] = 'Job' THEN SMServiceSite.JCCo ELSE NULL END,
		@Job = CASE WHEN SMServiceSite.[Type] = 'Job' THEN SMServiceSite.Job ELSE NULL END,
		@DefaultServiceCenter = DefaultServiceCenter,
		@DefaultContactName = 
			CASE WHEN SMSiteContactInfo.FirstName IS NOT NULL AND SMSiteContactInfo.LastName IS NOT NULL THEN 
				RTRIM(ISNULL(SMSiteContactInfo.FirstName,'') + ' ' + ISNULL(SMSiteContactInfo.LastName,''))
			ELSE
				NULL
			END,
		@DefaultContactPhone = SMSiteContactInfo.Phone,
		@CostingMethod = SMServiceSite.CostingMethod
	FROM dbo.SMServiceSite
		LEFT JOIN SMServiceSiteContact ON SMServiceSiteContact.SMCo = SMServiceSite.SMCo
		AND SMServiceSiteContact.ServiceSite = SMServiceSite.ServiceSite
		AND SMServiceSiteContact.ContactGroup = SMServiceSite.ContactGroup
		AND SMServiceSiteContact.ContactSeq = SMServiceSite.ContactSeq
		LEFT JOIN SMContact as SMSiteContactInfo ON SMSiteContactInfo.ContactGroup = SMServiceSiteContact.ContactGroup
		AND SMSiteContactInfo.ContactSeq = SMServiceSiteContact.ContactSeq
	
	WHERE SMServiceSite.SMCo = @SMCo 
		AND SMServiceSite.ServiceSite = @ServiceSite
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = 'Service Site has not been setup.'
		RETURN 1
    END
    
    IF @IsActive <> 'Y'
    BEGIN
		SET @msg = ISNULL(@msg,'') + ' - Inactive service site.'
		RETURN 1
    END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMServiceSiteVal] TO [public]
GO
