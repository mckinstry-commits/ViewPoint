SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/24/2011
-- Description:	Creates a new GLEntry in the vGLEntry table.
-- =============================================
CREATE PROCEDURE [dbo].[vspGLCreateEntry]
	@Source bSource, @TransactionsShouldBalance bit, @HQBatchDistributionID bigint = NULL, @PRLedgerUpdateMonthID bigint = NULL, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @NextGLEntryID bigint
	
	BEGIN TRAN
		SELECT @NextGLEntryID = ISNULL(MAX(GLEntryID), 0) + 1
		FROM dbo.vGLEntry
		
		BEGIN TRY
			INSERT dbo.vGLEntry (GLEntryID, [Source], TransactionsShouldBalance, HQBatchDistributionID, PRLedgerUpdateMonthID)
			VALUES (@NextGLEntryID, @Source, @TransactionsShouldBalance, @HQBatchDistributionID, @PRLedgerUpdateMonthID)
		END TRY
		BEGIN CATCH
			SET @msg = ERROR_MESSAGE()
			SET @NextGLEntryID = -1
		END CATCH
	COMMIT TRAN
	
	RETURN @NextGLEntryID
END
GO
GRANT EXECUTE ON  [dbo].[vspGLCreateEntry] TO [public]
GO
