SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[mvwRLBARExport]
as
SELECT
	ARTH.ARCo AS Company
,	ARTH.Invoice AS InvoiceNumber
,	ARTH.CustGroup
,	ARTH.Customer 
,	ARCM.Name AS CustomerName
,	ARTH.TransDate AS TransactionDate
--,	ARTL.Mth
--,	ARTL.ARTrans
,	ARTH.Description AS InvoiceDescription
--,	MAX(ARTL.Description) AS MaxLineDesc
,	COUNT(ARTL.KeyID) AS DetailLineCount
,	COALESCE(ARTH.AmountDue,0.00) AS AmountDue
,	COALESCE(SUM(ARTL.Amount),0) AS OriginalAmount
--,	SUM(ARTL.Amount) AS AmountSum
--,	SUM(ARTL.TaxBasis) AS TaxBasisSum
--,	SUM(ARTL.TaxAmount) AS AmountTaxSum
--,	SUM(ARTL.TaxDisc) AS TaxDiscountSum
--,	SUM(ARTL.DiscOffered) AS DiscountOfferedSum
--,	SUM(ARTL.DiscTaken) AS DiscountTakenSum
--,	SUM(ARTL.FinanceChg) AS FinanceChgSum
--,	SUM(ARTL.Retainage) AS RetainageSum
--,	SUM(ARTL.RetgTax) AS RetainageTaxSum
--,	COALESCE(SUM(ARTL.Amount),0) AS Amount
,	COALESCE(SUM(ARTL.TaxAmount),0) AS Tax
--,	COALESCE(SUM(ARTL.Retainage),0) AS Retainage
--,	COALESCE((SUM(ARTL.Amount)-SUM(ARTL.Retainage)),0) AS Total
from 
	dbo.HQCO HQCO  INNER JOIN
	dbo.ARTH ARTH ON
		HQCO.HQCo=ARTH.ARCo LEFT OUTER JOIN 
	dbo.ARTL ARTL ON
		ARTL.ARCo=ARTH.ARCo
		AND ARTL.Mth=ARTH.Mth			 
		AND ARTL.ARTrans=ARTH.ARTrans INNER JOIN 
	dbo.ARCM ARCM ON 
		ARTH.CustGroup=ARCM.CustGroup
	AND ARTH.Customer=ARCM.Customer
WHERE
	ARTH.AmountDue <> 0
--	HQCO.HQCo=101
--	(ARTH.Invoice>=' ' AND ARTH.Invoice<='zzzzzzzzzz')
--AND	ARTH.TransDate>={ts '2013-01-01 00:00:00'} 
GROUP BY
	ARTH.ARCo
,	ARTH.Invoice 
,	ARTH.TransDate 
--,	ARTL.Mth
--,	ARTL.ARTrans
,	ARTH.CustGroup
,	ARTH.Customer 
,	ARCM.Name
,	ARTH.Description 
,	ARTH.AmountDue 
--ORDER BY
--	ARTH.Invoice
GO
