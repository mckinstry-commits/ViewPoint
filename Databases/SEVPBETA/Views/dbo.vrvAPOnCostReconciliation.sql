SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvAPOnCostReconciliation]
AS 
    
/***********************************************************************    

Author:		Czeslaw Czapla
   
Created:	05/29/2012

Usage:
For on-cost invoices in an AP Transaction Entry batch, this view displays
line-level details of the original invoices from which the on-cost invoices
were derived. Standard views APHB and APLB contain batch data for the
on-cost invoices; views APTH and APTL contain transaction data for the
original invoices.

Parameters:  
N/A

Related reports: 
AP On-Cost Reconciliation By Batch (Report ID: 1214)    

Revision history:   
Date	Author		Issue		Description

***********************************************************************/  

SELECT
	'Co_oncost'			= APHB.Co,
	'Mth_oncost'		= APHB.Mth,
	'BatchId_oncost'	= APHB.BatchId,
	'BatchSeq_oncost'	= APHB.BatchSeq,
	'Vendor_oncost'		= APHB.Vendor,
	'APRef_oncost'		= APHB.APRef,
	'VendName_oncost'	= APVM_oncost.Name,
	'InvTotal_oncost'	= APHB.InvTotal,
	'APLine_oncost'		= APLB.APLine,
	'Vendor_orig'		= APTH.Vendor,
	'VendName_orig'		= APVM_orig.Name,
	'APRef_orig'		= APTH.APRef,
	'InvDate_orig'		= APTH.InvDate,
	'Mth_orig'			= APTH.Mth,
	'APTrans_orig'		= APTH.APTrans,
	'APLine_orig'		= APTL.APLine,
	'GrossAmt_orig'		= APTL.GrossAmt,
	'GrossAmt_oncost'	= APLB.GrossAmt
FROM APLB
INNER JOIN APHB ON APLB.Co=APHB.Co AND APLB.Mth=APHB.Mth AND APLB.BatchId=APHB.BatchId AND APLB.BatchSeq=APHB.BatchSeq
INNER JOIN APTL ON APLB.Co=APTL.APCo AND APLB.ocApplyMth=APTL.Mth AND APLB.ocApplyTrans=APTL.APTrans AND APLB.ocApplyLine=APTL.APLine
INNER JOIN APTH ON APTL.APCo=APTH.APCo AND APTL.Mth=APTH.Mth AND APTL.APTrans=APTH.APTrans
INNER JOIN APVM APVM_oncost ON APHB.VendorGroup=APVM_oncost.VendorGroup AND APHB.Vendor=APVM_oncost.Vendor
INNER JOIN APVM APVM_orig ON APTH.VendorGroup=APVM_orig.VendorGroup AND APTH.Vendor=APVM_orig.Vendor
GO
GRANT SELECT ON  [dbo].[vrvAPOnCostReconciliation] TO [public]
GRANT INSERT ON  [dbo].[vrvAPOnCostReconciliation] TO [public]
GRANT DELETE ON  [dbo].[vrvAPOnCostReconciliation] TO [public]
GRANT UPDATE ON  [dbo].[vrvAPOnCostReconciliation] TO [public]
GO
