SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMDrawingLogRevisionsDelete]
 /************************************************************
 * CREATED:     9/27/06  CHS
 * MODIFIED:	AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
 *				GF 11/08/2011 TK-09736 use key id
 *
 *
 * USAGE:
 * Deletes a drawing log revision
 *
 * CALLED FROM:
 *	ViewpointCS Portal  
 *
 * INPUT PARAMETERS
 *    JCCo and Job 
 *
 * OUTPUT PARAMETERS
 *   
 * RETURN VALUE
 *   
 ************************************************************/
 ----TK-09736
 (@Original_KeyID BIGINT)

AS
SET NOCOUNT ON;

---- DELETE DRAWING LOG REVISION
BEGIN
	DELETE FROM dbo.PMDR
	WHERE KeyID = @Original_KeyID
END

RETURN

--    (
--      @Original_PMCo bCompany,
--      @Original_Project bJob,
--      @Original_DrawingType bDocType,
--      @Original_Drawing bDocument,
--      @Original_Rev TINYINT,
--      @Original_RevisionDate bDate,
--      @Original_Status bStatus,
--      @Original_Notes VARCHAR(MAX),
--      @Original_UniqueAttchID UNIQUEIDENTIFIER,
--      @Original_Description bDesc
--    )
--AS 
--    SET NOCOUNT ON ;
 
--    DELETE  FROM PMDR
--    WHERE   ( Drawing = @Original_Drawing )
--            AND ( DrawingType = @Original_DrawingType )
--            AND ( PMCo = @Original_PMCo )
--            AND ( Project = @Original_Project )
--            AND ( Rev = @Original_Rev )
--            AND ( RevisionDate = @Original_RevisionDate
--                  OR @Original_RevisionDate IS NULL
--                  AND RevisionDate IS NULL
--                )
--            AND ( Description = @Original_Description
--                  OR @Original_Description IS NULL
--                  AND Description IS NULL
--                )
--            AND ( Status = @Original_Status
--                  OR @Original_Status IS NULL
--                  AND Status IS NULL
--                ) 





GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogRevisionsDelete] TO [VCSPortal]
GO
