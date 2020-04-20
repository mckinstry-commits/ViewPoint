USE MCK_INTEGRATION
go

IF EXISTS (SELECT 1 FROM sysobjects WHERE type='V' AND name='mvwRLBMetaImportSummary')
BEGIN
	PRINT 'DROP VIEW mvwRLBMetaImportSummary'
	DROP VIEW mvwRLBMetaImportSummary
END
go

PRINT 'CREATE VIEW mvwRLBMetaImportSummary'
go

CREATE VIEW mvwRLBMetaImportSummary
as
SELECT 
	pvt.MetaFileName
,	COALESCE(pvt.PurchaseOrder,0) AS PurchaseOrder
,	COALESCE(pvt.SubContract,0) AS SubContract
,	COALESCE(pvt.RecurringInvoice,0) AS RecurringInvoice
,	COALESCE(pvt.PurchaseOrder,0)+COALESCE(pvt.SubContract,0)+COALESCE(pvt.RecurringInvoice,0) AS Matched
,	CAST( ( CAST( COALESCE(pvt.PurchaseOrder,0)+COALESCE(pvt.SubContract,0)+COALESCE(pvt.RecurringInvoice,0) as decimal(20,3)) ) / ( CAST(COALESCE(pvt.PurchaseOrder,0)+COALESCE(pvt.SubContract,0)+COALESCE(pvt.RecurringInvoice,0)+COALESCE(pvt.Unmatched,0) AS decimal(20,3)) ) AS decimal(20,3)) AS MatchedPercent
,	COALESCE(pvt.Unmatched,0) AS Unmatched
,	CAST( ( CAST( COALESCE(pvt.Unmatched,0) as decimal(20,3)) ) / ( CAST(COALESCE(pvt.PurchaseOrder,0)+COALESCE(pvt.SubContract,0)+COALESCE(pvt.RecurringInvoice,0)+COALESCE(pvt.Unmatched,0) AS decimal(20,3)) ) AS decimal(20,3)) AS UnmatchedPercent
,	COALESCE(pvt.PurchaseOrder,0)+COALESCE(pvt.SubContract,0)+COALESCE(pvt.RecurringInvoice,0)+COALESCE(pvt.Unmatched,0) AS Total
from
(
SELECT 
	MetaFileName
,	CASE RecordType
		WHEN 'PO' THEN 'PurchaseOrder'
		WHEN 'SC' THEN 'SubContract'
		WHEN 'RI' THEN 'RecurringInvoice'
		ELSE 'Unmatched'
	END AS RecordType
--,	coalesce(RecordType,'Unmatched') AS RecordType
,	COUNT(*)  AS Total
FROM 
	RLB_AP_ImportData
GROUP BY 
	MetaFileName
,	CASE RecordType
		WHEN 'PO' THEN 'PurchaseOrder'
		WHEN 'SC' THEN 'SubContract'
		WHEN 'RI' THEN 'RecurringInvoice'
		ELSE 'Unmatched'
	END
) t1
PIVOT 
(
	sum(Total) FOR RecordType in ([PurchaseOrder],[SubContract],[RecurringInvoice],[Unmatched])
) pvt
GO

SELECT * FROM mvwRLBMetaImportSummary ORDER BY MetaFileName

TRUNCATE TABLE dbo.RLB_AP_ImportData


--SELECT * FROM dbo.RLB_AP_ImportData where ltrim(rtrim(Number)) like '1.07E%'