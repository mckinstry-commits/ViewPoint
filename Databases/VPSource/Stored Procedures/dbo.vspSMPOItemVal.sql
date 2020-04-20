SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Modified:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
--
--
-- Create date: 4/11/11
-- Description:	Validation for PO items created within the SM PO Information form
-- =============================================
CREATE PROCEDURE [dbo].[vspSMPOItemVal]
	@POCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @BatchSeq int, @POItem bItem, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @PO varchar(30)
	
	SELECT @PO = PO
	FROM dbo.POHB
	WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId AND BatchSeq = @BatchSeq
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Batch could not be found'
		RETURN 1
	END

    EXEC @rcode = dbo.vspPOItemPOCDClosedCheck @co = @POCo, @po = @PO, @poitem = @POItem, @msg = @msg OUTPUT
    IF @rcode <> 0 RETURN @rcode
    
    SELECT @msg = [Description]
    FROM dbo.POIB
	WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId AND BatchSeq = @BatchSeq AND POItem = @POItem
    --It is ok if no results are found as this is the sproc used when adding new items
    
    
    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMPOItemVal] TO [public]
GO
