SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPUpdateCanvasTreeViewItemVisibility]
/*************************************
*	Created by:		CC 03/27/2011
*	Modified by:	
*   
*
**************************************/
@NodeId				INT,
@VisibileState		bYN
AS
BEGIN
	UPDATE dbo.VPCanvasTreeItems
	SET ShowItem = @VisibileState
	WHERE KeyID = @NodeId;
END 
GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateCanvasTreeViewItemVisibility] TO [public]
GO
