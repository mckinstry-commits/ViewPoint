SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[mvwRLBAPExport]
as

SELECT 
	'PO' AS RecordType
,	[Company]
,	[PurchaseOrderNumber] AS Number
,	[VendorGroup]
,	[Vendor]
,	[VendorName]
,	[TransactionDate]
,	[JCCo]
,	[Job]
,	[JobDescription]
,	[PurchaseOrderDescription] AS Description
,	[DetailLineCount]
,	[TotalOrigCost]
,	[TotalOrigTax]
,	[RemainingAmount]
,	[RemainingTax]
FROM 
	mvwRLBAPPOExport
UNION
SELECT 
	'SC' AS RecordType
,	[Company]
,	[SubcontractNumber]
,	[VendorGroup]
,	[Vendor]
,	[VendorName]
,	[TransactionDate]
,	[JCCo]
,	[Job]
,	[JobDescription]
,	[SubcontractDescription]
,	[DetailLineCount]
,	[SLOriginalCost]
,	[SLOriginalTax]
,	[Amount]
,	[Tax]
FROM 
	mvwRLBAPSLExport

GO
