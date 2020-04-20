--SELECT * INTO bAPUI_20150123_BU FROM bAPUI 

DECLARE apcur CURSOR for
SELECT
	--apui.APCo,apui.UIMth, apui.UISeq , apui.VendorGroup, apui.Vendor, apui.InvDate, DATEADD(day,ISNULL(hqpt.DaysTillDue,0),apui.InvDate) AS DueDate, apui.PayMethod, apvm.PayTerms, ISNULL(hqpt.DaysTillDue,0) AS TermDays, apui.InvTotal
	apui.APCo,apui.UIMth, apui.UISeq, DATEADD(day,ISNULL(hqpt.DaysTillDue,0),apui.InvDate) AS DueDate, apui.InvTotal
from 
	bAPUI apui LEFT OUTER JOIN 
	bAPVM apvm ON 
		apui.VendorGroup=apvm.VendorGroup
	AND apui.Vendor=apvm.Vendor LEFT OUTER JOIN
	bHQPT hqpt ON
		apvm.PayTerms=hqpt.PayTerms
where 
	apui.APCo IN (1, 20, 60)
AND apui.InUseMth is null and apui.InUseBatchId is NULL
AND apui.DueDate IS NULL
order by 
	apui.UIMth, apui.UISeq
FOR READ ONLY

DECLARE @APCo bCompany
DECLARE @UIMth bMonth
DECLARE @UISeq INT
DECLARE @DueDate bDate
DECLARE @InvTotal bDollar

OPEN apcur
fetch apcur INTO @APCo,@UIMth,@UISeq,@DueDate,@InvTotal

WHILE @@FETCH_STATUS=0
BEGIN
	PRINT 
		CAST(@APCo AS CHAR(10))
	+	CAST(@UIMth AS CHAR(25))
	+	CAST(@UISeq AS CHAR(10))
	+	CAST(@DueDate AS CHAR(25))
	+	CAST(@InvTotal AS CHAR(20))

	UPDATE bAPUI SET DueDate=@DueDate WHERE DueDate IS NULL AND APCo=@APCo AND UIMth=@UIMth AND UISeq=@UISeq


	fetch apcur INTO @APCo,@UIMth,@UISeq,@DueDate,@InvTotal

END

CLOSE apcur
DEALLOCATE apcur
go

