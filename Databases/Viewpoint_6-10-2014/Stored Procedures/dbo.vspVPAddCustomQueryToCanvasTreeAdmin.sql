SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************
* CREATED BY: CJG 04-08-2011
* MODIFIED By : HH 10/29/2012 TK-18922 added update procedure
*				
*	
*  Mirrors vspVPAddCustomQueryToCanvasTree for the admin
*	
* 
* Input params:
*	
* Output params:
*	
* 
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPAddCustomQueryToCanvasTreeAdmin]  
@CanvasId INT,
@QueryId INT,
@ParentId INT,
@CustomName VARCHAR(128) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		DECLARE @gridConfigurationID int
	
	SELECT @gridConfigurationID = KeyID
	FROM VPDisplayGridSettings
	WHERE DisplayID = @CanvasId AND QueryName =
		(SELECT QueryName FROM VPGridQueries WHERE KeyID = @QueryId);

	IF EXISTS(
		SELECT * FROM dbo.VPDisplayTreeItems
		WHERE	TabNavigationID = @CanvasId
				AND GridConfigurationID = @gridConfigurationID
	)
	BEGIN
		-- Update
		UPDATE dbo.VPDisplayTreeItems 
		SET ItemTitle = CASE 
							WHEN @CustomName IS NULL OR @CustomName = '' THEN dbo.VPGridQueries.QueryTitle 
							ELSE @CustomName 
						END 
		FROM dbo.VPDisplayTreeItems
		INNER JOIN dbo.VPGridQueries ON dbo.VPGridQueries.QueryName = dbo.VPDisplayTreeItems.Item
		WHERE dbo.VPGridQueries.KeyID = @QueryId
				AND dbo.VPDisplayTreeItems.TabNavigationID = @CanvasId
				AND dbo.VPDisplayTreeItems.GridConfigurationID = @gridConfigurationID
				;
	END
	ELSE
	BEGIN
		-- Insert
		WITH LastItem
		AS
		(
			SELECT COALESCE(MAX(ItemOrder), 0) AS ItemOrder
			FROM dbo.VPDisplayTreeItems
			WHERE TabNavigationID = @CanvasId AND ParentID = @ParentId
		)
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
		SELECT	4 , -- ItemType - int
				dbo.VPGridQueries.QueryName , -- Item - varchar(2048)
				@ParentId , -- ParentId - int
				LastItem.ItemOrder , -- ItemOrder - int
				@CanvasId , -- CanvasId - int
				CASE 
					WHEN @CustomName IS NULL OR @CustomName = '' THEN dbo.VPGridQueries.QueryTitle 
					ELSE @CustomName 
				END , -- ItemTitle - varchar(128)
				'Y',  -- ShowItem - bYN
				'Y',  -- IsCustom - bYN
				-1, -- TreeItemTemplateID
				@gridConfigurationID
		FROM dbo.VPGridQueries 
		CROSS JOIN LastItem
		WHERE dbo.VPGridQueries.KeyID = @QueryId;
	END
END


GO
GRANT EXECUTE ON  [dbo].[vspVPAddCustomQueryToCanvasTreeAdmin] TO [public]
GO
