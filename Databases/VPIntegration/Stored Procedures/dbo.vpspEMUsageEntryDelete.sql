SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tom Jochums
-- Create date: 12/18/09
-- Description:	Deletes an existing EM Usage entry
-- =============================================
CREATE PROCEDURE [dbo].[vpspEMUsageEntryDelete]
	@Key_EMCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @Key_BatchSequence AS INT, @VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Batch is Open Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND [Status] = 0)
	BEGIN
		RAISERROR('Cannot delete. Batch is not in the Open status.', 16, 1)
		GOTO vspExit
	END	
	-- Batch Locked Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND InUseBy = @VPUserName)
	BEGIN
		RAISERROR('You must first lock the batch before being able to delete EM usage entries', 16, 1)
		GOTO vspExit
	END
	
	DELETE FROM EMBF
	WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND BatchSeq = @Key_BatchSequence
	
	vspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vpspEMUsageEntryDelete] TO [VCSPortal]
GO
