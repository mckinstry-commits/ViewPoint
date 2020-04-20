SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvAPOnCostInvoices]
AS 
    
/***********************************************************************    

Author:		Czeslaw Czapla
   
Created:	06/18/2012

Usage:
For original invoices that have related on-cost invoices, this view 
displays line-level details of the on-cost invoices.

In this view, each on-cost invoice is classified as being one of 
three possible types (or "cases"):

1. The on-cost invoice resides only in AP transaction tables 
(because it has been posted and has not subsequently been brought into 
a new AP entry batch); the view returns NULL values for batch columns,
since the on-cost invoice does not reside in a batch.

2. The on-cost invoice resides only in AP entry batch tables 
(because it has not yet been posted); the view returns NULL values
for transaction identifier columns as an artificial indication
that the on-cost invoice has not been posted.

3. The on-cost invoice resides in both AP transaction tables 
and AP entry batch tables (because it was posted previously and then 
subsequently brought into a new AP entry batch where it now resides);
the view returns non-null values for batch columns and transaction 
identifier columns as an indication that the on-cost invoice occurs 
in both places.

Standard views APTH and APTL contain transaction data for the original 
invoices, as well as transaction data for posted on-cost invoices; 
views APHB and APLB contain batch data for on-cost invoices.

Parameters:
N/A

Related reports: 
AP On-Cost Invoices (Report ID: 1214)

Revision history:   
Date	Author		Issue		Description

***********************************************************************/  

--Case 1: On-cost invoice resides only in AP transaction tables (because posted and not brought into a new batch)
--Identify case: NULL values occur in columns APTH.InUseMth and APTH.InUseBatchId for on-cost invoice
--Use AP transaction tables for original invoice; use AP transaction tables for on-cost invoice

(
SELECT
	'Co_orig'				= APTHorig.APCo,
	'Vendor_orig'			= APTHorig.Vendor,
	'VendName_orig'			= APVMorig.Name,
	'APRef_orig'			= APTHorig.APRef,
	'InvDate_orig'			= APTHorig.InvDate,
	'Mth_orig'				= APTHorig.Mth,
	'APTrans_orig'			= APTHorig.APTrans,
	'PayControl_orig'		= APTHorig.PayControl,
	'InvTotal_orig'			= APTHorig.InvTotal,
	'APLine_orig'			= APTLorig.APLine,
	'Vendor_oncost'			= APTHoncost.Vendor,
	'VendName_oncost'		= APVMoncost.Name,
	'APRef_oncost'			= APTHoncost.APRef,
	'InvDate_oncost'		= APTHoncost.InvDate,
	'Mth_oncost'			= APTHoncost.Mth,
	'APTrans_oncost'		= APTHoncost.APTrans,
	'APLine_oncost'			= APTLoncost.APLine,
	'BatchMth_oncost'		= NULL,
	'BatchId_oncost'		= NULL,
	'BatchAction_oncost'	= NULL,
	'GrossAmt_oncost'		= APTLoncost.GrossAmt,
	'GrossAmt_orig'			= APTLorig.GrossAmt
FROM		APTL APTLorig
INNER JOIN	APTH APTHorig ON APTLorig.APCo=APTHorig.APCo AND APTLorig.Mth=APTHorig.Mth AND APTLorig.APTrans=APTHorig.APTrans
INNER JOIN	APTL APTLoncost ON APTLorig.APCo=APTLoncost.APCo AND APTLorig.Mth=APTLoncost.ocApplyMth AND APTLorig.APTrans=APTLoncost.ocApplyTrans AND APTLorig.APLine=APTLoncost.ocApplyLine
INNER JOIN	APTH APTHoncost ON APTLoncost.APCo=APTHoncost.APCo AND APTLoncost.Mth=APTHoncost.Mth AND APTLoncost.APTrans=APTHoncost.APTrans
INNER JOIN	APVM APVMorig ON APTHorig.VendorGroup=APVMorig.VendorGroup AND APTHorig.Vendor=APVMorig.Vendor
INNER JOIN	APVM APVMoncost ON APTHoncost.VendorGroup=APVMoncost.VendorGroup AND APTHoncost.Vendor=APVMoncost.Vendor
WHERE APTHoncost.InUseMth IS NULL AND APTHoncost.InUseBatchId IS NULL
)

UNION

--Case 2: On-cost invoice resides only in AP entry batch tables (because not yet posted)
--Identify case: NULL value occurs in column APHB.APTrans for on-cost invoice
--Use AP transaction tables for original invoice; use AP entry batch tables for on-cost invoice

