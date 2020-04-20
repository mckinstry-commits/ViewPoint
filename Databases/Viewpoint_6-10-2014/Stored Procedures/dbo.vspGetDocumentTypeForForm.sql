SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspGetDocumentTypeForForm]
/************************************
*  Created: Chris G 04/10/13 - TFS Story 44707
* Modified: Chris G 05/01/13 - Reflect schema changes to remove VDocIntegration.DocumentTypeForm
*
* Gets a the mapped document type for a given form.
*
************************************/
(@form varchar(30))
as
set nocount on
   
    SELECT DocumentTypeId
      FROM Document.DocumentType
     WHERE Form = @form
   
return


GO
GRANT EXECUTE ON  [dbo].[vspGetDocumentTypeForForm] TO [public]
GO
