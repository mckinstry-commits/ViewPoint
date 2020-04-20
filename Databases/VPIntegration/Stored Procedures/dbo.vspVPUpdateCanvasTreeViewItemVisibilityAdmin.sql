SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************
*	Created by:		CJG 04/08/2011
*	Modified by:	
*   
*
**************************************/
CREATE PROCEDURE [dbo].[vspVPUpdateCanvasTreeViewItemVisibilityAdmin]
@NodeId				INT,
@VisibileState		bYN
AS
BEGIN
	UPDATE dbo.VPDisplayTreeItems
	SET ShowItem = @VisibileState
	WHERE KeyID = @NodeId;
END

GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateCanvasTreeViewItemVisibilityAdmin] TO [public]
GO
