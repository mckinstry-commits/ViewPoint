SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************
* CREATED BY: CJG 04-08-2011
* MODIFIED By : HH 10/29/2012 TK-18922 dummy parameter @Seq
*				
*		
* Mirrors vspVPRemoveCustomQueryFromCanvasTree for the admin
*	
* 
* Input params:
*	
* Output params:
*	
* 
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPRemoveCustomFolderOrQueryFromCanvasTreeAdmin]  
@CanvasId INT,
@ItemId INT,
@Seq INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @gridConfigurationID int

	SELECT @gridConfigurationID = GridConfigurationID FROM dbo.VPDisplayTreeItems
	WHERE TabNavigationID = @CanvasId AND KeyID = @ItemId AND IsCustom = 'Y';

    DELETE 
	FROM dbo.VPDisplayTreeItems 
	WHERE TabNavigationID = @CanvasId AND KeyID = @ItemId AND IsCustom = 'Y';
	
	DELETE
	FROM dbo.VPDisplayGridParameters
	WHERE GridConfigurationId = @gridConfigurationID
	
	DELETE
	FROM dbo.VPDisplayGridColumns
	WHERE GridConfigurationId = @gridConfigurationID
	
	DELETE
	FROM dbo.VPDisplayGridSettings
	WHERE KeyID = @gridConfigurationID
	
END



GO
GRANT EXECUTE ON  [dbo].[vspVPRemoveCustomFolderOrQueryFromCanvasTreeAdmin] TO [public]
GO
