USE Viewpoint
GO

--SCRIPT TO TURN ALL COMPANY AUDITS ON

--HQCO
UPDATE dbo.HQCO
SET AuditContact='Y'
	
	, AuditMatl = 'Y'
	, AuditTax = 'Y'
WHERE udTESTCo = 'N'
PRINT 'HQCO AUDITS ON'

--UPDATE APCO
UPDATE apc
	SET apc.AuditComp = 'Y'
		, apc.AuditHold = 'Y'
		, apc.AuditPay = 'Y'
		, apc.AuditPayTypes = 'Y'
		, apc.AuditRecur = 'Y'
		, apc.AuditTrans = 'Y'
		, apc.AuditTransHoldCodeYN = 'Y'
		, apc.AuditUnappInv = 'Y'
		, apc.AuditVendors = 'Y'
	FROM APCO apc
		JOIN HQCO hq ON hq.HQCo = apc.APCo
	WHERE hq.udTESTCo='N'
PRINT 'APCO AUDITS ON'
--ARCO
UPDATE ar
	SET ar.AuditCustomers = 'Y'
		, ar.AuditRecType = 'Y'
		, ar.AuditTrans = 'Y'
	FROM ARCO ar
		JOIN dbo.HQCO co ON ar.ARCo = co.HQCo
	WHERE co.udTESTCo = 'N'
PRINT 'ARCO AUDITS ON'
--CMCO
UPDATE cm
	SET cm.AuditAccts = 'Y'
		, cm.AuditDetail ='Y'
	FROM dbo.CMCO cm 
		JOIN HQCO co ON cm.CMCo = co.HQCo
	WHERE co.udTESTCo = 'N'
PRINT 'CMCO AUDITS ON'

--UPDATE Attachment Options
UPDATE dbo.HQAO
SET UseAuditing = 'Y'
PRINT 'Attachment AUDITS ON'

--EM CO
UPDATE e
SET AuditEquipment = 'Y'	
FROM dbo.EMCO e
	JOIN dbo.HQCO h ON e.EMCo = h.HQCo
WHERE h.udTESTCo = 'N'
PRINT 'EMCO AUDITS ON'

--GL Co
UPDATE g
SET AuditAccts = 'Y'
	, AuditAutoJrnl = 'Y'
	, AuditBals = 'Y'
	, AuditBudgets = 'Y'
	, AuditDetail = 'Y'
FROM dbo.GLCO g
	JOIN HQCO h ON g.GLCo = h.HQCo
WHERE h.udTESTCo = 'N'
PRINT 'GLCO AUDITS ON'

--INCO
UPDATE i
SET AuditBoM = 'Y'
	, AuditLoc = 'Y'
	, AuditMatl = 'Y'
	, AuditMOs = 'Y'
FROM dbo.INCO i 
	JOIN HQCO h ON i.INCo = h.HQCo
WHERE h.udTESTCo = 'N'
PRINT 'INCO AUDITS ON'


--JBCO
UPDATE j
SET AuditBills = 'Y', AuditTemplate = 'Y'
FROM dbo.JBCO j
	JOIN HQCO h ON j.JBCo = h.HQCo
WHERE h.udTESTCo = 'N'
PRINT 'JBCO AUDITS ON'

--JCCo
UPDATE jc
SET AuditDepts = 'Y'
	, jc.AuditContracts = 'Y'
	, jc.AuditJobs = 'Y'
	, jc.AuditChngOrders = 'Y'
	, jc.AuditPhases = 'Y'
	, jc.AuditCostTypes = 'Y'
	, jc.AuditPhaseMaster = 'Y'
	, jc.AuditProjectionOverrides = 'Y'
	, jc.AuditLiabilityTemplate = 'Y'
FROM dbo.JCCO jc 
	JOIN HQCO h ON h.HQCo = jc.JCCo
WHERE h.udTESTCo = 'N'
PRINT 'JCCO AUDITS ON'


--PMCO
UPDATE pm
SET AuditDailyLogs='Y'
	, AuditPMCA = 'Y'
	, AuditPMEC = 'Y'
	, AuditPMEH = 'Y'
	, AuditPMFM = 'Y'
	, AuditPMIM = 'Y'
	, AuditPMMF = 'Y'
	, AuditPMNR = 'Y'
	, AuditPMPA = 'Y'
	, AuditPMPC = 'Y'
	, AuditPMPF = 'Y'
	, AuditPMPL = 'Y'
	, AuditPMPM = 'Y'
	, AuditPMPN = 'Y'
	, AuditPMSL = 'Y'
	, AuditPMTH = 'Y'
	, AuditPMMM = 'Y'
FROM PMCO pm 
	JOIN HQCO h ON pm.PMCo = h.HQCo
WHERE h.udTESTCo = 'N'
PRINT 'PMCO AUDITS ON'

--POCO
UPDATE po
SET po.AuditPOCompliance = 'Y'
	, po.AuditPOReceipts = 'Y'
	, po.AuditPOs = 'Y'
	, po.AuditQuote = 'Y'
	, po.AuditReview = 'Y'
	, po.AuditRQ = 'Y'
FROM dbo.POCO po
	JOIN HQCO h ON po.POCo = h.HQCo
WHERE h.HQCo = 1

UPDATE po
SET po.AuditPOCompliance = 'Y'
	, po.AuditPOReceipts = 'Y'
	, po.AuditPOs = 'Y'
	, po.AuditQuote = 'Y'
	, po.AuditReview = 'Y'
	, po.AuditRQ = 'Y'
FROM dbo.POCO po
	JOIN HQCO h ON po.POCo = h.HQCo
WHERE h.HQCo = 20

UPDATE po
SET po.AuditPOCompliance = 'Y'
	, po.AuditPOReceipts = 'Y'
	, po.AuditPOs = 'Y'
	, po.AuditQuote = 'Y'
	, po.AuditReview = 'Y'
	, po.AuditRQ = 'Y'
FROM dbo.POCO po
	JOIN HQCO h ON po.POCo = h.HQCo
WHERE h.HQCo = 60
PRINT 'POCO AUDITS ON'

--PRCO
UPDATE pr
SET AuditAccums = 'Y'
	, AuditCraftClass = 'Y'
	, AuditDLs = 'Y'
	, AuditEmployees = 'Y'
	, AuditPayHistory = 'Y'
	, AuditStateIns = 'Y'
	, AuditTaxes = 'Y'
	, W2AuditYN = 'Y'
FROM dbo.PRCO pr
	JOIN HQCO h ON pr.PRCo = h.HQCo
WHERE udTESTCo = 'N'
PRINT 'PRCO AUDITS ON'

--SLCO
UPDATE sl
SET AuditSLCompliance = 'Y'
	, AuditSLs = 'Y'
FROM dbo.SLCO sl
	JOIN dbo.HQCO h ON sl.SLCo = h.HQCo
WHERE udTESTCo = 'N'
PRINT 'PRCO AUDITS ON'
