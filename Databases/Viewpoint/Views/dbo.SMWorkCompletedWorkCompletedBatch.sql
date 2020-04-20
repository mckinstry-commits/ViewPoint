SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMWorkCompletedWorkCompletedBatch]
AS
	SELECT vSMWorkCompleted.*, vSMWorkCompletedBatch.BatchCo, vSMWorkCompletedBatch.BatchMonth, vSMWorkCompletedBatch.BatchId, vSMWorkCompletedBatch.BatchSeq, vSMWorkCompletedBatch.IsProcessed
	FROM dbo.vSMWorkCompleted
		INNER JOIN dbo.vSMWorkCompletedBatch ON vSMWorkCompleted.SMWorkCompletedID = vSMWorkCompletedBatch.SMWorkCompletedID
GO
GRANT SELECT ON  [dbo].[SMWorkCompletedWorkCompletedBatch] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedWorkCompletedBatch] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedWorkCompletedBatch] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedWorkCompletedBatch] TO [public]
GO
