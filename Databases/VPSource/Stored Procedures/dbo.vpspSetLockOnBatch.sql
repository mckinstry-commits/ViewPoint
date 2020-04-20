SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tom Jochums
-- Create date: 2/22/10
-- Description:	Unlocks/Locks a batch with the given ID
-- =============================================
CREATE PROCEDURE [dbo].[vpspSetLockOnBatch]
	@Key_JCCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @LockedYN AS BIT, @VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @InUseBy AS bVPUserName
	
	SELECT @InUseBy = InUseBy
	FROM HQBC (NOLOCK)
	WHERE Co = @Key_JCCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
	
	
	IF @InUseBy <> @VPUserName
	BEGIN
		RAISERROR('Another user is using this batch. Please reload your list of batches to view the batches you can use.', 16, 1)
	END
	ELSE
	BEGIN
		-- This executes if the username matches or nobody is using the batch
		
		UPDATE HQBC
		SET 
			InUseBy = CASE WHEN @LockedYN = 1 THEN @VPUserName ELSE NULL END
		WHERE Co = @Key_JCCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
	END
END


GO
GRANT EXECUTE ON  [dbo].[vpspSetLockOnBatch] TO [VCSPortal]
GO
