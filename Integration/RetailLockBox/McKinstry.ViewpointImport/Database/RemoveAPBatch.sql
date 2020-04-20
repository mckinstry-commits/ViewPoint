DECLARE @RLBImportBatchID int
SET @RLBImportBatchID = 1

DECLARE @ProcessTable table
(
	ID int identity(1,1),
	HeaderKeyID bigint NULL,
	FooterKeyID bigint NULL,
	AttachmentID int NULL,
	UniqueAttchID uniqueidentifier
)

INSERT INTO @ProcessTable(HeaderKeyID, FooterKeyID, AttachmentID, UniqueAttchID)
SELECT
Record.HeaderKeyID, Record.FooterKeyID, Record.AttachmentID, Record.UniqueAttchID FROM MCK_INTEGRATION.dbo.RLBAPImportRecord Record
JOIN MCK_INTEGRATION.dbo.RLBAPImportDetail Detail ON
Detail.RLBAPImportDetailID = Record.RLBAPImportDetailID
WHERE Detail.RLBImportBatchID = @RLBImportBatchID

DECLARE @RowCount int, @i int
SET @RowCount = (SELECT COUNT(*) FROM @ProcessTable) 
SET @i = 1

WHILE (@i <= @RowCount)
BEGIN
	-- Variables for process table row items
	DECLARE @HeaderKeyID bigint, @FooterKeyID bigint, @AttachmentID int, @UniqueAttchID uniqueidentifier,
		@UIMth smalldatetime, @APCo tinyint, @UISeq smallint

	-- Fill values from process table row
	SELECT @HeaderKeyID=HeaderKeyID, @FooterKeyID=FooterKeyID, @AttachmentID=AttachmentID, @UniqueAttchID=UniqueAttchID
	FROM @ProcessTable WHERE ID = @i

	-- Fetch APUI details
	SELECT @UIMth=UIMth, @UISeq=UISeq, @APCo=APCo FROM Viewpoint.dbo.APUI WHERE APUI.KeyID=@HeaderKeyID

	-- Delete Footer
	DELETE FROM Viewpoint.dbo.bAPUL WHERE bAPUL.KeyID = @FooterKeyID
	IF EXISTS(SELECT 1 FROM Viewpoint.dbo.APUL APUL WHERE APUL.APCo=@APCo and APUL.UIMth=@UIMth AND APUL.UISeq=@UISeq)
	BEGIN
		DELETE FROM Viewpoint.dbo.bAPUL WHERE bAPUL.APCo=@APCo and bAPUL.UIMth=@UIMth AND bAPUL.UISeq=@UISeq
	END

	-- Delete Header
	DELETE FROM Viewpoint.dbo.bAPUI WHERE bAPUI.KeyID = @HeaderKeyID

	-- Delete Attachment
	IF NOT EXISTS(SELECT 1 FROM Viewpoint.dbo.APUI APUI WHERE APUI.UniqueAttchID = @UniqueAttchID)
	BEGIN
		DELETE FROM Viewpoint.dbo.bHQAT WHERE bHQAT.AttachmentID = @AttachmentID
	END

SET @i = @i  + 1

END