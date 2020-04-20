SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMDrawingLogDelete]
/************************************************************
* CREATED By:	GF 11/08/2011 TK-09736
*
* USAGE:
*   Deletes PM Drawing Log
*
* CALLED FROM:
*	ViewpointCS Portal  
*   
************************************************************/
(@Original_KeyID BIGINT)

AS
SET NOCOUNT ON;

---- TK-09736
DECLARE @rcode int, @Message varchar(255),
		@Original_Drawing nvarchar(50),
		@Original_DrawingType nvarchar(50),
		@Original_PMCo nvarchar(50),
		@Original_Project nvarchar(50)
SET @rcode = 0
SET @Message = ''

---- GET DRAWING KEY DATA
SELECT 	@Original_Drawing = Drawing,
		@Original_DrawingType = DrawingType,
		@Original_PMCo = PMCo,
		@Original_Project = Project
FROM dbo.PMDG WHERE KeyID = @Original_KeyID
IF @@ROWCOUNT = 0 RETURN

---- check for drawing revisions
IF EXISTS(SELECT 1 FROM dbo.PMDR WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND DrawingType = @Original_DrawingType
				AND Drawing = @Original_Drawing)
	BEGIN
	SET @rcode = 1
	SET @Message = 'Drawing Revisions exist for this drawing!'
	GoTo bspmessage
	END

---- DELETE DRAWING LOG
BEGIN
	DELETE FROM dbo.PMDG 
	WHERE KeyID = @Original_KeyID
END

RETURN


bspmessage:
	RAISERROR(@Message, 11, -1);
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogDelete] TO [VCSPortal]
GO
