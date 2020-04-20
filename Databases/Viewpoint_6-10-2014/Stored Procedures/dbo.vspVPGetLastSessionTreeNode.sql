SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		HH
* Create date:  TFS 43723 3/20/2013
* Modified Date: 
*				
* Description:	Get the KeyID for VPCanvasTreeItems by Item, Seq, CanvasId
*
*	Inputs:
*	
*
*	Outputs:
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPGetLastSessionTreeNode]
	-- Add the parameters for the stored procedure here
	@Item VARCHAR(2048),
	@ItemSeq INT, 
	@CanvasId INT,
    @TreeNodeId INT OUTPUT
	  
AS
BEGIN
		
	SELECT @TreeNodeId = KeyID 
	FROM VPCanvasTreeItems
	WHERE Item = @Item	
			AND ItemSeq = @ItemSeq
			AND CanvasId = @CanvasId;
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetLastSessionTreeNode] TO [public]
GO
