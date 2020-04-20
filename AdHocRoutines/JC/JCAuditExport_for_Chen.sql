USE Viewpoint
go

drop PROCEDURE mers.mvwContractAudit_Chen_20150227
go


create PROCEDURE mers.mvwContractAudit_Chen_20150227
as

SET NOCOUNT ON

DECLARE @tmpTbl TABLE
(
	JCCo		bCompany	NOT NULL
,	Contract	bContract	NOT null
)

INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 11071-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10485-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 11072-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10175-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 15997-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10166-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10188-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10168-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10178-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10290-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10155-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10326-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10183-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10177-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 15994-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 13210-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 10430-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (1,' 13149-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20406-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20306-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20355-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20126-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20142-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20405-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20202-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20307-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20535-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20634-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 22937-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20138-')

--2015.03.12 - LWO - Additional Contracts Added per Sarah C.
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20338-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20336-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 22940-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20339-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 20172-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 21160-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,' 21336-')
INSERT @tmpTbl ( JCCo, Contract) VALUES (20,'200156-')


SELECT
	jccm.JCCo
,	jccm.Contract
,	jccm.Description AS ContractDesc
,	jccm.CustomerReference
,	jccm.CustGroup
,	jccm.Customer
,	arcm.Name AS CustomerName
--,	jcci.Item
--,	jcci.Description AS ContractItemDesc
,	jccm.udPOC AS ContractPOC
,	jcmp.Name AS ContractPOCName
,	jccm.StartMonth
,	jccm.StartDate
,	jccm.ProjCloseDate
,	jccm.ActualCloseDate
,	jcdm.Department AS JCDepartment
,	jcdm.Description AS JCDepartmentDesc
,	glpi.Instance AS GLDepartment
,	glpi.Description AS GLDepartmentDesc
,	jccm.OrigContractAmt
,	jccm.ContractAmt - jccm.OrigContractAmt AS ChangeOrderAmt
,	jccm.ContractAmt
,	jccm.BilledAmt
,	jccm.ReceivedAmt
--,	jcci.OrigContractAmt
--,	jcci.ContractAmt
--,	jcci.ContractAmt - jcci.OrigContractAmt AS ChangeOrderAmt
--,	jcci.BilledAmt
--,	jcci.CurrentRetainAmt
FROM 
	HQCO hqco 
JOIN JCCM jccm ON
	hqco.HQCo=jccm.JCCo
AND hqco.udTESTCo<>'Y'
JOIN @tmpTbl tmp ON
	jccm.JCCo=tmp.JCCo
AND jccm.Contract=tmp.Contract
--LEFT OUTER JOIN JCCI jcci ON
--	jccm.JCCo=jcci.JCCo
--AND jccm.Contract=jcci.Contract
JOIN JCDM jcdm ON
	jccm.JCCo=jcdm.JCCo
AND jccm.Department=jcdm.Department
JOIN GLPI glpi ON
	jcdm.GLCo=glpi.GLCo
AND glpi.PartNo=3
AND SUBSTRING(jcdm.OpenRevAcct,10,4)=glpi.Instance
LEFT OUTER JOIN JCMP jcmp ON
	jccm.JCCo=jcmp.JCCo
AND jccm.udPOC=jcmp.ProjectMgr
LEFT OUTER JOIN ARCM arcm ON
	jccm.CustGroup=arcm.CustGroup
AND jccm.Customer=arcm.Customer
ORDER BY
	jccm.JCCo
,	jccm.Contract
go


GRANT EXEC ON mers.mvwContractAudit_Chen_20150227 TO PUBLIC 
GO

mers.mvwContractAudit_Chen_20150227