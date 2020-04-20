USE Viewpoint
go

--UPDATE APUL SET SMPhaseGroup=t1.WOSPhaseGroup, SMPhase=t1.WOSPhase

SELECT 
	'UPDATE APUL SET SMPhaseGroup=' 
+	COALESCE(CAST(wos.PhaseGroup AS VARCHAR(20)),'null')  + ','
+	'SMPhase=' + COALESCE('''' + wos.Phase + '''','null') + ' '
+	'WHERE KeyID=' + CAST(apul.KeyID AS VARCHAR(20))
,	apul.KeyID AS TargetKeyId
,	apul.UIMth
,	apul.UISeq
,	apul.JCCo
,	apul.Job
,	apul.SMCostType
,	apul.SMJCCostType
,	apul.SMPhase
,	apul.SMPhaseGroup
,	wos.JCCo AS WOSJCCo
,	wos.Job AS WOSJob
,	wos.PhaseGroup AS WOSPhaseGroup
,	wos.Phase AS WOSPhase
,	wc.JCCo AS WOWCJCCo
,	wc.PhaseGroup AS WOWCPhaseGroup
,	wc.JCCostType AS WOWCJCCostType
FROM
	APUL apul JOIN
    SMWorkOrderScope wos ON
		apul.SMCo=wos.SMCo
	AND apul.SMWorkOrder=wos.WorkOrder
	AND apul.Scope=wos.Scope JOIN
	SMWorkOrder wo ON
		wos.SMCo=wo.SMCo
	AND wos.WorkOrder=wo.WorkOrder JOIN
	SMServiceSite ss ON
		wo.SMCo=ss.SMCo
	AND wo.ServiceSite=ss.ServiceSite
	AND ss.Type='Job' JOIN
	SMWorkCompleted wc ON
		wo.SMCo=wc.SMCo
	AND wo.WorkOrder=wc.WorkOrder
	AND wc.PO=apul.PO
	AND wc.POItem=apul.POItem
	AND wc.POItemLine=apul.POItemLine
WHERE
	apul.SMPhase is null
--	( apul.SMPhase <> wos.Phase OR apul.SMPhaseGroup <> wos.PhaseGroup )
--AND apul.UIMth=@UIMth
--AND apul.UISeq=@UISeq
--  ORDER BY 
	--apul.UIMth,	apul.UISeq




GO

--UPDATE APUL SET SMPhaseGroup=1, SMPhase='2300-0000-      -' WHERE KeyID=8716

