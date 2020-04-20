SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspGenericContactsInsert
(
	@SiteID int,
	@Site varchar(255),
	@Name varchar(80),
	@Role varchar(255),
	@ContactDescription varchar(255),
	@Phone varchar(20),
	@Cell varchar(20),
	@Fax varchar(20),
	@eMailAddress varchar(255),
	@PageSiteControlID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pContacts(SiteID, Site, Name, Role, ContactDescription, Phone, Cell, Fax, eMailAddress, PageSiteControlID) 
VALUES (@SiteID, @Site, @Name, @Role, @ContactDescription, @Phone, @Cell, @Fax, @eMailAddress, @PageSiteControlID);

	SELECT ContactID, SiteID, Site, Name, Role, ContactDescription, Phone, Cell, Fax, eMailAddress, PageSiteControlID 
	
	FROM pContacts with (nolock)
	
	WHERE (ContactID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspGenericContactsInsert] TO [VCSPortal]
GO
