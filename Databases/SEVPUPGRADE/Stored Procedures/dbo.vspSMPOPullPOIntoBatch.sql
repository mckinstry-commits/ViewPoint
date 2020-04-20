SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Modified:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
--
--
-- Create date: 6/27/11
-- Description:	Pulls a PO back into a batch along with all items associated with the given work order
-- =============================================
CREATE PROCEDURE [dbo].[vspSMPOPullPOIntoBatch]
	@POCo bCompany, @PO varchar(30), @SMCo bCompany, @WorkOrder int, @BatchMonth bMonth, @BatchId bBatchID, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @POItem bItem

	EXEC @rcode = dbo.bspPOHBInsertExistingTrans @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @po = @PO, @includeitems = 'N', @errmsg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	DECLARE @POItemsToLoad TABLE (POItem bItem)
	
	--Only add the items that aren't already in another batch and are related to the given work order
	INSERT @POItemsToLoad
	SELECT POItem
	FROM dbo.POIT
	WHERE POCo = @POCo AND PO = @PO AND SMCo = @SMCo AND SMWorkOrder = @WorkOrder AND InUseMth IS NULL AND InUseBatchId IS NULL
	
	AddPOItemsLoop:
	BEGIN
		SELECT TOP 1 @POItem = POItem
		FROM @POItemsToLoad
		IF @@rowcount = 1
		BEGIN
			--The assumption here is that since we just created the batch and added the PO back in that the PO is the first batch record.
			EXEC dbo.bspPOIBInsertExistingTrans @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @po = @PO, @item = @POItem, @seq = 1, @errmsg = @msg OUTPUT
			
			DELETE @POItemsToLoad WHERE POItem = @POItem
			
			GOTO AddPOItemsLoop
		END
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMPOPullPOIntoBatch] TO [public]
GO
