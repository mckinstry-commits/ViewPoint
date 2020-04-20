
IF EXISTS ( SELECT * FROM sysobjects WHERE name='mvwAPUnnaprovedInvoiceSummary' AND type='V')
BEGIN
	PRINT 'drop VIEW mvwAPUnnaprovedInvoiceSummary'
	drop VIEW mvwAPUnnaprovedInvoiceSummary
END
go

PRINT 'CREATE VIEW mvwAPUnnaprovedInvoiceSummary'
go

CREATE VIEW mvwAPUnnaprovedInvoiceSummary
AS
SELECT 
	apui.APCo
,	apui.UIMth
,	apui.UISeq 
,	apui.APRef
,	apui.InvDate
,	apui.VendorGroup
,	apui.Vendor
,	apvm.Name AS VendorName
,	apul.Line
,	apul.JCCo
,	apul.Job
,	apul.PO
,	apul.POItem
,	apul.POItemLine
,	apul.SL
,	apul.SLItem
,	apur.ApprovalSeq
,	apur.Reviewer
,	hqrv.Name AS ReviewerName
,	apur.DateAssigned
,	apur.DateApproved
,	apur.RejectDate
,	apul.GrossAmt
FROM 
	APUI apui LEFT OUTER JOIN
	APUL apul ON
		apui.APCo=apul.APCo
	AND apui.UIMth=apul.UIMth
	AND apui.UISeq=apul.UISeq LEFT OUTER JOIN
	APUR apur ON
		apul.APCo=apur.APCo
	AND apul.UIMth=apur.UIMth
	AND apul.UISeq=apur.UISeq
	AND apul.Line=apur.Line LEFT OUTER JOIN
	APVM apvm ON
		apui.VendorGroup=apvm.VendorGroup
	AND apui.Vendor=apvm.Vendor LEFT OUTER JOIN
	HQRV hqrv ON
		apur.Reviewer=hqrv.Reviewer
WHERE
	apui.APCo<100

GO

GRANT SELECT ON mvwAPUnnaprovedInvoiceSummary TO PUBLIC
GO

SELECT * FROM mvwAPUnnaprovedInvoiceSummary