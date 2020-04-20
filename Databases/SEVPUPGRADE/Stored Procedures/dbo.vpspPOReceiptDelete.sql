SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/18/09
-- Description:	Deletes an existing PO receipt
-- =============================================
CREATE PROCEDURE [dbo].[vpspPOReceiptDelete]
	@Key_POCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @Key_Seq_BatchSeq AS INT, 
	@VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT, @msg VARCHAR(256), @RecvdCost bDollar, @BOCost bDollar, @ECM bECM

	-- Batch Locked Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_POCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND InUseBy = @VPUserName)
	BEGIN
		RAISERROR('You must first lock the batch before being able to delete PO Receipts', 16, 1)
		GOTO vspExit
	END
	
	DELETE FROM dbo.PORB
	WHERE Co = @Key_POCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND BatchSeq = @Key_Seq_BatchSeq
	
	vspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vpspPOReceiptDelete] TO [VCSPortal]
GO
