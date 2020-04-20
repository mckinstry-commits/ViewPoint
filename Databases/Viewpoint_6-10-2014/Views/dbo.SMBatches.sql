SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMBatches]
AS
SELECT DISTINCT MB.Co, MB.Mth, MB.BatchId,
	CASE WHEN HQBC.Status=0 THEN 'Open'
		WHEN HQBC.Status=4 THEN 'Posting'
		WHEN HQBC.Status=5 THEN 'Posted'
		WHEN HQBC.Status=6 THEN 'Cancelled'
		END Status,
		HQBC.InUseBy, HQBC.CreatedBy, HQBC.DateCreated
	FROM SMMiscellaneousBatch MB
	INNER JOIN HQBC ON MB.Co=HQBC.Co AND MB.Mth=HQBC.Mth AND MB.BatchId=HQBC.BatchId



GO
GRANT SELECT ON  [dbo].[SMBatches] TO [public]
GRANT INSERT ON  [dbo].[SMBatches] TO [public]
GRANT DELETE ON  [dbo].[SMBatches] TO [public]
GRANT UPDATE ON  [dbo].[SMBatches] TO [public]
GRANT SELECT ON  [dbo].[SMBatches] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMBatches] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMBatches] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMBatches] TO [Viewpoint]
GO
