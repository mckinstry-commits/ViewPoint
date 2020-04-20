SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************
* CREATED BY: AL 1/23/12
* MODIFIED By : 
*				
*	
*  Mirrors vspVPAddCustomFolderToCanvasTree for the admin
*	
* 
* Input params:
*	
* Output params:
*	
* 
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPAddCustomFolderToCanvasTreeAdmin]  
@CanvasId INT,
@ParentId INT,
@KeyID INT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	DECLARE @gridConfigurationID int, @lastItem int
	
	--SELECT @gridConfigurationID = KeyID
	--FROM VPDisplayGridSettings
	--WHERE DisplayID = @CanvasId AND QueryName =
	--	(SELECT QueryName FROM VPGridQueries WHERE KeyID = @QueryId);

    SElect @lastItem =
		COALESCE(MAX(ItemOrder), 0)
		FROM dbo.VPDisplayTreeItems
		WHERE TabNavigationID = @CanvasId AND ParentID = @ParentId
	
	DECLARE @InsertedRecs table (KeyID INT)
		
	INSERT INTO dbo.VPDisplayTreeItems
	        ( ItemType ,
	          Item ,
	          ParentID ,
	          ItemOrder ,
	          TabNavigationID ,
	          ItemTitle ,
	          ShowItem,
	          IsCustom,
	          TreeItemTemplateID,
	          GridConfigurationID
	        )       
	VALUES
			(0 , -- ItemType - int
	        NULL , -- Item - varchar(2048)
	        @ParentId , -- ParentId - int
	        @lastItem , -- ItemOrder - int
	        @CanvasId , -- CanvasId - int
	        'New Folder' , -- ItemTitle - varchar(128)
	        'Y',  -- ShowItem - bYN
	        'Y',  -- IsCustom - bYN
	        -1, -- TreeItemTemplateID
	        NULL--@gridConfigurationID
	        )

	SELECT @KeyID = SCOPE_IDENTITY()
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVPAddCustomFolderToCanvasTreeAdmin] TO [public]
GO
