SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE dbo.vpspContactMethodsGet
/******************************
* created by CHS, 12/21/05
*******************************/
(@ContactID int)
AS
	SET NOCOUNT ON;
SELECT 
pContactTypes.Description,
pContactMethods.ContactMethodID, 
pContactMethods.ContactID, 
pContactMethods.ContactTypeID, 
pContactMethods.ContactValue,
pContactMethods.SiteID

FROM pContactTypes with (nolock)
INNER JOIN pContactMethods with (nolock) ON pContactTypes.ContactTypeID = pContactMethods.ContactTypeID

WHERE 
pContactMethods.ContactID = @ContactID
                      
ORDER BY pContactMethods.ContactMethodID ASC




GO
GRANT EXECUTE ON  [dbo].[vpspContactMethodsGet] TO [VCSPortal]
GO
