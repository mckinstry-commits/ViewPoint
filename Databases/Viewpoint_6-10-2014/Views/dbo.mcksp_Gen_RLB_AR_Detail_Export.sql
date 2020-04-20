SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[mcksp_Gen_RLB_AR_Detail_Export]
as
SELECT
	ARTH.ARCo
,	ARTH.Invoice 
,	ARTH.TransDate 
,	ARTL.Mth
,	ARTL.ARTrans
,	ARTH.Customer 
,	ARCM.Name AS CustomerName
,	ARTH.Description 
,	ARTL.ARLine
,	ARTL.LineType
,	ARTL.RecType
,	ARTL.Description AS LineDesc
,	ARTH.AmountDue 
--,	SUM(ARTL.Amount) AS AmountSum
--,	SUM(ARTL.TaxBasis) AS TaxBasisSum
--,	SUM(ARTL.TaxAmount) AS AmountTaxSum
--,	SUM(ARTL.TaxDisc) AS TaxDiscountSum
--,	SUM(ARTL.DiscOffered) AS DiscountOfferedSum
--,	SUM(ARTL.DiscTaken) AS DiscountTakenSum
--,	SUM(ARTL.FinanceChg) AS FinanceChgSum
--,	SUM(ARTL.Retainage) AS RetainageSum
--,	SUM(ARTL.RetgTax) AS RetainageTaxSum
,	COALESCE(ARTL.Amount,0) AS Amount
,	COALESCE(ARTL.TaxAmount,0) AS Tax
,	COALESCE(ARTL.Retainage,0) AS Retainage
,	COALESCE((ARTL.Amount-ARTL.Retainage),0) AS Total
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
--WHERE
--	HQCO.HQCo=101
--	(ARTH.Invoice>=' ' AND ARTH.Invoice<='zzzzzzzzzz')
--AND	ARTH.TransDate>={ts '2013-01-01 00:00:00'} 
--ORDER BY
--	ARTH.Invoice
GO
GRANT SELECT ON  [dbo].[mcksp_Gen_RLB_AR_Detail_Export] TO [public]
GRANT INSERT ON  [dbo].[mcksp_Gen_RLB_AR_Detail_Export] TO [public]
GRANT DELETE ON  [dbo].[mcksp_Gen_RLB_AR_Detail_Export] TO [public]
GRANT UPDATE ON  [dbo].[mcksp_Gen_RLB_AR_Detail_Export] TO [public]
GO
