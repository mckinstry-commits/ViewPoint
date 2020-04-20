SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/17/2012
-- Description:	Creates a new JCCostEntry in the vJCCostEntry table.
-- =============================================
CREATE PROCEDURE [dbo].[vspJCCostEntryCreate]
	@Source bSource, @PRLedgerUpdateMonthID bigint = NULL, @HQBatchDistributionID bigint = NULL, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @NextJCCostEntryID bigint
	
	BEGIN TRAN
		SELECT @NextJCCostEntryID = ISNULL(MAX(JCCostEntryID), 0) + 1
		FROM dbo.vJCCostEntry
		
		BEGIN TRY
			INSERT dbo.vJCCostEntry (JCCostEntryID, [Source], HQBatchDistributionID, PRLedgerUpdateMonthID)
			VALUES (@NextJCCostEntryID, @Source, @HQBatchDistributionID, @PRLedgerUpdateMonthID)
		END TRY
		BEGIN CATCH
			SET @msg = ERROR_MESSAGE()
			SET @NextJCCostEntryID = 0
		END CATCH
	COMMIT TRAN
	
	RETURN @NextJCCostEntryID
END
GO
GRANT EXECUTE ON  [dbo].[vspJCCostEntryCreate] TO [public]
GO
