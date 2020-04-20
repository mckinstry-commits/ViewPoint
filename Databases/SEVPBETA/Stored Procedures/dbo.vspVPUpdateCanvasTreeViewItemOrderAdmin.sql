SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************
*	Created by:		CJG 4/8/11
*	Modified by:	
*
* Mirrors vspVPUpdateCanvasTreeViewItemOrder for admin
*
**************************************/
CREATE PROCEDURE [dbo].[vspVPUpdateCanvasTreeViewItemOrderAdmin]
@NodeId				int,
@OldParentId		int,
@NewParentId		int,
@NodesToUpdate		VARCHAR(MAX),
@NewIndexes			VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE VPDisplayTreeItems
	SET ParentID = @NewParentId
	WHERE KeyID = @NodeId;
	
	WITH NewOrderForOldItems(Id, NewIndex)
	AS
	(
		SELECT	TOP 100 PERCENT
				KeyID,
				ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
		FROM VPDisplayTreeItems
		WHERE ParentID = @OldParentId
		ORDER BY ItemOrder
	)
	UPDATE VPDisplayTreeItems
	SET ItemOrder = NewOrderForOldItems.NewIndex
	FROM VPDisplayTreeItems
	INNER JOIN NewOrderForOldItems ON VPDisplayTreeItems.KeyID = NewOrderForOldItems.Id;
	
	DECLARE @Id TABLE(KeyID int IDENTITY,
						   Names VARCHAR(150)
						   );
	DECLARE @Index TABLE(KeyID int IDENTITY,
						   Names VARCHAR(150)
						   );

	INSERT INTO @Id SELECT Names FROM [dbo].[vfTableFromArray](@NodesToUpdate);
	INSERT INTO @Index SELECT Names FROM [dbo].[vfTableFromArray](@NewIndexes);
	
	UPDATE VPDisplayTreeItems
	SET ItemOrder = CAST([@Index].Names AS int)
	FROM VPDisplayTreeItems
	INNER JOIN @Id ON CAST([@Id].Names AS int) = VPDisplayTreeItems.KeyID
	INNER JOIN @Index ON [@Id].KeyID = [@Index].KeyID;
END

GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateCanvasTreeViewItemOrderAdmin] TO [public]
GO
