SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tom Jochums
-- Create date: 3/11/10
-- Description:	Deletes an EM Usage Entry batch owned by the VPUserName
-- =============================================
CREATE PROCEDURE [dbo].[vpspEMUsageEntryBatchDelete]
	@Key_EMCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Batch is Open Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND [Status] = 0)
	BEGIN
		RAISERROR('Cannot update. Batch is not in the Open status.', 16, 1)
		GOTO vspExit
	END
	
	DECLARE @InUseBy AS bVPUserName	
	
	SELECT @InUseBy = InUseBy
	FROM HQBC (NOLOCK)
	WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId	
	
	IF @InUseBy <> @VPUserName
	BEGIN
		RAISERROR('Another user is using this batch. Please reload your list of batches to view the batches you can use.', 16, 1)
	END
	ELSE

	UPDATE HQBC
	SET 
		InUseBy = 'VCSPortal'
	WHERE Co = @Key_EMCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
		
	BEGIN
		DECLARE @msg varchar(60)
		DECLARE @retcode AS int
		-- Call the V6 Batch Delete - Pass the company, month, batch id and the new status of 6
		EXEC @retcode = bspEMBatchDelete @Key_EMCo, @Key_Mth, @Key_BatchId, 6, @msg output
		IF @retcode <> 0
		BEGIN
			RAISERROR(@msg, 16, 1)
		END
			
		EXEC vpspEMUsageEntryBatchGet @Key_EMCo, @VPUserName, @Key_BatchId
	END

    UPDATE HQBC
	   SET InUseBy = @VPUserName
	 WHERE Co = @Key_EMCo 
	   AND Mth = @Key_Mth 
	   AND BatchId = @Key_BatchId	
	vspExit:
END
GO
GRANT EXECUTE ON  [dbo].[vpspEMUsageEntryBatchDelete] TO [VCSPortal]
GO
