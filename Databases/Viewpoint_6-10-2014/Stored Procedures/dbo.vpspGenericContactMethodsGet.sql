SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   PROCEDURE dbo.vpspGenericContactMethodsGet
/******************************
* created by CHS, 12/21/05
*******************************/
(@ContactID int)
AS
	
SET NOCOUNT ON;

SELECT ContactMethodID, ContactID, pContactMethods.ContactTypeID, ContactValue, SiteID,
pContactTypes.Description FROM pContactMethods with (nolock)
INNER JOIN pContactTypes with (nolock) 
ON pContactMethods.ContactTypeID = pContactTypes.ContactTypeID 
WHERE ContactID = @ContactID
ORDER BY pContactMethods.ContactTypeID ASC



GO
GRANT EXECUTE ON  [dbo].[vpspGenericContactMethodsGet] TO [VCSPortal]
GO
