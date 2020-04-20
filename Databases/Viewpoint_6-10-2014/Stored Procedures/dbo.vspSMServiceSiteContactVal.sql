SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/19/10
-- Description:	SM Contact validation that is used specifically for a service site's main contact
-- =============================================
CREATE PROCEDURE [dbo].[vspSMServiceSiteContactVal]
	@ContactGroup bGroup,
	@Contact varchar(60),
	@SMCo bCompany,
	@ServiceSite varchar(20),
	@ContactSeq int OUTPUT,
	@ContactAssociatedWithServieSite bYN OUTPUT,
	@msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @ContactAssociatedWithServieSite = 'N'

	EXEC dbo.vspSMContactVal
		@ContactGroup = @ContactGroup,
		@Contact = @Contact,
		@ContactSeq = @ContactSeq OUTPUT,
		@msg = @msg OUTPUT
		
	-- We didn't find any contact so return validation failed
	IF @ContactSeq IS NULL
	BEGIN
		RETURN 1
	END
	
	--We return whether the contact is associated with the service site so that we can add them if they are not
	IF EXISTS(SELECT 1 FROM dbo.SMServiceSiteContact WHERE SMCo = @SMCo AND ServiceSite = @ServiceSite AND ContactGroup = @ContactGroup AND ContactSeq = @ContactSeq)
	BEGIN
		SET @ContactAssociatedWithServieSite = 'Y'
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMServiceSiteContactVal] TO [public]
GO
