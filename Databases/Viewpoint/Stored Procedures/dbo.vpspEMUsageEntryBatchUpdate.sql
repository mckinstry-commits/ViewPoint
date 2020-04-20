SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tom Jochums
-- Create date: 2/22/10
-- Description:	Unlocks/Locks a EM batch
-- =============================================
CREATE PROCEDURE [dbo].[vpspEMUsageEntryBatchUpdate]
	@Key_EMCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @LockedYN AS BIT, @VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	EXEC vpspSetLockOnBatch @Key_EMCo, @Key_Mth, @Key_BatchId, @LockedYN, @VPUserName 
	Exec vpspEMUsageEntryBatchGet @Key_EMCo, @VPUserName, @Key_BatchId
END

GO
GRANT EXECUTE ON  [dbo].[vpspEMUsageEntryBatchUpdate] TO [VCSPortal]
GO
