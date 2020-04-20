SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Chris Gall
-- Create date: 2/22/10
-- Modified By:	GF 12/15/2011 TK-10370 fix to lock batch
--
-- Description:	Unlocks/Locks a JC Progress Entry batch
-- =============================================
CREATE PROCEDURE [dbo].[vpspJCProgressBatchUpdate]
	@Key_JCCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @LockedYN AS BIT, @VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	-- Batch is Open Validation
	--IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_JCCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND [Status] = 0)
	--BEGIN
	--	RAISERROR('Cannot update. Batch is not in the Open status.', 16, 1)
	--	GOTO vspExit
	--END
	
	--DECLARE @InUseBy AS bVPUserName
	
	--SELECT @InUseBy = InUseBy
	--FROM HQBC (NOLOCK)
	--WHERE Co = @Key_JCCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
		
	--IF @InUseBy <> @VPUserName
	--	BEGIN
	--		RAISERROR('Another user is using this batch. Please reload your list of batches to view the batches you can use.', 16, 1)
	--	END
	--ELSE
	--	BEGIN
	--		-- This executes if the username matches or nobody is using the batch		
	--		UPDATE HQBC
	--		SET 
	--			InUseBy = CASE WHEN @LockedYN = 'Yes' THEN @VPUserName ELSE NULL END
	--		WHERE Co = @Key_JCCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
			
	--		EXEC vpspJCProgressBatchGet @Key_JCCo, @VPUserName, @Key_BatchId
	--	END
		
	EXEC vpspSetLockOnBatch @Key_JCCo, @Key_Mth, @Key_BatchId, @LockedYN, @VPUserName 
		
	EXEC vpspJCProgressBatchGet @Key_JCCo, @VPUserName, @Key_BatchId
		
	vspExit:
END
GO
GRANT EXECUTE ON  [dbo].[vpspJCProgressBatchUpdate] TO [VCSPortal]
GO
