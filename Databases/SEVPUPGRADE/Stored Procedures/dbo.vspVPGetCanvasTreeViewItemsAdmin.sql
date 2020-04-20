SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************
*	Created by:		CJG 4/7/11
*	Modified by:	CC 06/23/2011 - added username and company for semetry with vspVPGetCanvasTreeViewItems, but are ignored in the admin setup
*   
*	Mirrors vspVPGetCanvasTreeViewItems for the Admin form
*
**************************************/
CREATE PROCEDURE [dbo].[vspVPGetCanvasTreeViewItemsAdmin]
	(@CanvasId INT, @username bVPUserName, @co bCompany)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    SELECT	ISNULL(VPDisplayTreeItems.KeyID, -1) AS KeyID ,
			0 as ItemSeq,
			ISNULL(VPDisplayTreeItems.ItemType, VPCanvasTreeItemsTemplate.ItemType) AS ItemType ,
			COALESCE(VPDisplayTreeItems.ItemTitle, VPCanvasTreeItemsTemplate.ItemTitle, RIGHT(DDFH.Title, LEN(DDFH.Title) - 3)) AS Title,
			COALESCE(VPDisplayTreeItems.Item, DDFH.Form, VPCanvasTreeItemsTemplate.Item, '') AS Item ,
			VPDisplayTreeItems.ParentID AS ParentId ,
			ISNULL(VPDisplayTreeItems.ItemOrder, VPCanvasTreeItemsTemplate.ItemOrder) AS ItemOrder ,
			DDFH.ViewName ,
			DDFH.CoColumn ,
			VPCanvasTreeItemsTemplate.Expanded ,
			'Y' AS ShowItem,
			ISNULL(VPDisplayTreeItems.IsCustom, 'N') AS IsCustom,
			DDFH.IconKey
	FROM VPDisplayTreeItems
	LEFT OUTER JOIN VPCanvasTreeItemsTemplate
		ON VPCanvasTreeItemsTemplate.KeyID = VPDisplayTreeItems.TreeItemTemplateID
	LEFT OUTER JOIN DDFH ON VPCanvasTreeItemsTemplate.ItemType = 1 AND VPCanvasTreeItemsTemplate.Item = DDFH.Form
	WHERE VPDisplayTreeItems.TabNavigationID = @CanvasId
	AND VPDisplayTreeItems.ShowItem = 'Y';
	
	
	SELECT	ISNULL(VPDisplayTreeItems.KeyID, -1) AS KeyID ,
			COALESCE(VPDisplayTreeItems.ItemTitle, VPCanvasTreeItemsTemplate.ItemTitle, RIGHT(DDFH.Title, LEN(DDFH.Title) - 3)) AS Title,
			ISNULL(VPDisplayTreeItems.ItemType, VPCanvasTreeItemsTemplate.ItemType) AS ItemType
	FROM VPDisplayTreeItems
	LEFT OUTER JOIN VPCanvasTreeItemsTemplate
		ON VPCanvasTreeItemsTemplate.KeyID = VPDisplayTreeItems.TreeItemTemplateID
	LEFT OUTER JOIN DDFH ON VPCanvasTreeItemsTemplate.ItemType = 1 AND VPCanvasTreeItemsTemplate.Item = DDFH.Form
	WHERE VPDisplayTreeItems.TabNavigationID = @CanvasId
	AND VPDisplayTreeItems.ShowItem = 'N';
    
END


GO
GRANT EXECUTE ON  [dbo].[vspVPGetCanvasTreeViewItemsAdmin] TO [public]
GO
