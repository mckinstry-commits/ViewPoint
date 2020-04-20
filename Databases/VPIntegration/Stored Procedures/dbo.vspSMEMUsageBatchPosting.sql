SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/15/2011
-- Description:	Posting for the EM usage batches created by SM
-- Modified: 4/15/2011 AL - Added logic for deterministic EM posting based on 
--							interface values.
--				2/21/2012 TRL - TK-12747 added code to post Job Cost Distributions to JCCD
--			3/02/2012 TRL - TK- 12858 add new paramter for JC TransType
--			05/25/2012 TRL TK - 15053 removed @JCTransType Parameter for vspSMJobCostDetailInsert 
-- =============================================
CREATE PROCEDURE [dbo].[vspSMEMUsageBatchPosting]
	@SMCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @Source bSource, @TableName varchar(20), @PostDate bDate, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int
	
	--Make sure the batch can be posted and set it as posting in progress.
	EXEC @rcode = dbo.vspHQBatchPosting @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @Source = @Source, @TableName = @TableName, @DatePosted = @PostDate, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	DECLARE @BatchSeq int, @IsReversingEntry bit, @SMWorkCompletedID bigint, @BatchTransType char(1),
		@EMCo bCompany, @OldEMCo bCompany, @EMTrans bTrans,
		@CurrentKeyID bigint,
		@SeqErrMsg varchar(255),
		@PostToEM bYN,
		@GLLvl tinyint,
		@BatchNotes varchar(max)

	SELECT @PostToEM = UseEMInterface, @GLLvl = CASE GLLvl WHEN 'NoUpdate' THEN 0 WHEN 'Summary' THEN 1 WHEN 'Detail' THEN 2 END
	FROM dbo.vSMCO
	WHERE SMCo = @SMCo

	IF @PostToEM = 'Y'
	BEGIN
		DECLARE @BatchRecordsToProcess TABLE (SMWorkCompletedID bigint, BatchSeq int, BatchTransType char(1), EMCo bCompany NULL, OldEMCo bCompany NULL)
		
		INSERT @BatchRecordsToProcess
		SELECT SMWorkCompletedID, BatchSeq, BatchTransType, EMCo, OldEMCo
		FROM dbo.SMEMUsageBatch
		WHERE Co = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId AND IsProcessed = 0
	
		WHILE EXISTS(SELECT 1 FROM @BatchRecordsToProcess)
		BEGIN
			BEGIN TRAN
			SAVE TRAN EMUsageBatchPosting
				SELECT TOP 1 @SMWorkCompletedID = SMWorkCompletedID, @SeqErrMsg = 'Seq# ' + dbo.vfToString(BatchSeq), @BatchTransType = BatchTransType, @EMCo = EMCo, @OldEMCo = OldEMCo
				FROM @BatchRecordsToProcess

				IF @BatchTransType IN ('C','D')
				BEGIN
					/* Remove any existing records in EMRB for this transaction if it is a reversing transation.
						Later we will upadate EMRB from the vSMEMUsageBreakdownDistribution table */
					DELETE bEMRB
					FROM dbo.bEMRB
						INNER JOIN dbo.vSMWorkCompleted ON bEMRB.EMCo = vSMWorkCompleted.CostCo AND bEMRB.Mth = vSMWorkCompleted.CostMth AND bEMRB.Trans = vSMWorkCompleted.CostTrans
					WHERE vSMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID
					
					EXEC @EMTrans = dbo.bspHQTCNextTrans @tablename = 'bEMRD', @co = @OldEMCo, @mth = @BatchMth, @errmsg = @msg OUTPUT

					IF @EMTrans = 0
					BEGIN
						SET @msg = @SeqErrMsg + ' - Unable to update EM Revenue Detail. ' + @msg
						ROLLBACK TRAN EMUsageBatchPosting
						COMMIT TRAN
						RETURN 1
					END
					
					INSERT dbo.bEMRD
						(EMCo, Mth, Trans, BatchID, EMGroup, Equipment, RevCode, [Source], TransType, PostDate, ActualDate,
						GLCo, RevGLAcct, ExpGLCo, ExpGLAcct, Memo,
						Category,
						TimeUM, TimeUnits, UM, WorkUnits, Dollars, RevRate, CustGroup, Customer,
						SMCo, SMWorkOrder, SMScope)
					SELECT
						OldEMCo, @BatchMth, @EMTrans, @BatchId, OldEMGroup, OldEquipment, OldRevCode, 'SM', 'C', @PostDate, OldActualDate,
						OldGLCo, OldGLAcct, OldOffsetGLCo, OldOffsetGLAcct, 'SM Equipment Usage',
						OldCategory,
						OldTimeUM, OldTimeUnits, OldWorkUM, OldWorkUnits, OldDollars, OldRevRate, OldCustGroup, OldCustomer,
						SMCo, WorkOrder, OldScope
					FROM dbo.SMEMUsageBatch
					WHERE SMWorkCompletedID = @SMWorkCompletedID
				END
				
				IF @BatchTransType IN ('A','C')
				BEGIN
					EXEC @EMTrans = dbo.bspHQTCNextTrans @tablename = 'bEMRD', @co = @EMCo, @mth = @BatchMth, @errmsg = @msg OUTPUT

					IF @EMTrans = 0
					BEGIN
						SET @msg = @SeqErrMsg + ' - Unable to update EM Revenue Detail. ' + @msg
						ROLLBACK TRAN EMUsageBatchPosting
						COMMIT TRAN
						RETURN 1
					END
					
					INSERT dbo.bEMRD
						(EMCo, Mth, Trans, BatchID, EMGroup, Equipment, RevCode, [Source], TransType, PostDate, ActualDate,
						GLCo, RevGLAcct, ExpGLCo, ExpGLAcct, Memo,
						Category,
						TimeUM, TimeUnits, UM, WorkUnits, Dollars, RevRate, CustGroup, Customer,
						SMCo, SMWorkOrder, SMScope)
					SELECT
						EMCo, @BatchMth, @EMTrans, @BatchId, EMGroup, Equipment, RevCode, 'SM', 'C', @PostDate, ActualDate,
						GLCo, GLAcct, OffsetGLCo, OffsetGLAcct, 'SM Equipment Usage',
						Category,
						TimeUM, TimeUnits, WorkUM, WorkUnits, Dollars, RevRate, CustGroup, Customer,
						SMCo, WorkOrder, Scope
					FROM dbo.SMEMUsageBatch
					WHERE SMWorkCompletedID = @SMWorkCompletedID
					
					UPDATE dbo.vSMWorkCompleted
					SET CostCo = @EMCo, CostMth = @BatchMth, CostTrans = @EMTrans
					WHERE SMWorkCompletedID = @SMWorkCompletedID
				END
				
				--Capture the trans # so we can later update the work completed with it
				--Also set the record as processed so that it doesn't get reprocessed if posting fails
				UPDATE dbo.vSMWorkCompletedBatch 
				SET IsProcessed = 1
				WHERE SMWorkCompletedID = @SMWorkCompletedID
				
				DELETE @BatchRecordsToProcess WHERE SMWorkCompletedID = @SMWorkCompletedID
			COMMIT TRAN
		END
	END
	ELSE
	BEGIN
		UPDATE dbo.vSMWorkCompletedBatch 
		SET IsProcessed = 1
		WHERE BatchCo = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
	END

	--GL POSTING
	EXEC @rcode = dbo.vspSMGLDistributionPost @SMCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @PostDate = @PostDate, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	IF @PostToEM = 'Y'
	BEGIN 
		DECLARE @SMEMUsageBreakdownDistributionID bigint
		DECLARE @EMUsageBreakDownToProcess TABLE (SMEMUsageBreakdownDistributionID bigint, Trans bTrans)
		
		INSERT @EMUsageBreakDownToProcess
		SELECT vSMEMUsageBreakdownDistribution.SMEMUsageBreakdownDistributionID, SMWorkCompletedWorkCompletedBatch.CostTrans
		FROM dbo.vSMEMUsageBreakdownDistribution
			INNER JOIN dbo.SMWorkCompletedWorkCompletedBatch ON vSMEMUsageBreakdownDistribution.SMCo = SMWorkCompletedWorkCompletedBatch.BatchCo AND vSMEMUsageBreakdownDistribution.Mth = SMWorkCompletedWorkCompletedBatch.BatchMonth AND vSMEMUsageBreakdownDistribution.BatchId = SMWorkCompletedWorkCompletedBatch.BatchId AND vSMEMUsageBreakdownDistribution.BatchSeq = SMWorkCompletedWorkCompletedBatch.BatchSeq
		WHERE vSMEMUsageBreakdownDistribution.SMCo = @SMCo AND vSMEMUsageBreakdownDistribution.Mth = @BatchMth AND vSMEMUsageBreakdownDistribution.BatchId = @BatchId
		
		WHILE EXISTS(SELECT 1 FROM @EMUsageBreakDownToProcess)
		BEGIN
			BEGIN TRAN
			SAVE TRAN EMUsageBreakDownPosting
				SELECT TOP 1 @SMEMUsageBreakdownDistributionID = SMEMUsageBreakdownDistributionID, @EMTrans = Trans
				FROM @EMUsageBreakDownToProcess
				
				INSERT INTO dbo.bEMRB (EMCo, Mth, Trans, EMGroup, RevBdownCode, Equipment, RevCode, Amount)
				SELECT EMCo, Mth, @EMTrans, EMGroup, RevBdownCode, Equipment, RevCode, Total
				FROM dbo.vSMEMUsageBreakdownDistribution
				WHERE SMEMUsageBreakdownDistributionID = @SMEMUsageBreakdownDistributionID
				IF @@rowcount <> 1
				BEGIN
					SET @msg = 'Unable to post distributions from SMEMUsageBreakdownDistribution.'
					ROLLBACK TRAN EMUsageBreakDownPosting
					COMMIT TRAN
					RETURN 1
				END
		
				DELETE dbo.vSMEMUsageBreakdownDistribution WHERE SMEMUsageBreakdownDistributionID = @SMEMUsageBreakdownDistributionID
				IF @@rowcount <> 1
				BEGIN
					SET @msg = 'Unable to remove posted distributions from SMEMUsageBreakdownDistribution.'
					ROLLBACK TRAN EMUsageBreakDownPosting
					COMMIT TRAN
					RETURN 1
				END
					
				DELETE @EMUsageBreakDownToProcess WHERE SMEMUsageBreakdownDistributionID = @SMEMUsageBreakdownDistributionID
			COMMIT TRAN
		END
	END
	ELSE
	BEGIN
		DELETE dbo.vSMEMUsageBreakdownDistribution
		WHERE SMCo = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId
	END

	/*START JOB COST DETAIL RECORD UPDATE*/	
	EXEC @rcode = dbo.vspSMJobCostDetailInsert @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId,  @errmsg = @msg OUTPUT
	IF @rcode <> 0
	BEGIN
		SET @msg = @SeqErrMsg + ' - Unable to update Job Cost Detail. ' + dbo.vfToString(@msg)
		RETURN @rcode
	END
	/*END JOB COST DETAIL RECORD UPDATE*/

	DELETE dbo.vSMWorkCompletedBatch WHERE BatchCo = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
	
	--Update the vSMDetailTransaction records as posted, delete work completed that was marked as deleted and update
	--the cost flags.
	EXEC @rcode = dbo.vspSMWorkCompletedPost @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	SELECT @BatchNotes = 'EM Interface set at: ' + @PostToEM + dbo.vfLineBreak() +
		'GL Revenue Interface Level set at: ' + dbo.vfToString(@GLLvl) + dbo.vfLineBreak()
	
	--Capture notes, set Status to posted and cleanup HQCC records
	EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @Notes = @BatchNotes, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	SET @msg = NULL
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMEMUsageBatchPosting] TO [public]
GO
