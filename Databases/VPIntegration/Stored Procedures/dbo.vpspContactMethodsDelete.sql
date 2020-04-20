SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.vpspContactMethodsDelete
(
	@Original_ContactMethodID int,
	@Original_ContactID int,
	@Original_ContactTypeID int,
	@Original_ContactValue varchar(50),
	@Original_SiteID int
)
AS
	SET NOCOUNT OFF;
	
DELETE FROM pContactMethods

WHERE (ContactMethodID = @Original_ContactMethodID) 

AND (ContactID = @Original_ContactID) 
AND (ContactTypeID = @Original_ContactTypeID) 
AND (ContactValue = @Original_ContactValue OR @Original_ContactValue IS NULL AND ContactValue IS NULL) 
AND (SiteID = @Original_SiteID OR @Original_SiteID IS NULL AND SiteID IS NULL)



GO
GRANT EXECUTE ON  [dbo].[vpspContactMethodsDelete] TO [VCSPortal]
GO
