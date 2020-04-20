SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspGenericContactMethodsInsert
(
	@ContactID int,
	@ContactTypeID int,
	@ContactValue varchar(50),
	@SiteID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pContactMethods(ContactID, ContactTypeID, ContactValue, SiteID) 

VALUES (@ContactID, @ContactTypeID, @ContactValue, @SiteID);

SELECT ContactMethodID, ContactID, ContactTypeID, ContactValue, SiteID 

FROM pContactMethods with (nolock)

WHERE (ContactMethodID = SCOPE_IDENTITY())




GO
GRANT EXECUTE ON  [dbo].[vpspGenericContactMethodsInsert] TO [VCSPortal]
GO
