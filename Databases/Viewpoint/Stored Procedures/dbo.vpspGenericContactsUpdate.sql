SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspGenericContactsUpdate
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
	@PageSiteControlID int,
	@Original_ContactID int,
	@Original_Cell varchar(20),
	@Original_ContactDescription varchar(255),
	@Original_Fax varchar(20),
	@Original_Name varchar(80),
	@Original_PageSiteControlID int,
	@Original_Phone varchar(20),
	@Original_Role varchar(255),
	@Original_Site varchar(255),
	@Original_SiteID int,
	@Original_eMailAddress varchar(255),
	@ContactID int
)
AS
	SET NOCOUNT OFF;
UPDATE pContacts 
SET SiteID = @SiteID, Site = @Site, Name = @Name, Role = @Role, ContactDescription = @ContactDescription, Phone = @Phone, Cell = @Cell, Fax = @Fax, eMailAddress = @eMailAddress, PageSiteControlID = @PageSiteControlID 

WHERE (ContactID = @Original_ContactID) 
AND (Cell = @Original_Cell OR @Original_Cell IS NULL AND Cell IS NULL) 
AND (ContactDescription = @Original_ContactDescription OR @Original_ContactDescription IS NULL AND ContactDescription IS NULL) 
AND (Fax = @Original_Fax OR @Original_Fax IS NULL AND Fax IS NULL) 
AND (Name = @Original_Name OR @Original_Name IS NULL AND Name IS NULL) 
AND (PageSiteControlID = @Original_PageSiteControlID OR @Original_PageSiteControlID IS NULL AND PageSiteControlID IS NULL) 
AND (Phone = @Original_Phone OR @Original_Phone IS NULL AND Phone IS NULL) 
AND (Role = @Original_Role OR @Original_Role IS NULL AND Role IS NULL) 
AND (Site = @Original_Site OR @Original_Site IS NULL AND Site IS NULL) 
AND (SiteID = @Original_SiteID) 
AND (eMailAddress = @Original_eMailAddress OR @Original_eMailAddress IS NULL AND eMailAddress IS NULL);

	SELECT ContactID, SiteID, Site, Name, Role, ContactDescription, Phone, Cell, Fax, eMailAddress, PageSiteControlID 
	FROM pContacts with (nolock)
	WHERE (ContactID = @ContactID)


GO
GRANT EXECUTE ON  [dbo].[vpspGenericContactsUpdate] TO [VCSPortal]
GO
