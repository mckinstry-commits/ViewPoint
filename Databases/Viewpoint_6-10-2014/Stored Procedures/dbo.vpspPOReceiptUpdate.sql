SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/18/09
--  Modified by:  TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
--				GF 11/16/2011 TK-10080 POItemLine added
--
-- Description:	Updates an existing PO receipt
-- =============================================
CREATE PROCEDURE [dbo].[vpspPOReceiptUpdate]
	@Key_POCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @Key_Seq_BatchSeq AS INT, 
	@PO AS varchar(30), @POItem AS bItem, @POItemLine AS INT, @RecvdDate AS bDate, 
	@RecvdBy AS VARCHAR(10), @Description AS bDesc, @RecvdUnits AS bUnits, 
	@RecvdCost AS bDollar, @BOUnits AS bUnits, @BOCost AS bDollar, 
	@ReceiverNumber AS VARCHAR(20), @VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT, @msg VARCHAR(256), @ECM bECM,
			@CurUnitCost bUnitCost, @UM bUM,
			@ItemType TINYINT

	-- Batch Locked Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_POCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND InUseBy = @VPUserName)
	BEGIN
		RAISERROR('You must first lock the batch before being able to update PO Receipts', 16, 1)
		GOTO vspExit
	END

	-- PO Validation
	EXEC @rcode = bspPOValVendInUse @Key_POCo, @PO, @Key_BatchId, @Key_Mth, NULL, NULL, NULL, @msg OUTPUT
	
	IF @rcode <> 0
	BEGIN
		SET @msg = 'PO Validation failed - ' + @msg
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END
	
	-- PO Item Validation
	EXEC @rcode = bspPOItemVal @Key_POCo, @PO, @POItem, @Key_BatchId, @Key_Mth, 'PO Receipt', NULL, NULL, NULL, @msg OUTPUT
	
	IF @rcode <> 0
	BEGIN
		SET @msg = 'PO Item Validation failed - ' + @msg
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END

---- TK-10080 validate PO Item Line
SELECT @ItemType = ItemType
FROM dbo.vPOItemLine WITH (NOLOCK)
WHERE POCo=@Key_POCo
	AND PO=@PO
	AND POItem=@POItem
	AND POItemLine=@POItemLine
IF @@ROWCOUNT = 0
	BEGIN
	RAISERROR('The PO Item Line is not valid.', 16, 1)
	GOTO vspExit
	END
	
---- cannot receive against type 6 - SM Work Order
IF @ItemType = 6
	BEGIN
	RAISERROR('The PO Item Line is type 6 - SM Work Order. Cannot receive for this type.', 16, 1)
	GOTO vspExit
	END

	-- Validate that the PO doesn't change on batch change items
	IF EXISTS(SELECT TOP 1 1
		FROM PORB WITH (NOLOCK)
		WHERE Co = @Key_POCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND BatchSeq = @Key_Seq_BatchSeq AND BatchTransType = 'C' AND PO <> @PO)
	BEGIN
		RAISERROR('You can''t change the PO number on a change batch transaction.', 16, 1)
		GOTO vspExit
	END
	
	SELECT @ECM = CurECM
		,@CurUnitCost = CurUnitCost
		,@UM = UM
	FROM POIT
	WHERE POCo = @Key_POCo AND PO = @PO AND POItem = @POItem
	
	IF @UM = 'LS'
	BEGIN
		IF @RecvdCost IS NULL
		BEGIN
			RAISERROR('The PO item selected has a lump sum unit of measure so you must supply the changes to received total.', 16, 1)
			GOTO vspExit
		END
	
		SELECT @RecvdUnits = 0
			,@BOUnits = 0
			,@BOCost = ISNULL(@BOCost, @RecvdCost * -1)
	END
	ELSE
	BEGIN
		IF @RecvdUnits IS NULL
		BEGIN
			RAISERROR('The changes to received units is required for PO items that don''t have a lump sum unit of measure.', 16, 1)
			GOTO vspExit
		END
	
		SELECT @BOUnits = ISNULL(@BOUnits, @RecvdUnits * -1)
			,@RecvdCost = @CurUnitCost * @RecvdUnits
			,@BOCost = @CurUnitCost * @BOUnits
			
		IF @ECM IS NOT NULL
		BEGIN
			SELECT @RecvdCost = @RecvdCost / dbo.vpfECMFactor(@ECM)
				,@BOCost = @BOCost / dbo.vpfECMFactor(@ECM)
		END
	END

	UPDATE dbo.PORB
	SET PO = @PO
		,POItem = @POItem
		,RecvdDate = @RecvdDate
		,RecvdBy = @RecvdBy
		,[Description] = @Description
		,RecvdUnits = @RecvdUnits
		,BOUnits = @BOUnits
		,Receiver# = @ReceiverNumber
		,RecvdCost = @RecvdCost
		,BOCost = @BOCost
		,ECM = @ECM
		----TK-00000
		,POItemLine = @POItemLine
	WHERE Co = @Key_POCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND BatchSeq = @Key_Seq_BatchSeq

	EXEC vpspPOReceiptGet @Key_POCo, @Key_Mth, @Key_BatchId, @VPUserName, @Key_Seq_BatchSeq
	
	vspExit:
END


GO
GRANT EXECUTE ON  [dbo].[vpspPOReceiptUpdate] TO [VCSPortal]
GO
