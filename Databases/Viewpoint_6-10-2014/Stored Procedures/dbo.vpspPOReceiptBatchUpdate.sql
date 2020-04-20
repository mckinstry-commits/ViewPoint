SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/17/09
-- Modified By:	GF 11/16/2011 TK-10080
-- Description:	Unlocks/Locks a batch
-- =============================================
CREATE PROCEDURE [dbo].[vpspPOReceiptBatchUpdate]
	@Key_POCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @LockedYN AS BIT, @VPUserName AS bVPUserName
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--DECLARE @InUseBy AS bVPUserName
	
	--SELECT @InUseBy = InUseBy
	--FROM HQBC (NOLOCK)
	--WHERE Co = @Key_POCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
	
	
	--IF @InUseBy <> @VPUserName
	--BEGIN
	--	RAISERROR('Another user is using this batch. Please reload your list of batches to view the batches you can use.', 16, 1)
	--END
	--ELSE
	--BEGIN
	--	-- This executes if the username matches or nobody is using the batch
		
	--	UPDATE HQBC
	--	SET 
	--		InUseBy = CASE WHEN @LockedYN = 'Yes' THEN @VPUserName ELSE NULL END
	--	WHERE Co = @Key_POCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId
		
	EXEC vpspSetLockOnBatch @Key_POCo, @Key_Mth, @Key_BatchId, @LockedYN, @VPUserName 
		
	EXEC vpspPOReceiptBatchGet @Key_POCo, @VPUserName, @Key_BatchId
	--END
END

GO
GRANT EXECUTE ON  [dbo].[vpspPOReceiptBatchUpdate] TO [VCSPortal]
GO
