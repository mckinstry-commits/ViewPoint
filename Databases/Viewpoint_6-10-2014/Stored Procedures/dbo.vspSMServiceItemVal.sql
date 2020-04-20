SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMServiceItemVal]
	/******************************************************
	* CREATED BY:  MarkH 
	* MODIFIED By: Jacob V 8/9/10 Updated to reflect changes to service site
	*			   Lane G 4/3/13 Returns back Class, Manufacturer, Model, SerialNumber.
	* Usage:  Validates a Service Item.  Service Items are 
	*			unique to SMCo/ServiceSite
	*	
	*
	* Input params:
	*
	*	@SMCo - SM Company
	*	@ServiceSite - SM Service Site
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@SMCo bCompany, @ServiceSite varchar(20), @ServiceableItem varchar(20), @Class varchar(15) = NULL OUTPUT,  @Type varchar(15) = NULL OUTPUT,  @Manufacturer varchar(20) = NULL OUTPUT,  @Model varchar(20) = NULL OUTPUT,  @SerialNumber varchar(60) = NULL OUTPUT, @msg varchar(100) OUTPUT   	
   	
AS
BEGIN
	SET NOCOUNT ON
   	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company.'
		RETURN 1
	END
	
	IF @ServiceSite IS NULL
	BEGIN
		SET @msg = 'Missing SM Service Site.'
		RETURN 1
	END
	
	IF @ServiceableItem IS NULL
	BEGIN
		SET @msg = 'Missing SM Serviceable Item.'
		RETURN 1
	END

	--    varchar(60) = NULL OUTPUT, 
	SELECT @Class = Class, @Type = [Type], @Manufacturer = Manufacturer, @Model = Model, @SerialNumber = SerialNumber, @msg = [Description]
	FROM dbo.SMServiceItems
	WHERE SMCo = @SMCo AND ServiceSite = @ServiceSite AND ServiceItem = @ServiceableItem
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = 'Serviceable Item has not been setup.'
		RETURN 1
    END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMServiceItemVal] TO [public]
GO
