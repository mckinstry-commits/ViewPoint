DECLARE @RLBImportBatchID int
SET @RLBImportBatchID = 1

DECLARE @ProcessTable table
(
	ID int identity(1,1),
	HeaderKeyID bigint NULL,
	AttachmentID int NULL,
	UniqueAttchID uniqueidentifier
)

INSERT INTO @ProcessTable(HeaderKeyID, AttachmentID, UniqueAttchID)
SELECT
Record.HeaderKeyID, Record.AttachmentID, Record.UniqueAttchID FROM MCK_INTEGRATION.dbo.RLBARImportRecord Record
JOIN MCK_INTEGRATION.dbo.RLBARImportDetail Detail ON
Detail.RLBARImportDetailID = Record.RLBARImportDetailID
WHERE Detail.RLBImportBatchID = @RLBImportBatchID

DECLARE @RowCount int, @i int
SET @RowCount = (SELECT COUNT(*) FROM @ProcessTable) 
SET @i = 1

-- Variables for process table row items
DECLARE @HeaderKeyID bigint, @AttachmentID int, @UniqueAttchID uniqueidentifier,
	@BatchID int, @Co tinyint, @Mth smalldatetime, @BatchKeyID bigint

-- Variables for proc
DECLARE @RC int, @errmsg varchar(60)

IF (@RowCount > 0)
BEGIN
	-- Fill values from process table row
	SELECT @HeaderKeyID=HeaderKeyID FROM @ProcessTable WHERE ID = @i
	-- Fetch ARBH details
	SELECT @BatchID=BatchId, @Co=Co, @Mth=Mth FROM Viewpoint.dbo.ARBH WHERE ARBH.KeyID=@HeaderKeyID
	-- Clear AR Batch (removes ARBH items and sets HQBC batch status to 6)
	EXECUTE @RC = Viewpoint.dbo.bspARBatchClear @Co, @Mth, @BatchID, @errmsg OUTPUT
END

WHILE (@i <= @RowCount)
BEGIN
	-- Fill values from process table row
	SELECT @AttachmentID=AttachmentID, @UniqueAttchID=UniqueAttchID
	FROM @ProcessTable WHERE ID = @i

	-- Delete Attachment
	IF NOT EXISTS(SELECT 1 FROM Viewpoint.dbo.ARBH ARBH WHERE ARBH.UniqueAttchID = @UniqueAttchID)
	BEGIN
		DELETE FROM Viewpoint.dbo.bHQAT WHERE bHQAT.AttachmentID = @AttachmentID
	END

SET @i = @i  + 1

END