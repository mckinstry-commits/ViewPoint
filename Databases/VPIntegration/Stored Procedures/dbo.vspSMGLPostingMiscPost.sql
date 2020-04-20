SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMGLPostingMiscPost]
   /***********************************************************
    * Created:  ECV 03/30/11
    * Modified: TRL TK-13744 04/04/12 add to post recordds into JCCD from SMJobCostDistribution for SM Work Orders with Jobs
    *				05/25/2012 TRL TK - 15053 removed @JCTransType Parameter for vspSMJobCostDetailInsert
    *
    * Post a batch of GL records for Work Completed 
    * Miscellaneous records located in the vSMMiscellaneousBatch
    * table.
    *
    * GL Interface Levels:
    *	0      No update
    *	1      Summarize entries by GLCo#/GL Account
    *   2      Full detail
    *
    * INPUT PARAMETERS
    *   @co           SM Co#
    *   @mth            Posting Month
    *   @batchid		Batch ID
    *   @postdate		Batch Post Date
    *
    * OUTPUT PARAMETERS
    *   @msg            error message if something went wrong
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    *****************************************************/
(@co bCompany, @mth bMonth, @batchid int, @postdate bDate, @msg varchar(255)=NULL OUTPUT)
AS
SET NOCOUNT ON

	DECLARE @rcode int,
		@GLLvl tinyint,
		@BatchNotes varchar(max)

	SET @postdate = DATEADD(dd,0, DATEDIFF(dd,0, @postdate))

	-- Validate HQ Batch
	EXEC @rcode = dbo.vspHQBatchPosting @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Source = 'SMLedgerUpdate', @TableName = 'SMMiscellaneousBatch', @DatePosted = @postdate, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	--- update batch status as 'posting in progress'
	UPDATE dbo.bHQBC
	SET [Status] = 4, DatePosted = @postdate
	WHERE Co = @co and Mth = @mth and BatchId = @batchid
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Unable to update HQ Batch Control information!'
		GOTO ErrorFound
	END
	
	SELECT @GLLvl = CASE GLLvl WHEN 'NoUpdate' THEN 0 WHEN 'Summary' THEN 1 WHEN 'Detail' THEN 2 END
	FROM dbo.vSMCO
	WHERE SMCo = @co

	--GL POSTING
	EXEC @rcode = dbo.vspSMGLDistributionPost @SMCo = @co, @BatchMth = @mth, @BatchId = @batchid, @PostDate = @postdate, @msg = @msg OUTPUT
	IF @rcode <> 0 GOTO ErrorFound

	EXEC @rcode = dbo.vspSMGLPostingMiscDelete @SMCo = @co, @Mth = @mth, @BatchId = @batchid, @msg = @msg OUTPUT
	IF @rcode <> 0 GOTO ErrorFound
	
	/*START JOB COST DETAIL RECORD UPDATE*/	
	EXEC @rcode = dbo.vspSMJobCostDetailInsert @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @errmsg = @msg OUTPUT
	IF @rcode <> 0 GOTO ErrorFound
	/*END JOB COST DETAIL RECORD UPDATE*/	

	/* Delete Batch Records */
	DELETE dbo.vSMMiscellaneousBatch
	WHERE Co = @co AND Mth = @mth AND BatchId = @batchid

	--Update the vSMDetailTransaction records as posted, delete work completed that was marked as deleted and update
	--the cost flags.
	EXEC @rcode = dbo.vspSMWorkCompletedPost @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	SELECT @BatchNotes = 'GL Revenue Interface Level set at: ' + dbo.vfToString(@GLLvl) + CHAR(13) + CHAR(10)
	
	--Capture notes, set Status to posted and cleanup HQCC records
	EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Notes = @BatchNotes, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	RETURN 0
ErrorFound:
	RETURN 1

GO
GRANT EXECUTE ON  [dbo].[vspSMGLPostingMiscPost] TO [public]
GO
