SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE dbo.vpspGenericContactMethodsUpdate
(
	@ContactMethodID int, 
	@ContactID int,
	@ContactTypeID int,
	@ContactValue varchar(50),
	@SiteID int,
	@Original_ContactMethodID int, 
	@Original_ContactID int,
	@Original_ContactTypeID int,
	@Original_ContactValue varchar(50),
	@Original_SiteID int
)

AS
	
SET NOCOUNT OFF;

UPDATE pContactMethods 
SET ContactID = @ContactID, ContactTypeID = @ContactTypeID, ContactValue = @ContactValue, 
SiteID = @SiteID 

WHERE (ContactMethodID = @ContactMethodID); 
--AND (ContactID = @Original_ContactID) 
--AND (ContactTypeID = @Original_ContactTypeID) 
--AND (ContactValue = @Original_ContactValue OR @Original_ContactValue IS NULL AND ContactValue IS NULL) 
--AND (SiteID = @Original_SiteID OR @Original_SiteID IS NULL AND SiteID IS NULL);

SELECT ContactMethodID, ContactID, ContactTypeID, ContactValue, SiteID 
FROM pContactMethods with (nolock)
WHERE (ContactMethodID = @ContactMethodID)





GO
GRANT EXECUTE ON  [dbo].[vpspGenericContactMethodsUpdate] TO [VCSPortal]
GO
