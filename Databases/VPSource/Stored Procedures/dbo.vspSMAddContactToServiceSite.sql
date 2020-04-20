SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/19/10
-- Description:	Adds the given contact to the list of associated contacts for a given service site. This is used when setting a service site's default contact.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAddContactToServiceSite]
	@ContactGroup bGroup,
	@ContactSeq int,
	@SMCo bCompany,
	@ServiceSite varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    INSERT SMServiceSiteContact (SMCo, ServiceSite, ContactGroup, ContactSeq)
    VALUES (@SMCo, @ServiceSite, @ContactGroup, @ContactSeq)
END

GO
GRANT EXECUTE ON  [dbo].[vspSMAddContactToServiceSite] TO [public]
GO
