USE Viewpoint
go

PRINT 'BACKUP APUI Table'
go

SELECT * INTO APUI_20141212_BU FROM APUI
go


PRINT 'DISABLE TRIGGER dbo.btAPUIu ON bAPUI'
go

DISABLE TRIGGER dbo.btAPUIu ON bAPUI
go

PRINT 'Do APUI.UIMth Update'
go

DECLARE apcur CURSOR FOR
SELECT
	KeyID, APCo, UIMth, UISeq, APRef, InvDate, InvTotal, UniqueAttchID
FROM
	APUI 
WHERE 
	UIMth < '11/1/2014'
--AND UIMth = '6/1/2014'
AND APCo < 100
ORDER BY 
	UIMth
,	KeyID
FOR READ ONLY

DECLARE @rcnt		INT
DECLARE @total		decimal(38,2)

DECLARE @itemcnt	INT
DECLARE @attachmentcnt	INT
DECLARE @attachmentindexcnt	INT

DECLARE @totalitemcnt	INT
DECLARE @totalattachmentcnt	int
DECLARE @totalattachmentindexcnt	int

DECLARE @newUIMth	bMonth
DECLARE @newUISeq	int

DECLARE @KeyID		int
DECLARE @APCo		bCompany
DECLARE @UIMth		smalldatetime
DECLARE @UISeq		int
DECLARE @APRef		varchar(30)
DECLARE @InvDate	smalldatetime
DECLARE @InvTotal	decimal(38,2)
DECLARE @UniqueAttchID	UNIQUEIDENTIFIER

select 
	@rcnt=0
,	@total=0
,	@totalitemcnt=0
,	@totalattachmentcnt=0
,	@totalattachmentindexcnt=0

SET @newUIMth='11/1/2014'

PRINT
	CAST('#'	AS CHAR(10))								--int
+	CAST('KeyID'	AS CHAR(10))								--int
+	CAST('APCo'	AS CHAR(10))							--int
+	CAST('UIMth' AS CHAR(15))							--smalldatetime
+	CAST('APRef'	AS CHAR(30))								--varchar(30)
+	CAST('InvDate' AS CHAR(15))		--smalldatetime
+	CAST('InvTotal'	AS CHAR(10))							--decimal(38,2)
+	CAST('itemcnt'	AS CHAR(10))							--int
+	CAST('attcnt'	AS CHAR(10))							--int
+	CAST('attixcnt'	AS CHAR(10))							--int

print REPLICATE('-',150)

OPEN apcur
FETCH apcur INTO
	@KeyID		--int
,	@APCo		--bCompany
,	@UIMth		--smalldatetime
,	@UISeq		--int
,	@APRef		--varchar(30)
,	@InvDate	--smalldatetime
,	@InvTotal	--decimal(38,2)
,	@UniqueAttchID

WHILE @@fetch_status=0
BEGIN
	SELECT @rcnt=@rcnt+1, @total=@total+@InvTotal

	SELECT @itemcnt=COUNT(*) FROM APUL WHERE APCo=@APCo AND UIMth=@UIMth AND UISeq=@UISeq
	SELECT @attachmentcnt=COUNT(*)  FROM HQAT WHERE UniqueAttchID=@UniqueAttchID
	SELECT @attachmentindexcnt=COUNT(*) FROM HQAI WHERE UniqueAttchID=@UniqueAttchID 

	SELECT 
		@totalitemcnt=@totalitemcnt+@itemcnt
	,	@totalattachmentcnt=@totalattachmentcnt+@attachmentcnt
	,	@totalattachmentindexcnt=@totalattachmentindexcnt+@attachmentindexcnt

	PRINT
		CAST(@rcnt	AS CHAR(10))								--int
	+	CAST(@KeyID	AS CHAR(10))								--int
	+	CAST(@APCo	AS CHAR(10))								--int
	+	CAST(convert(VARCHAR(10),@UIMth,112) AS CHAR(15))						--smalldatetime
	+	CAST(@APRef	AS CHAR(30))								--varchar(30)
	+	CAST(convert(VARCHAR(10),@InvDate,112) AS CHAR(15))		--smalldatetime
	+	CAST(@InvTotal	AS CHAR(10))							--decimal(38,2)
	+	CAST(@itemcnt	AS CHAR(10))							--int
	+	CAST(@attachmentcnt	AS CHAR(10))							--int
	+	CAST(@attachmentindexcnt	AS CHAR(10))							--int


	-- THIS IS THE UPDATE THAT WILL NEED TO BE DONE
	IF @itemcnt=0
	BEGIN		
		IF NOT EXISTS ( SELECT 1 FROM APUI WHERE APCo=@APCo AND UIMth=@newUIMth AND UISeq=@UISeq)
		begin
			UPDATE APUI SET UIMth=@newUIMth, Notes=Notes + ' UIMth updated from ' + CONVERT(VARCHAR(10),@UIMth,112) WHERE KeyID=@KeyID
		END
		ELSE
		BEGIN
			SELECT @newUISeq = MAX(UISeq)+1 FROM APUI WHERE APCo=@APCo AND UIMth=@newUIMth
			PRINT 'NEW UISeq: ' + cast(@newUISeq AS CHAR(10)) + ' : ' + cast(@UISeq AS CHAR(10))
			UPDATE APUI SET UIMth=@newUIMth, UISeq=@newUISeq, Notes=Notes + ' UIMth updated from ' + CONVERT(VARCHAR(10),@UIMth,112) WHERE KeyID=@KeyID
		END
	END

	FETCH apcur INTO
		@KeyID		--int
	,	@APCo		--bCompany
	,	@UIMth		--smalldatetime
	,	@UISeq		--int
	,	@APRef		--varchar(30)
	,	@InvDate	--smalldatetime
	,	@InvTotal	--decimal(38,2)
	,	@UniqueAttchID

END

CLOSE apcur
DEALLOCATE apcur

PRINT ''

PRINT CAST(@rcnt AS VARCHAR(10)) + ' Invoices'
PRINT CAST(@totalitemcnt AS VARCHAR(10)) + ' Invoice Items'
PRINT CAST(@totalattachmentcnt AS VARCHAR(10)) + ' Invoice Attachments'
PRINT CAST(@totalattachmentindexcnt AS VARCHAR(10)) + ' Invoice Attachment Indexes'
PRINT CAST(@total AS VARCHAR(10)) + ' Value'
GO

PRINT 'ENABLE TRIGGER dbo.btAPUIu ON bAPUI'
go

ENABLE TRIGGER dbo.btAPUIu ON bAPUI
go