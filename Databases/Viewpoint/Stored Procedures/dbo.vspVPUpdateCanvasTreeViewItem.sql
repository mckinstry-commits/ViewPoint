SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[vspVPUpdateCanvasTreeViewItem]
/*************************************
*	Created by:		CC 9/8/2010 - Issue 138988
*	Modified by:	
* 
* 
**************************************/
	@NodeId			INT,
	@NewTitle		varchar(128)
AS
BEGIN
	
	UPDATE VPCanvasTreeItems 
	SET ItemTitle = @NewTitle 
	WHERE KeyID = @NodeId;
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateCanvasTreeViewItem] TO [public]
GO
