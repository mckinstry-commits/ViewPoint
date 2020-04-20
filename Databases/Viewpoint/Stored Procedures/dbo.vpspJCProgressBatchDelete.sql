SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 2/22/10
-- Description:	Deletes a JC Progress Entry batch owned by the VPUserName
-- =============================================
CREATE PROCEDURE [dbo].[vpspJCProgressBatchDelete]
	@Key_JCCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Batch is Open Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_JCCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND [Status] = 0)
	BEGIN
		RAISERROR('Cannot update. Batch is not in the Open status.', 16, 1)
		GOTO vspExit
	END
	
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
		DECLARE @msg varchar(60)
		DECLARE @retcode AS int
		
		EXEC @retcode = bspJCPPBatchDelete @Key_JCCo, @Key_Mth, @Key_BatchId, @msg output
		IF @retcode <> 0
		BEGIN
			RAISERROR(@msg, 16, 1)
		END
			
		EXEC vpspJCProgressBatchGet @Key_JCCo, @VPUserName, @Key_BatchId
	END
	
	vspExit:
END
GO
GRANT EXECUTE ON  [dbo].[vpspJCProgressBatchDelete] TO [VCSPortal]
GO
