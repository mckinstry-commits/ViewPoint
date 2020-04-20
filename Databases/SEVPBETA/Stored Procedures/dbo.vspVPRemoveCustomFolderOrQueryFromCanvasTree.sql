SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPRemoveCustomFolderOrQueryFromCanvasTree]  
/***********************************************************
* CREATED BY: CC 04-01-2011
* MODIFIED By : HH 4/6/2012 TK-13724 Added CustomName
*				
*		
* Usage: Used by the tree in work centers to remove custom queries
*	
* 
* Input params:
*	
* Output params:
*	
* 
*****************************************************/
@CanvasId INT,
@ItemId INT,
@Seq VARCHAR(128)
AS
BEGIN
	DECLARE @QueryName VARCHAR(128);
	
	SELECT @QueryName = Item--select * from VPPartSettings
	FROM dbo.VPCanvasTreeItems 
	WHERE CanvasId = @CanvasId AND KeyID = @ItemId AND IsCustom = 'Y';
	
	DELETE 
	FROM dbo.VPCanvasTreeItems 
	WHERE CanvasId = @CanvasId AND KeyID = @ItemId AND IsCustom = 'Y';
	
	DELETE VPCanvasGridSettings
	FROM VPCanvasGridSettings
	INNER JOIN dbo.VPPartSettings ON VPCanvasGridSettings.PartId = dbo.VPPartSettings.KeyID
	WHERE dbo.VPCanvasGridSettings.QueryName = @QueryName 
			AND dbo.VPCanvasGridSettings.Seq = @Seq
			AND dbo.VPPartSettings.CanvasId = @CanvasId;
END
GO
GRANT EXECUTE ON  [dbo].[vspVPRemoveCustomFolderOrQueryFromCanvasTree] TO [public]
GO
