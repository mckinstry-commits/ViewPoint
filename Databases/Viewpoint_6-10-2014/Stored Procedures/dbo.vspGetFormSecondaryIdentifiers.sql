SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspGetFormSecondaryIdentifiers]
/************************************
* Created: Chris G 04/10/13 - TFS Story 44707
* Modified: 
*
* Gets a list of secondary identifier mapping for a given form.
*
************************************/
(@form varchar(30))
as
set nocount on
   
SELECT Seq, UseDescription, DocumentSecondaryIdentifierTypeId
  FROM VDocIntegration.DoumentSecondaryIdentifierForm
 WHERE Form = @form
   
return


GO
GRANT EXECUTE ON  [dbo].[vspGetFormSecondaryIdentifiers] TO [public]
GO
