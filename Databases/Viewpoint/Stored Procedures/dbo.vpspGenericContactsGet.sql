SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspGenericContactsGet
/******************************
* created by CHS, 12/20/05
*
*******************************/
(
@pagesitecontrolid int
)
AS
	SET NOCOUNT ON;
SELECT ContactID, SiteID, Site, Name, Role, ContactDescription, Phone, Cell, Fax, eMailAddress, PageSiteControlID 

FROM pContacts with (nolock)

WHERE (PageSiteControlID = @pagesitecontrolid)
ORDER BY Name


GO
GRANT EXECUTE ON  [dbo].[vpspGenericContactsGet] TO [VCSPortal]
GO
