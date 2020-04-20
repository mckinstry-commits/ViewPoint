SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMGLPostingMiscDelete]
   /***********************************************************
    * Created:  ECV 03/31/11
    * Modified: 
    *
    *
    * Deletes a batch of GL records created for Work Completed 
    * Miscellaneous records located in the vSMMiscellaneousBatch
    * table.
    *
    * INPUT PARAMETERS
    *   @SMCo           SM Co#
    *   @mth            Posting Month
    *   @BatchId		Batch ID
    *
    * OUTPUT PARAMETERS
    *   @msg            error message if something went wrong
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    *****************************************************/
(@SMCo bCompany, @Mth bMonth, @BatchId int, @msg varchar(255)=NULL OUTPUT)
AS
SET NOCOUNT ON


BEGIN TRANSACTION

BEGIN TRY
	/* Remove InUse Flag from batch */
	DECLARE @rcode int
	
	UPDATE dbo.HQBC SET InUseBy = NULL WHERE Co = @SMCo AND BatchId = @BatchId AND Mth = @Mth AND [Source] = 'SMLedgerUp'
	
	IF EXISTS(SELECT 1 FROM dbo.HQBC Where Co = @SMCo AND BatchId = @BatchId AND Mth = @Mth AND Source = 'SMLedgerUp' AND [Status] < 4)
	BEGIN
		--Capture all the GL Entries to delete before we delete the distribution records
		DECLARE @SMGLEntriesToDelete TABLE (SMGLEntryID bigint)
		
		INSERT @SMGLEntriesToDelete
		SELECT SMGLEntriesToDelete.SMGLEntryID
		FROM dbo.vSMGLDistribution
			CROSS APPLY (
				SELECT SMGLEntryID
				UNION
				SELECT ReversingSMGLEntryID
			) SMGLEntriesToDelete
		WHERE SMCo = @SMCo AND BatchMonth = @Mth AND BatchId = @BatchId AND SMGLEntriesToDelete.SMGLEntryID IS NOT NULL
		
		--Clear GL distributions
		DELETE dbo.vSMGLDistribution
		WHERE SMCo = @SMCo AND BatchMonth = @Mth AND BatchId = @BatchId
		
		--Clear GL Entries
		DELETE dbo.vSMGLEntry
		WHERE SMGLEntryID IN (SELECT SMGLEntryID FROM @SMGLEntriesToDelete)
		
		DELETE dbo.vSMMiscellaneousBatch WHERE Co = @SMCo AND Mth = @Mth AND BatchId = @BatchId
		
		/*Clear records currently being created by job related work orders*/
		EXEC @rcode = dbo.vspSMWorkCompletedBatchClear @BatchCo = @SMCo, @BatchMonth = @Mth, @BatchId = @BatchId, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			ROLLBACK TRAN
			RETURN @rcode
		END

		--The work completed batch records don't get cleared out in vspSMWorkCompletedBatchClear so they need to be deleted here
		DELETE dbo.vSMWorkCompletedBatch
		WHERE BatchCo = @SMCo AND BatchMonth = @Mth AND BatchId = @BatchId

		UPDATE dbo.HQBC SET [Status] = 6 WHERE Co = @SMCo AND BatchId = @BatchId AND Mth = @Mth AND [Source] = 'SMLedgerUp'
	END
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
	SET @msg = 'Batch delete failed: ' + ERROR_MESSAGE()	
	RETURN 1
END CATCH

COMMIT TRANSACTION
SET @msg='The batch has been cancelled.'
RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspSMGLPostingMiscDelete] TO [public]
GO
