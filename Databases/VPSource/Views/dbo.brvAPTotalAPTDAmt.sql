
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   view [dbo].[brvAPTotalAPTDAmt]

AS

/**************************************************************************************

Author:			Nadine F.
Date Created:	03/13/2003

Reports:		AP Open Payables (APOpenPay.rpt)
				AP Open Payables Detail (APOpenPayDetail.rpt)

Purpose:		Used by AP Open Payables reports to display the AP Invoice total amount
				("Gross") from APTD. View returns one line per APCo, Mth, APTrans.

Revision History      
Date		Author	Issue		Description
06/24/2013	Czeslaw	TFS-50405	Prior internationalization enhancements effectively
								repurposed relevant report column from Invoice Total to
								"Gross Plus Tax". Present revision subtracts from that
								"Gross Plus Tax" aggregate sum (APTDTotalAmt) the total
								tax amount from any retainage pay type row in APTD when
								APCompany is set for "Tax basis is net of retainage".								

**************************************************************************************/
    
SELECT
	'APCo'			= APTD.APCo,
	'Mth'			= APTD.Mth,
	'APTrans'		= APTD.APTrans,
	'APTDTotalAmt'	= SUM
						(
							CASE
								WHEN APCO.TaxBasisNetRetgYN = 'Y' THEN
									(
										CASE
											WHEN APTD.PayCategory IS NULL THEN
												(
													CASE WHEN APTD.PayType = APCO.RetPayType THEN (APTD.Amount - APTD.TotTaxAmount) ELSE APTD.Amount END
												)
											ELSE
												(
													CASE WHEN APTD.PayType = APPC.RetPayType THEN (APTD.Amount - APTD.TotTaxAmount) ELSE APTD.Amount END
												)
											END
									)
								ELSE
									APTD.Amount
								END
						)
FROM dbo.APTD APTD
JOIN dbo.APCO APCO ON APCO.APCo = APTD.APCo
LEFT JOIN dbo.APPC APPC ON APPC.APCo = APTD.APCo AND APPC.PayCategory = APTD.PayCategory
GROUP BY APTD.APCo, APTD.Mth, APTD.APTrans
GO

GRANT SELECT ON  [dbo].[brvAPTotalAPTDAmt] TO [public]
GRANT INSERT ON  [dbo].[brvAPTotalAPTDAmt] TO [public]
GRANT DELETE ON  [dbo].[brvAPTotalAPTDAmt] TO [public]
GRANT UPDATE ON  [dbo].[brvAPTotalAPTDAmt] TO [public]
GO
