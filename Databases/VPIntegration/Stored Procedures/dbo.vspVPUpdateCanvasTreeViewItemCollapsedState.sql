SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPUpdateCanvasTreeViewItemCollapsedState]
/*************************************
*	Created by:		CC 9/10/10- Issue 138988
*	Modified by:	
*   
*
**************************************/
@NodeId				INT,
@ExpandedState		bYN
AS
BEGIN
	UPDATE dbo.VPCanvasTreeItems
	SET Expanded = @ExpandedState
	WHERE KeyID = @NodeId;
END 
GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateCanvasTreeViewItemCollapsedState] TO [public]
GO
