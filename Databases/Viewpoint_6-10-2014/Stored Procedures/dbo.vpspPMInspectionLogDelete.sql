SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMInspectionLogDelete]
/************************************************************
* CREATED By:     2/16/06  CHS
* Modified By:	GF 11/08/2011 TK-00000 use key id for delete
*
*
* USAGE:
*   Deletes PM Inspection Log
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(@Original_KeyID BIGINT)

AS
SET NOCOUNT ON;

---- DELETE INSPECTION LOG
DELETE FROM dbo.PMIL WHERE [KeyID] = @Original_KeyID;



GO
GRANT EXECUTE ON  [dbo].[vpspPMInspectionLogDelete] TO [VCSPortal]
GO
