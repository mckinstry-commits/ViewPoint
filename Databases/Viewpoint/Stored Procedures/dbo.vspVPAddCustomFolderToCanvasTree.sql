SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPAddCustomFolderToCanvasTree]  
/***********************************************************
* CREATED BY: AL 1/23/12
* MODIFIED By : 
*				
*		
* Usage: Used by the tree in work centers to add custom folders
*	
* 
* Input params:
*	
* Output params:
*	
* 
*****************************************************/
@CanvasId INT,
@ParentId INT,
@KeyID INT OUTPUT
AS
BEGIN
DECLARE @lastItem INT, @nextKey INT

	SELECT @lastItem = 
		COALESCE(MAX(ItemOrder), 0)
		FROM dbo.VPCanvasTreeItems
		WHERE CanvasId = @CanvasId AND ParentId = @ParentId

	SELECT @nextKey =
		COALESCE(MAX(KeyID), 0) + 1
		FROM dbo.VPCanvasTreeItems
		
	SELECT @KeyID = @nextKey
		
	INSERT INTO dbo.VPCanvasTreeItems
	        ( ItemType ,
	          Item ,
	          ParentId ,
	          ItemOrder ,
	          CanvasId ,
	          ItemTitle ,
	          Expanded ,
	          ShowItem ,
	          IsCustom ,
	          KeyID
	        )
	VALUES (
		   0 , -- ItemType - int
	        NULL , -- Item - varchar(2048)
	        @ParentId , -- ParentId - int
	        @lastItem , -- ItemOrder - int
	        @CanvasId , -- CanvasId - int
	        'New Folder' , -- ItemTitle - varchar(128)
	        'N' , -- Expanded - bYN
	        'Y',  -- ShowItem - bYN
	        'Y', -- IsCustom - bYN
	        @nextKey
	        )
	
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPAddCustomFolderToCanvasTree] TO [public]
GO
