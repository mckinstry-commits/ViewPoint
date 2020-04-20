UPDATE dbo.vDDFHc
SET JoinClause ='LEFT JOIN JCJM ON Co=JCCo AND Project=Job
	LEFT JOIN dbo.PREHFullName e ON e.PRCo = udContractAdminLeg.PRCo AND e.Employee = udContractAdminLeg.AssignedTo
	LEFT JOIN dbo.udAuthSigners a ON a.Code=udContractAdminLeg.McKSigner
	LEFT JOIN dbo.udLegalStatus s ON s.Status = udContractAdminLeg.Status
	LEFT JOIN dbo.mvwLegalDocHistoryLatestDates h ON h.Co=udContractAdminLeg.Co AND h.Contract = udContractAdminLeg.Contract AND h.Project = udContractAdminLeg.Project AND h.DocType = udContractAdminLeg.DocType AND h.Seq = udContractAdminLeg.Seq'
WHERE Form='udContractAdminLeg'


UPDATE dbo.DDFIc
SET ViewName='JCJM', ColumnName = 'Description'
, ControlType=5,FieldType = 0 
WHERE Form = 'udContractAdminLeg' AND Seq = 5006

UPDATE dbo.DDFIc
SET ViewName='a', ColumnName = 'Description'
, ControlType=5,FieldType = 0 
WHERE Form = 'udContractAdminLeg' AND Seq = 5035

UPDATE dbo.DDFIc
SET ViewName='s', ColumnName = 'Description'
, ControlType=5,FieldType = 0 
WHERE Form = 'udContractAdminLeg' AND Seq = 5045
 
UPDATE dbo.DDFIc
SET ViewName='e', ColumnName = 'FullName'
, ControlType=5,FieldType = 0 
WHERE Form = 'udContractAdminLeg' AND Seq = 5330

 UPDATE dbo.DDFIc
SET ViewName='h', ColumnName = 'LatestUpdateStatusDATE'
, ControlType=5,FieldType = 0 
WHERE Form = 'udContractAdminLeg' AND Seq = 5050