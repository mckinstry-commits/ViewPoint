SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvAPEFTRemReprint]
AS

/***********************************************************************

Author:		DML

Created:	06/09/2009

Related reports:
AP EFT Remittance Reprint (Report ID: 1023)
AP Credit Service Remittance Reprint (Report ID: XXXX)

Usage:
This view displays information for EFT payments and Credit Service payments;
both unposted and posted payments are included. Standard views APPB and APTB
are used for unposted payment data; views APPH and APPD are used for posted
payment data.

An unposted EFT or Credit Service payment is defined as a payment that resides
in the payment batch tables (APPB; APTB), and not in the payment history tables
(APPH; APPD); additionally, the payment must already have been assigned values
for PaidDate and CMRef, indicating that a download file has been initialized
for the payment. Prior to assignment of these values, the EFT or Credit Service
payment is not ready for meaningful reporting.

A posted EFT or Credit Service payment is defined as a payment that resides in
the history tables, and not in the batch tables; such a payment will always have
values for PaidDate and CMRef.

At any given time, a given payment will reside in either the batch tables or the 
history tables, but not both.

For an unposted payment row, the view artificially assigns value NULL to 
columns EFTSeq and CMRefSeq. In the case of report AP EFT Remittance Reprint,
this effectively allows the report to sort on BatchSeq instead of EFTSeq
for unposted payments; for unposted payments, under the "Seq" column heading 
the report displays BatchSeq values. In the case of report AP Credit Service
Remittance Reprint, this null value assignment allows the report to sort on 
BatchSeq instead of CMRefSeq for unposted payments; for unposted payments, 
under the "Seq" column heading the report likewise displays BatchSeq values.

For a posted payment row, either EFT or Credit Service, the view assigns value NULL
to column BatchSeq; this is necessary, given that column BatchSeq does not exist
in the history tables. In the case of report AP EFT Remittance Reprint,
for posted payments the report sorts on EFTSeq, and under the "Seq" column heading
displays EFTSeq values. In the case of report AP Credit Service Remittance Reprint,
for posted payments the report sorts on CMRefSeq, and under the "Seq" column heading
displays CMRefSeq values.

Parameters:
N/A

Revision history:
Date		Author		Issue			Description
10/26/2011	DML			144210 (CL)		Added column CMCo
06/07/2012	Czeslaw		D-05257 (V1)	Removed conditional logic from selected
	columns 'P-UN' because moot (always resolved to same value);
	conflated selected columns APPB.PrevDisc and APPD.PrevDiscTaken to a single
	column because equivalent, correcting defective calculations in report;
	added value 'S' (Credit Service) to PayMethod selection criterion so view
	can serve new Credit Service report; removed WITH(NOLOCK), per current practice; 
	in second Select statement, added previously-missing join criteria (in ON clause)
	necessary for data integrity; in first Select statement, added three selection
	criteria previously located unnecessarily in Crystal file; reformatted query,
	aliasing all columns consistently.

***********************************************************************/

