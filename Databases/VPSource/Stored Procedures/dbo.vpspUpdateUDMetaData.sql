SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ken E / Chris G
-- Create date: 8/23/12
-- Description:	Updates UD Fields/Column in Connects meta data.
--				NOTE: This is called each time a Portal control
--					  is loaded so it must be as efficient as possible.
-- =============================================
CREATE PROCEDURE [dbo].[vpspUpdateUDMetaData] 
	(@portalControlId INT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @view varchar(128), @viewVersionConnects int, @viewVersionViewpoint int, 
			@dataGridID int, @detailsID int
	
	-- Get the View associated with the Portal Control
	SELECT @view = PrimaryTable FROM pPortalControls WHERE PortalControlID = @portalControlId
	
	SELECT @viewVersionConnects = PrimaryTableVersion FROM pPortalControls WHERE PortalControlID = @portalControlId
	SELECT @viewVersionViewpoint = [Version] FROM vUDVersion WHERE TableName = @view
	
	-- IF the Viewpoint version is NULL (ie. doesnt exist in the table) treat that as 
	-- version 0.  So if Connects Version = NULL and Viewpoint Version = NULL that will
	-- be a non-equal initial condition forcing the update.  However,  if Connects Version = 0
	-- and Viewpoint Version = NULL, that is considered equal (unchanged).  
	-- Viewpoint versions start at 1
	IF @viewVersionViewpoint IS NULL
	BEGIN
		SET @viewVersionViewpoint = 0
	END
	
	-- If the version hasn't changed bail
	IF @viewVersionViewpoint = @viewVersionConnects
	BEGIN
		RETURN
	END
	
	-- Get the DataGrid or Details record for the Portal Control.  We can safely assume the
	-- TopLeftTable determines the type of control (Grid or Details).
	SELECT @dataGridID = DataGridID, @detailsID = DetailsID FROM pPortalHTMLTables
	INNER JOIN pPortalControlLayout ON HTMLTableID = TopLeftTableID 
		AND PortalControlID = @portalControlId
	
	-- Update the appropriate Grid or Details control
	IF @dataGridID IS NOT NULL
	BEGIN
		EXEC vpspUpdateUDGridMetaData @dataGridID, @view
	END
	ELSE IF @detailsID IS NOT NULL
	BEGIN
		EXEC vpspUpdateUDDetailsMetaData @portalControlId, @view
	END
	
	-- Update the Connects version to match the Viewpoint version.
	UPDATE pPortalControls SET PrimaryTableVersion = @viewVersionViewpoint WHERE PortalControlID = @portalControlId
END
GO
GRANT EXECUTE ON  [dbo].[vpspUpdateUDMetaData] TO [VCSPortal]
GO
