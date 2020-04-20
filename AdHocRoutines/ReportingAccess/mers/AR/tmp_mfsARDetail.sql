DECLARE @AgeDate bDate
SET @AgeDate='3/1/2015'

SELECT
	artl.ARCo
,	artl.Mth
,	artl.ARTrans
,	arth.CustGroup
,	arth.Customer
,	arcm.Name AS CustomerName
,	arth.Description AS InvoiceDesc
,	arth.ARTransType
,	artl.RecType
,	isnull(arth.DueDate,arth.TransDate) AS AgeDate
,	DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) AS DaysFromAge
,	isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0)  AS AgeAmount    
,	isnull(artl.Amount,0)-0 AS Amount
,	isnull(artl.Retainage,0)-0 AS Retainage
,	isnull(artl.DiscOffered,0)-0 AS DiscOffered
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) < 30 THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS DueCurrent
,	CASE
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) between 30 and 60 THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS Due30to60
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) between 60 and 90  THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS Due60to90
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) between 90 and 120  THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS Due60to120
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) > 120  THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS Due120Plus
,	artl.ApplyMth
,	artl.ApplyTrans
,	artl.GLCo
,	artl.GLAcct
,	artl.JCCo
,	artl.Contract
,	artl.Item
--,	artl.Job
--,	artl.PhaseGroup
--,	artl.Phase
--,	artl.CostType
,	artl.udSMCo
,	artl.udWorkOrder
FROM 
		HQCO hqco
JOIN ARTL artl ON
	hqco.HQCo=artl.ARCo
AND hqco.udTESTCo <> 'Y'
JOIN ARTH arth ON
	artl.ARCo=arth.ARCo
AND artl.Mth=arth.Mth
AND artl.ARTrans=arth.ARTrans
LEFT OUTER JOIN ARCM arcm ON
	arth.CustGroup=arcm.CustGroup
--AND arth.Customer=arcm.Customer
--WHERE
--	artl.udSMCo IS NOT null