--Unposted payments (in batch tables)
(
SELECT 
	'SRC'			= 'PB-TB', --PAYMENT BATCH HEADER and TRANS DETAILS
	'Co'			= APPB.Co,
	'BatchSeq'		= APPB.BatchSeq,
	'PayMethod'		= APPB.PayMethod,
	'CMRef'			= APPB.CMRef,
	'CMAcct'		= APPB.CMAcct,
	'CMCo'			= APPB.CMCo,
	'Vendor'		= APPB.Vendor,
	'Name'			= APPB.Name,
	'Address'		= APPB.Address,
	'City'			= APPB.City,
	'State'			= APPB.State,
	'Zip'			= APPB.Zip,
	'PaidDate'		= APPB.PaidDate,
	'Supplier'		= APPB.Supplier,
	'VoidYN'		= APPB.VoidYN,
	'AddnlInfo'		= APPB.AddnlInfo,
	'Country'		= APPB.Country,
	'APTrans'		= APTB.APTrans,
	'APRef'			= APTB.APRef,
	'Description'	= APTB.Description,
	'InvDate'		= APTB.InvDate,
	'Gross'			= APTB.Gross,
	'Retainage'		= APTB.Retainage,
	'PrevPaid'		= APTB.PrevPaid,
	'PrevDisc'		= APTB.PrevDisc,
	'Balance'		= APTB.Balance,
	'DiscTaken'		= APTB.DiscTaken,
	'EFTSeq'		= NULL,
	'CMRefSeq'		= NULL,
	'ExpMth'		= APTB.ExpMth,
	'BatchId'		= APPB.BatchId,
	'VendorGroup'	= APPB.VendorGroup,
	'Mth'			= APPB.Mth,
	'P-UN'			= 'Unposted'
FROM APPB
INNER JOIN APTB ON APPB.Co=APTB.Co AND APPB.Mth=APTB.Mth AND APPB.BatchId=APTB.BatchId AND APPB.BatchSeq=APTB.BatchSeq
WHERE APPB.PayMethod IN ('E','S')
AND APPB.PaidDate IS NOT NULL
AND APPB.CMRef IS NOT NULL
AND APPB.CMRef <> ''
)

UNION ALL

--Posted payments (in history tables)
(
SELECT 
	'SRC'			= 'PH-PD', -- PAYMENT HEADER and DETAILS
	'Co'			= APPH.APCo,
	'BatchSeq'		= NULL,
	'PayMethod'		= APPH.PayMethod,
	'CMRef'			= APPH.CMRef,
	'CMAcct'		= APPH.CMAcct,
	'CMCo'			= APPH.CMCo,
	'Vendor'		= APPH.Vendor,
	'Name'			= APPH.Name,
	'Address'		= APPH.Address,
	'City'			= APPH.City,
	'State'			= APPH.State,
	'Zip'			= APPH.Zip,
	'PaidDate'		= APPH.PaidDate,
	'Supplier'		= APPH.Supplier,
	'VoidYN'		= APPH.VoidYN,
	'AddnlInfo'		= APPH.AddnlInfo,
	'Country'		= APPH.Country,
	'APTrans'		= APPD.APTrans,
	'APRef'			= APPD.APRef,
	'Description'	= APPD.Description,
	'InvDate'		= APPD.InvDate,
	'Gross'			= APPD.Gross,
	'Retainage'		= APPD.Retainage,
	'PrevPaid'		= APPD.PrevPaid,
	'PrevDisc'		= APPD.PrevDiscTaken,
	'Balance'		= APPD.Balance,
	'DiscTaken'		= APPD.DiscTaken,
	'EFTSeq'		= APPH.EFTSeq,
	'CMRefSeq'		= APPH.CMRefSeq,
	'ExpMth'		= APPD.Mth,
	'BatchId'		= APPH.BatchId,
	'VendorGroup'	= APPH.VendorGroup,
	'Mth'			= APPH.PaidMth,
	'P-UN'			= 'Posted'
FROM APPH
INNER JOIN APPD ON APPH.APCo=APPD.APCo AND APPH.CMCo=APPD.CMCo AND APPH.CMAcct=APPD.CMAcct AND APPH.PayMethod=APPD.PayMethod AND APPH.CMRef=APPD.CMRef AND APPH.CMRefSeq=APPD.CMRefSeq AND APPH.EFTSeq=APPD.EFTSeq
WHERE APPH.PayMethod IN ('E','S')
)
GO
GRANT SELECT ON  [dbo].[vrvAPEFTRemReprint] TO [public]
GRANT INSERT ON  [dbo].[vrvAPEFTRemReprint] TO [public]
GRANT DELETE ON  [dbo].[vrvAPEFTRemReprint] TO [public]
GRANT UPDATE ON  [dbo].[vrvAPEFTRemReprint] TO [public]
GRANT SELECT ON  [dbo].[vrvAPEFTRemReprint] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvAPEFTRemReprint] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvAPEFTRemReprint] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvAPEFTRemReprint] TO [Viewpoint]
GO
