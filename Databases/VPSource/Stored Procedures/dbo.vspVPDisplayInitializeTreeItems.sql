SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************
*	Created by:		CJG 4/8/11 
*	Modified by:	
*   
*	Initializes the TreeItems for new records or resets.
*
**************************************/
CREATE PROCEDURE [dbo].[vspVPDisplayInitializeTreeItems]
	@TabNavigationID int, @TemplateName varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DELETE FROM VPDisplayTreeItems WHERE TabNavigationID = @TabNavigationID

    INSERT INTO VPDisplayTreeItems
		(TabNavigationID, TreeItemTemplateID, ShowItem, ItemOrder, ItemTitle, ParentID)
		(SELECT @TabNavigationID, KeyID, ShowItem, ItemOrder, NULL, ParentId
		 FROM VPCanvasTreeItemsTemplate
		 WHERE TemplateName = @TemplateName)
	
	-- Set the Parents relative to the new Items
	UPDATE t1
	SET ParentID = t2.KeyID
	FROM VPDisplayTreeItems t1
	JOIN VPDisplayTreeItems t2 ON t2.TreeItemTemplateID = t1.ParentID
	WHERE t1.TabNavigationID = @TabNavigationID AND t2.TabNavigationID = @TabNavigationID
END
GO
GRANT EXECUTE ON  [dbo].[vspVPDisplayInitializeTreeItems] TO [public]
GO
