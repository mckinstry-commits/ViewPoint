SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************
*	Created by:		CJG 4/8/2011
*	Modified by:	
* 
* Mirrors vspVPUpdateCanvasTreeViewItem for Admin
* 
**************************************/
CREATE PROCEDURE [dbo].[vspVPUpdateCanvasTreeViewItemAdmin]
	@NodeId			INT,
	@NewTitle		varchar(128)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE VPDisplayTreeItems 
	SET ItemTitle = @NewTitle 
	WHERE KeyID = @NodeId;
END

GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateCanvasTreeViewItemAdmin] TO [public]
GO
