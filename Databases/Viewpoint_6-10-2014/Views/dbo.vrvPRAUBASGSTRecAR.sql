SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvPRAUBASGSTRecAR] as

/*******************************************************************
* Created: DML - 16 June 2011 - Issue # 144033, B-04906
* 
* Created for the AR section of the PR BAS GST Reconciliation Report 
*  
********************************************************************/

SELECT Src = 'AR'
, H.ARCo					--ARTH
, H.Mth
, H.ARTransType
, H.Customer
, H.Invoice
, H.TransDate
, H.Source
, L.Amount				--ARTL
, L.TaxAmount
, L.Retainage
, L.ARTrans
, L.ARLine
, L.ApplyMth
, L.ApplyTrans
, L.ApplyLine
, L.RetgTax
, A.GSTTaxAmt		--PRAUEmployerBASAmounts
, A.TaxYear
, A.SalesOrPurchAmt
, A.SalesOrPurchAmtGST
, A.Seq
, C.Item		--PRAUEmployerBASGSTTaxCodes
, C.TaxCode
, C.TaxGroup
, B.GSTStartDate			--PRAUEmployerBAS
, B.GSTEndDate
, C.ItemDesc
FROM   ARTH H 
LEFT OUTER JOIN ARTL L 
	ON H.ARCo=L.ARCo 
		AND H.Mth=L.Mth 
		AND H.ARTrans=L.ARTrans 
INNER JOIN PRAUEmployerBASGSTTaxCodes C 
	ON L.ARCo=C.PRCo 
		AND L.TaxCode=C.TaxCode 
		AND L.TaxGroup=C.TaxGroup 
LEFT OUTER JOIN PRAUEmployerBASAmounts A
	ON C.PRCo=A.PRCo 
		AND C.TaxYear=A.TaxYear 
		AND C.Seq=A.Seq 
		AND C.Item=A.Item 
RIGHT OUTER JOIN PRAUEmployerBAS B 
	ON A.PRCo=B.PRCo 
		AND A.TaxYear=B.TaxYear 
		AND A.Seq=B.Seq
Left outer join ARCO O on H.ARCo = O.ARCo

WHERE  H.ARTransType<>'P' 
AND B.GSTStartDate<=H.Mth 
AND B.GSTEndDate>=H.Mth 
AND C.Item in ('G1', 'G2', 'G3')
--and B.PRCo = 213
--and B.TaxYear = 2011
--and B.Seq = 1

UNION

SELECT distinct Src = 'CM'
, CM.CMCo					
, CM.Mth
, 'Z' as ARTransType
, Null as Customer
, Null as Invoice
, CM.ActDate as TransDate
, Source
, CM.Amount				
, Null as TaxAmount
, Null as Retainage
, CM.CMTrans
, Null as ARLine
, Null as ApplyMth
, Null as ApplyTrans
, Null as ApplyLine
, Null as RetgTax
, A.GSTTaxAmt		--PRAUEmployerBASAmounts				
, B.TaxYear
, A.SalesOrPurchAmt
, A.SalesOrPurchAmtGST
, B.Seq
, C.Item					--PRAUEmployerBASGSTTaxCodes
, C.TaxCode
, C.TaxGroup
, B.GSTStartDate			--PRAUEmployerBAS
, B.GSTEndDate
, Null as ItemDesc
FROM   CMDT CM

LEFT OUTER  JOIN PRAUEmployerBASGSTTaxCodes C 
	on CM.CMCo=C.PRCo
		and CM.TaxCode=C.TaxCode
		and CM.TaxGroup=C.TaxGroup
LEFT OUTER JOIN PRAUEmployerBASAmounts A
	ON C.PRCo=A.PRCo 
		AND C.TaxYear=A.TaxYear 
		AND C.Seq=A.Seq 
		AND C.Item=A.Item 
inner join PRAUEmployerBAS B
	on CM.CMCo=B.PRCo
		and C.PRCo=B.PRCo		--rem
		and C.TaxYear=B.TaxYear  -- rem
		and C.Seq=B.Seq			--rem

WHERE  C.Item in ('G1','G2','G3')
and CM.Mth >= B.GSTStartDate
and CM.Mth <= B.GSTEndDate
--and B.PRCo = 213
--and B.TaxYear = 2011
--and B.Seq = 1




GO
GRANT SELECT ON  [dbo].[vrvPRAUBASGSTRecAR] TO [public]
GRANT INSERT ON  [dbo].[vrvPRAUBASGSTRecAR] TO [public]
GRANT DELETE ON  [dbo].[vrvPRAUBASGSTRecAR] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRAUBASGSTRecAR] TO [public]
GRANT SELECT ON  [dbo].[vrvPRAUBASGSTRecAR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRAUBASGSTRecAR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRAUBASGSTRecAR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRAUBASGSTRecAR] TO [Viewpoint]
GO
