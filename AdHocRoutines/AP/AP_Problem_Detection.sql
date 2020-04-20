--SELECT 
--	apul.UIMth, apul.UISeq, apul.GLCo, apul.GLAcct, poit.GLCo, poit.GLAcct
--FROM 
--	APUL apul
--JOIN POIT poit ON
--	apul.APCo
--AND	apul.PO=poit.PO
--AND apul.POItem=poit.POItem
--WHERE
--	apul.APCo < 100
--AND	apul.GLAcct IS NULL


--SELECT * FROM APUL WHERE UISeq=2236

--SELECT * FROM APUI WHERE dbo.APCo <100 
--SELECT * FROM APUL WHERE APCo<100 AND GLAcct IS NULL ORDER BY APCo, UIMth, UISeq



SELECT
	apui.APCo
,	apui.UIMth
,	apui.UISeq
,	apui.InUseBatchId
,	apul.Line
,	apur.Reviewer
,	apur.DateApproved
,	apul.LineType
,	CASE apul.LineType
		WHEN 1 THEN 'Job'
		WHEN 2 THEN 'Inv'
		WHEN 3 THEN 'Exp'
		WHEN 4 THEN 'Equipment'
		WHEN 5 THEN 'Equipment WO'
		WHEN 6 THEN 'PO'
		WHEN 7 THEN 'Subcontract'
		WHEN 8 THEN 'SM WO'
		ELSE CAST(apul.LineType AS VARCHAR(20))
	END AS LineTypeDesc		
,	apul.ItemType
,	CASE 
		WHEN apul.LineType=6 AND apul.ItemType=1 THEN 'Job'
		WHEN apul.LineType=6 AND apul.ItemType=2 THEN 'Inventory'
		WHEN apul.LineType=6 AND apul.ItemType=3 THEN 'Expense'
		WHEN apul.LineType=6 AND apul.ItemType=4 THEN 'Equipment'
		WHEN apul.LineType=6 AND apul.ItemType=5 THEN 'Equipment WO'
		WHEN apul.LineType=6 AND apul.ItemType=6 THEN 'SM WO'
		ELSE coalesce(CAST(apul.ItemType AS VARCHAR(20)),null)
	END AS ItemTypeDesc
,	apul.GLCo
,	apul.GLAcct
,	apul.PO
,	apul.POItem
,	apul.POItemLine
,	apul.JCCo
,	apul.Job
,	apul.PhaseGroup
,	apul.Phase
,	apul.JCCType
,	apul.SL
,	apul.SLItem
,	apul.SMCo
,	apul.SMWorkOrder
,	apul.Scope
,	apul.SMCostType
,	apul.SMPhaseGroup
,	apul.SMPhase
,	apul.SMJCCostType
FROM 
	APUI apui
JOIN APUL apul ON
	apui.APCo=apul.APCo	    
AND apui.UIMth=apul.UIMth
AND apui.UISeq=apul.UISeq
JOIN APUR apur ON
	apul.APCo=apur.APCo
AND apul.UIMth=apur.UIMth
AND apul.UISeq=apur.UISeq
AND apul.Line=apur.Line
WHERE
	apui.APCo < 100
AND apui.InUseBatchId IS NULL
and apur.DateApproved IS null
--AND	apul.LineType=6
--AND apul.ItemType=1
ORDER BY
	apui.APCo
,	apui.UIMth
,	apui.UISeq
,	apul.Line	



