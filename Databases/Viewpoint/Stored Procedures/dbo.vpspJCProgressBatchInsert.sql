SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Chris Gall
-- Create date: 2/22/10
-- Description:	Inserts a new JC Progress Entry batch
-- =============================================
CREATE PROCEDURE [dbo].[vpspJCProgressBatchInsert]
	@Key_JCCo AS bCompany, @Key_Mth AS bMonth, @Key_Job AS bJob,
	@LockedYN AS VARCHAR(3), @ActualDate AS bDate, @VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @batchId AS bBatchID, @errMsg AS VARCHAR(60)
	
	--Set the key month to the first day of the month
	SET @Key_Mth = CAST(DATEPART(yyyy, @Key_Mth) AS VARCHAR) + '-' + CAST(DATEPART(mm, @Key_Mth) AS VARCHAR) + '-01'
	
	EXEC @batchId = bspHQBCInsert @Key_JCCo, @Key_Mth, 'JC Progres', 'JCPP', 'N', 'N', NULL, NULL, @errMsg OUTPUT
	
	-- If the batch id is 0 or less then creating the batch failed
	IF @batchId > 0
	BEGIN		
		DECLARE @msg varchar(255)
		DECLARE @retcode AS int
		DECLARE @PhaseGroup AS bGroup
		
		----TK-00000 use JCCo key value
		select @PhaseGroup = PhaseGroup from dbo.HQCO with (nolock) where HQCo = @Key_JCCo
		
		-- Initalize the phases in the batch
		EXEC @retcode = vspJCProgInitBatch @Key_JCCo, @Key_Mth, @batchId, @Key_Job, @PhaseGroup, @ActualDate, @msg output
		IF @retcode <> 0
		BEGIN
			RAISERROR(@msg, 16, 1)
		END		
		
		-- The created by is set by the username (which is VCSPortal) so we set it to the 
		-- actual user after the record has been inserted
		-- We also set whether the batch is being used right now based on the Locked value
		UPDATE HQBC
		SET 
			CreatedBy = @VPUserName,
			InUseBy = CASE WHEN @LockedYN IN ('Y', 'Yes') THEN @VPUserName ELSE NULL END
		WHERE Co = @Key_JCCo AND Mth = @Key_Mth AND BatchId = @batchId
			
		EXEC vpspJCProgressBatchGet @Key_JCCo, @Key_Job, @VPUserName, @batchId
	END
	ELSE
	BEGIN
		RAISERROR(@errMsg, 16, 1)
	END
	
END
GO
GRANT EXECUTE ON  [dbo].[vpspJCProgressBatchInsert] TO [VCSPortal]
GO
