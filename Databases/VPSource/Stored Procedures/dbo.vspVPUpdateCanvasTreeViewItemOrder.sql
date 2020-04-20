SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPUpdateCanvasTreeViewItemOrder]
/*************************************
*	Created by:		CC 9/10/10- Issue 138988
*	Modified by:	
*   
*
**************************************/
@NodeId				int,
@OldParentId		int,
@NewParentId		int,
@NodesToUpdate		VARCHAR(MAX),
@NewIndexes			VARCHAR(MAX)
AS
BEGIN
	UPDATE VPCanvasTreeItems
	SET ParentId = @NewParentId
	WHERE KeyID = @NodeId;
	
	WITH NewOrderForOldItems(Id, NewIndex)
	AS
	(
		SELECT	TOP 100 PERCENT
				KeyID,
				ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
		FROM VPCanvasTreeItems
		WHERE ParentId = @OldParentId
		ORDER BY ItemOrder
	)
	UPDATE VPCanvasTreeItems
	SET ItemOrder = NewOrderForOldItems.NewIndex
	FROM VPCanvasTreeItems
	INNER JOIN NewOrderForOldItems ON VPCanvasTreeItems.KeyID = NewOrderForOldItems.Id;
	
	DECLARE @Id TABLE(KeyID int IDENTITY,
						   Names VARCHAR(150)
						   );
	DECLARE @Index TABLE(KeyID int IDENTITY,
						   Names VARCHAR(150)
						   );

	INSERT INTO @Id SELECT Names FROM [dbo].[vfTableFromArray](@NodesToUpdate);
	INSERT INTO @Index SELECT Names FROM [dbo].[vfTableFromArray](@NewIndexes);
	
	UPDATE VPCanvasTreeItems
	SET ItemOrder = CAST([@Index].Names AS int)
	FROM VPCanvasTreeItems
	INNER JOIN @Id ON CAST([@Id].Names AS int) = VPCanvasTreeItems.KeyID
	INNER JOIN @Index ON [@Id].KeyID = [@Index].KeyID;
	
END 
GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateCanvasTreeViewItemOrder] TO [public]
GO
