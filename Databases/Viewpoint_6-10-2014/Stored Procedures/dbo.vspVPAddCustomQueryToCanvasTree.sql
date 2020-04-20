SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPAddCustomQueryToCanvasTree]  
/***********************************************************
* CREATED BY: CC 04-01-2011
* MODIFIED By : HH TK-13724 Added @CustomName that serves as ItemTitle
*				HH 05/10/2012 TK-14882 Added @ItemSeq
*				
*		
* Usage: Used by the tree in work centers to add custom queries
*	
* 
* Input params:
*	
* Output params:
*	
* 
*****************************************************/
@CanvasId INT,
@QueryId INT,
@ParentId INT,
@CustomName varchar(128),
@ItemSeq INT
AS
BEGIN
	WITH LastItem
	AS
	(
		SELECT COALESCE(MAX(ItemOrder), 0) AS ItemOrder
		FROM dbo.VPCanvasTreeItems
		WHERE CanvasId = @CanvasId AND ParentId = @ParentId
	),
	NextKey
	AS
	(
		SELECT COALESCE(MAX(KeyID), 0) + 1 AS KeyID
		FROM dbo.VPCanvasTreeItems
	)
	INSERT INTO dbo.VPCanvasTreeItems
	        ( ItemType ,
			  ItemSeq ,
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
	SELECT	4 , -- ItemType - int
			@ItemSeq, --ItemSeq -int
	        dbo.VPGridQueries.QueryName , -- Item - varchar(2048)
	        @ParentId , -- ParentId - int
	        LastItem.ItemOrder , -- ItemOrder - int
	        @CanvasId , -- CanvasId - int
	        @CustomName , -- ItemTitle - varchar(128)
	        'N' , -- Expanded - bYN
	        'Y',  -- ShowItem - bYN
	        'Y', -- IsCustom - bYN
	        NextKey.KeyID
	FROM dbo.VPGridQueries 
	CROSS JOIN LastItem
	CROSS JOIN NextKey
	WHERE dbo.VPGridQueries.KeyID = @QueryId;
	
	--Add query to change messages if not already added
	INSERT INTO dbo.VPPartFormChangedMessages
	        ( FormName, FormTitle )
	SELECT	QueryName,
			QueryTitle
	FROM dbo.VPGridQueries
	LEFT OUTER JOIN dbo.VPPartFormChangedMessages ON QueryName = FormName
	WHERE dbo.VPGridQueries.KeyID = @QueryId AND FormName IS NULL;	
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPAddCustomQueryToCanvasTree] TO [public]
GO
