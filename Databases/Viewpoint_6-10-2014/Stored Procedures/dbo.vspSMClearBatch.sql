SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMClearBatch]
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
(@SMCo bCompany, @mth bMonth, @BatchId int, @msg varchar(255)=NULL OUTPUT)
AS
SET NOCOUNT ON

SET @msg=NULL
BEGIN TRANSACTION

BEGIN TRY
	/* Remove InUse Flag from batch */
	DECLARE @CurrentStatus int, @rcode int, @tablename char(20), @inuseby bVPUserName, @BatchSource varchAR(10)

	SELECT @CurrentStatus=Status, @inuseby=InUseBy, @tablename=TableName, @BatchSource=Source 
	FROM dbo.HQBC with (nolock) where Co=@SMCo AND Mth=@mth AND BatchId=@BatchId

	IF @@rowcount=0
   	BEGIN
	   	SELECT @msg='Invalid batch.', @rcode=1
	   	GOTO bspexit
   	END
   
	IF @CurrentStatus=5
   	BEGIN
   		SELECT @msg='Cannot clear, batch has already been posted!', @rcode=1
	   	GOTO bspexit
   	END
   
	IF @CurrentStatus=4
   	BEGIN
   		SELECT @msg='Cannot clear, batch status is posting in progress!', @rcode=1
   		GOTO bspexit
   	END
   	
	IF @inuseby<>SUSER_SNAME()
   	BEGIN
	   	SELECT @msg='Batch is already in use by @inuseby ' + isnull(@inuseby,'') + '!', @rcode=1
	   	GOTO bspexit
   	END

	DELETE dbo.vHQBatchDistribution
	WHERE Co = @SMCo AND Mth = @mth AND BatchId = @BatchId
	    
	DELETE dbo.vHQBatchLine
	WHERE Co = @SMCo AND Mth = @mth AND BatchId = @BatchId

	DELETE dbo.vGLDistribution
	WHERE Co = @SMCo AND Mth = @mth AND BatchId = @BatchId

	DELETE dbo.vGLDistributionInterface
	WHERE Co = @SMCo AND Mth = @mth AND BatchId = @BatchId
	
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
	WHERE SMCo = @SMCo AND BatchMonth = @mth AND BatchId = @BatchId AND SMGLEntriesToDelete.SMGLEntryID IS NOT NULL
		
	--Clear GL distributions
	DELETE dbo.vSMGLDistribution
	WHERE SMCo = @SMCo AND BatchMonth = @mth AND BatchId = @BatchId
		
	--Clear GL Entries
	DELETE dbo.vSMGLEntry
	WHERE SMGLEntryID IN (SELECT SMGLEntryID FROM @SMGLEntriesToDelete)
	
	DELETE dbo.vSMMiscellaneousBatch WHERE Co=@SMCo AND Mth=@mth AND BatchId = @BatchId

	DELETE dbo.vSMAgreementAmrtBatch
	WHERE Co = @SMCo AND Mth = @mth AND BatchId = @BatchId

	UPDATE HQBC Set Status=6 Where Co=@SMCo AND BatchId=@BatchId AND Mth=@mth

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
	SET @msg = 'Batch clear failed: ' + ERROR_MESSAGE()	
	RETURN 1
END CATCH

COMMIT TRANSACTION
SET @msg='The batch has been cancelled.'
   
bspexit:
   
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSMClearBatch] TO [public]
GO