(
SELECT
	'Co_orig'				= APTHorig.APCo,
	'Vendor_orig'			= APTHorig.Vendor,
	'VendName_orig'			= APVMorig.Name,
	'APRef_orig'			= APTHorig.APRef,
	'InvDate_orig'			= APTHorig.InvDate,
	'Mth_orig'				= APTHorig.Mth,
	'APTrans_orig'			= APTHorig.APTrans,
	'PayControl_orig'		= APTHorig.PayControl,
	'InvTotal_orig'			= APTHorig.InvTotal,
	'APLine_orig'			= APTLorig.APLine,
	'Vendor_oncost'			= APHBoncost.Vendor,
	'VendName_oncost'		= APVMoncost.Name,
	'APRef_oncost'			= APHBoncost.APRef,
	'InvDate_oncost'		= APHBoncost.InvDate,
	'Mth_oncost'			= NULL,
	'APTrans_oncost'		= NULL,
	'APLine_oncost'			= NULL,
	'BatchMth_oncost'		= APHBoncost.Mth,
	'BatchId_oncost'		= APHBoncost.BatchId,
	'BatchAction_oncost'	= APLBoncost.BatchTransType,
	'GrossAmt_oncost'		= APLBoncost.GrossAmt,
	'GrossAmt_orig'			= APTLorig.GrossAmt
FROM		APTL APTLorig
INNER JOIN	APTH APTHorig ON APTLorig.APCo=APTHorig.APCo AND APTLorig.Mth=APTHorig.Mth AND APTLorig.APTrans=APTHorig.APTrans
INNER JOIN	APLB APLBoncost ON APTLorig.APCo=APLBoncost.Co AND APTLorig.Mth=APLBoncost.ocApplyMth AND APTLorig.APTrans=APLBoncost.ocApplyTrans AND APTLorig.APLine=APLBoncost.ocApplyLine
INNER JOIN	APHB APHBoncost ON APLBoncost.Co=APHBoncost.Co AND APLBoncost.Mth=APHBoncost.Mth AND APLBoncost.BatchId=APHBoncost.BatchId AND APLBoncost.BatchSeq=APHBoncost.BatchSeq
INNER JOIN	APVM APVMorig ON APTHorig.VendorGroup=APVMorig.VendorGroup AND APTHorig.Vendor=APVMorig.Vendor
INNER JOIN	APVM APVMoncost ON APHBoncost.VendorGroup=APVMoncost.VendorGroup AND APHBoncost.Vendor=APVMoncost.Vendor
WHERE APHBoncost.APTrans IS NULL
)

UNION

--Case 3: On-cost invoice resides in both AP transaction tables and AP entry batch tables (because posted previously and then brought again into a new batch)
--Identify case: Non-null value occurs in column APHB.APTrans for on-cost invoice
--Use AP transaction tables for original invoice; use AP entry batch tables for on-cost invoice

(
SELECT
	'Co_orig'				= APTHorig.APCo,
	'Vendor_orig'			= APTHorig.Vendor,
	'VendName_orig'			= APVMorig.Name,
	'APRef_orig'			= APTHorig.APRef,
	'InvDate_orig'			= APTHorig.InvDate,
	'Mth_orig'				= APTHorig.Mth,
	'APTrans_orig'			= APTHorig.APTrans,
	'PayControl_orig'		= APTHorig.PayControl,
	'InvTotal_orig'			= APTHorig.InvTotal,
	'APLine_orig'			= APTLorig.APLine,
	'Vendor_oncost'			= APHBoncost.Vendor,
	'VendName_oncost'		= APVMoncost.Name,
	'APRef_oncost'			= APHBoncost.APRef,
	'InvDate_oncost'		= APHBoncost.InvDate,
	'Mth_oncost'			= APHBoncost.Mth,
	'APTrans_oncost'		= APHBoncost.APTrans,
	'APLine_oncost'			= APLBoncost.APLine,
	'BatchMth_oncost'		= APHBoncost.Mth,
	'BatchId_oncost'		= APHBoncost.BatchId,
	'BatchAction_oncost'	= APLBoncost.BatchTransType,
	'GrossAmt_oncost'		= APLBoncost.GrossAmt,
	'GrossAmt_orig'			= APTLorig.GrossAmt
FROM		APTL APTLorig
INNER JOIN	APTH APTHorig ON APTLorig.APCo=APTHorig.APCo AND APTLorig.Mth=APTHorig.Mth AND APTLorig.APTrans=APTHorig.APTrans
INNER JOIN	APLB APLBoncost ON APTLorig.APCo=APLBoncost.Co AND APTLorig.Mth=APLBoncost.ocApplyMth AND APTLorig.APTrans=APLBoncost.ocApplyTrans AND APTLorig.APLine=APLBoncost.ocApplyLine
INNER JOIN	APHB APHBoncost ON APLBoncost.Co=APHBoncost.Co AND APLBoncost.Mth=APHBoncost.Mth AND APLBoncost.BatchId=APHBoncost.BatchId AND APLBoncost.BatchSeq=APHBoncost.BatchSeq
INNER JOIN	APVM APVMorig ON APTHorig.VendorGroup=APVMorig.VendorGroup AND APTHorig.Vendor=APVMorig.Vendor
INNER JOIN	APVM APVMoncost ON APHBoncost.VendorGroup=APVMoncost.VendorGroup AND APHBoncost.Vendor=APVMoncost.Vendor
WHERE APHBoncost.APTrans IS NOT NULL
)
GO
GRANT SELECT ON  [dbo].[vrvAPOnCostInvoices] TO [public]
GRANT INSERT ON  [dbo].[vrvAPOnCostInvoices] TO [public]
GRANT DELETE ON  [dbo].[vrvAPOnCostInvoices] TO [public]
GRANT UPDATE ON  [dbo].[vrvAPOnCostInvoices] TO [public]
GRANT SELECT ON  [dbo].[vrvAPOnCostInvoices] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvAPOnCostInvoices] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvAPOnCostInvoices] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvAPOnCostInvoices] TO [Viewpoint]
GO
