SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/17/09
-- Description:	Inserts a new batch
-- =============================================
CREATE PROCEDURE [dbo].[vpspPOReceiptBatchInsert]
	@Key_POCo AS bCompany, @Key_Mth AS bMonth, @LockedYN AS BIT, @VPUserName AS bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @batchId AS bBatchID, @errMsg AS VARCHAR(60)
	
	--Set the key month to the first day of the month
	SET @Key_Mth = CAST(DATEPART(yyyy, @Key_Mth) AS VARCHAR) + '-' + CAST(DATEPART(mm, @Key_Mth) AS VARCHAR) + '-01'
	
	EXEC @batchId = bspHQBCInsert @Key_POCo, @Key_Mth, 'PO Receipt', 'PORB', 'N', 'N', NULL, NULL, @errMsg OUTPUT
	
	-- If the batch id is 0 or less then creating the batch failed
	IF @batchId > 0
	BEGIN
		-- The created by is set by the susername (which is VCSPortal) so we set it to the 
		-- actual user after the record has been inserted
		-- We also set whether the batch is being used right now based on the Locked value
		UPDATE HQBC
		SET 
			CreatedBy = @VPUserName,
			InUseBy = CASE WHEN @LockedYN = 1 THEN @VPUserName ELSE NULL END
		WHERE Co = @Key_POCo AND Mth = @Key_Mth AND BatchId = @batchId

		EXEC vpspPOReceiptBatchGet @Key_POCo, @VPUserName, @batchId
	END
	ELSE
	BEGIN
		RAISERROR(@errMsg, 16, 1)
	END
	
END

GO
GRANT EXECUTE ON  [dbo].[vpspPOReceiptBatchInsert] TO [VCSPortal]
GO
