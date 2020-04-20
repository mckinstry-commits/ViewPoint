SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetCanvasTreeViewItems]
   /*************************************
   *	Created by:		CC 9/8/10- Issue 138988
   *	Modified by:	CJG 3/24/11 - TK-03299 added ShowItem
   *					CC  3/25/11 - added second result set to return hidden items
   *                    FDT 4/7/11 - added IconKey	
   *					CC 06/23/2011 - added username & company to filter out queries that the user is denied access to
   *					HH 05/10/2012 TK-14882 Added ItemSeq to selection
   *					GPT 10/17/2012 TK-18473 always show form queries (ItemType=1) Reviewed by HH.
   *
   **************************************/
(@CanvasId INT, @username bVPUserName, @co bCompany)
AS
BEGIN
	SELECT	KeyID ,
			VPCanvasTreeItems.ItemType ,
			VPCanvasTreeItems.ItemSeq ,
			COALESCE(VPCanvasTreeItems.ItemTitle, RIGHT(DDFH.Title, LEN(DDFH.Title) - 3), VPCanvasTreeItems.Item) AS Title,
			COALESCE(DDFH.Form, VPCanvasTreeItems.Item, '') AS Item ,
			VPCanvasTreeItems.ParentId ,
			VPCanvasTreeItems.ItemOrder ,
			ViewName ,
			CoColumn ,
			Expanded ,
			ShowItem ,
			IsCustom ,
			IconKey
	FROM dbo.VPCanvasTreeItems
	LEFT OUTER JOIN DDFH ON ItemType = 1 AND VPCanvasTreeItems.Item = DDFH.Form
	LEFT OUTER JOIN vfVPGetQuerySecurity(@username, @co) AS AvailableQueries ON dbo.VPCanvasTreeItems.Item = AvailableQueries.QueryName
	WHERE CanvasId = @CanvasId
	AND ShowItem = 'Y'
	AND ((Access = 0 AND ItemType = 4) OR (Access IS NULL OR ItemType = 1));
			
	SELECT	KeyID,
			COALESCE(VPCanvasTreeItems.ItemTitle, RIGHT(DDFH.Title, LEN(DDFH.Title) - 3), VPCanvasTreeItems.Item) AS Title,
			VPCanvasTreeItems.ItemType
	FROM dbo.VPCanvasTreeItems
	LEFT OUTER JOIN DDFH ON ItemType = 1 AND VPCanvasTreeItems.Item = DDFH.Form
	LEFT OUTER JOIN vfVPGetQuerySecurity(@username, @co) AS AvailableQueries ON dbo.VPCanvasTreeItems.Item = AvailableQueries.QueryName
	WHERE CanvasId = @CanvasId
	AND ShowItem = 'N'
	AND ((Access = 0 AND ItemType = 4) OR (Access IS NULL OR ItemType = 1));
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetCanvasTreeViewItems] TO [public]
GO
