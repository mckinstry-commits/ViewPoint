/*
2014.12.04 - LWO 
Script to update APUL records with valid Work Order data from PO (e.g. SMCo, WorkOrder, Scope, SMJCCostType

Need to incorporate this into our import routines so that SM based APUL records have valid SM data.

*/
--SELECT * INTO APUL_20141204_BU FROM dbo.APUL

BEGIN TRAN

UPDATE APUL SET
	SMCo=t1.PO_SMCo
,	SMWorkOrder=t1.PO_SMWorkOrder
,	Scope=t1.PO_SMScope
,	SMJCCostType=t1.PO_SMJCCostType
,	SMPhaseGroup=t1.PO_SMPhaseGroup
,	SMPhase=t1.PO_SMPhase
FROM
(
SELECT
	apul.APCo AS APCo
,	apul.KeyID AS KeyId
,	apul.SMCo AS AP_SMCo
,	apul.SMWorkOrder AS AP_SMWorkOrder
,	apul.Scope AS AP_Scope
,	apul.SMCostType as AP_SMCostType
,	apul.SMJCCostType AS AP_SMJCCostType
,	poit.SMCo AS PO_SMCo
,	poit.SMWorkOrder AS PO_SMWorkOrder
,	poit.SMScope AS PO_SMScope
,	poit.SMJCCostType AS PO_SMJCCostType
,	poit.SMPhaseGroup AS PO_SMPhaseGroup
,	poit.SMPhase AS PO_SMPhase
FROM
	APUL apul JOIN
	POIT poit ON
		apul.APCo=poit.POCo
	AND apul.PO=poit.PO
	AND apul.POItem=poit.POItem JOIN
	SMWorkOrderScope smsc ON
		poit.SMCo=smsc.SMCo
	AND poit.SMWorkOrder=smsc.WorkOrder
	AND poit.SMScope=smsc.Scope
WHERE
	apul.APCo <100
AND 
(
	apul.SMCo IS NULL OR apul.SMCo <> poit.SMCo  
OR	apul.SMWorkOrder IS NULL OR apul.SMWorkOrder <> poit.SMWorkOrder
OR	apul.Scope IS NULL OR apul.Scope <> poit.SMScope
OR	apul.SMJCCostType IS NULL OR apul.SMJCCostType <> poit.SMJCCostType
OR	apul.SMPhaseGroup IS NULL OR apul.SMPhaseGroup <> poit.SMPhaseGroup
OR	apul.SMPhase IS NULL OR apul.SMPhase <> poit.SMPhase
)
) t1
WHERE
	APUL.KeyID=t1.KeyId

IF @@ERROR<>0
	ROLLBACK TRAN
ELSE 
	COMMIT TRAN
go



SELECT DISTINCT SMPhaseGroup, SMScope, SMPhase, COUNT(*) FROM POIT WHERE SMWorkOrder IS NOT NULL GROUP BY SMPhaseGroup, SMScope, SMPhase ORDER BY SMPhase--AND Job IS NOT null

SELECT * INTO POIT_20141204_BU FROM POIT

BEGIN tran
UPDATE POIT SET SMPhaseGroup=t1.SM_PhaseGroup, SMPhase=t1.SM_Phase
FROM
(
SELECT
	poit.KeyID
,	poit.SMPhaseGroup
,	poit.SMPhase
,	scope.PhaseGroup AS SM_PhaseGroup
,	scope.Phase AS SM_Phase
FROM 
	dbo.SMWorkOrderScope scope JOIN
	POIT poit ON
		scope.SMCo=poit.SMCo
	AND scope.WorkOrder=poit.SMWorkOrder
	AND scope.Scope=poit.SMScope
WHERE
	ISNULL(poit.SMPhaseGroup,'')<>ISNULL(scope.PhaseGroup,'')
OR	ISNULL(poit.SMPhase,'')<>ISNULL(scope.Phase,'')
) t1
WHERE POIT.KeyID=t1.KeyID

IF @@ERROR<>0
	ROLLBACK TRAN
ELSE 
	COMMIT TRAN
go

--SELECT * FROM APUI


--SELECT SMPhase,SMWorkOrder,* FROM APUL WHERE SMWorkOrder=9001575 --UIMth='11/1/2014' AND UISeq=6
--SELECT SMPhase,SMWorkOrder,* FROM POIT WHERE SMCo=1 AND SMWorkOrder=9001575 AND SMScope=3 
--SELECT Phase,WorkOrder,* FROM dbo.SMWorkOrderScope WHERE SMCo=1 AND WorkOrder=9001575 AND Scope=3

SELECT * FROM APUL WHERE PO='130102697'
SELECT * FROM JCOR WHERE Month='10/1/2014'

SELECT * FROM [dbo].[mvwWIPReport] WHERE Contract='11639-'

sp_helptext [mvwWIPReport]