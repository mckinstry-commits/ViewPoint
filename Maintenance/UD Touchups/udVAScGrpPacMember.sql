

--SELECT * FROM dbo.DDFIc
--WHERE Form LIKE 'udVA%'
--SELECT * FROM dbo.vDDFHc
--WHERE Form LIKE 'udVA%'


--SELECT * 
--FROM udVAScGrpPacMember 
--	JOIN dbo.DDSG sg ON sg.SecurityGroup = udVAScGrpPacMember.SecGroup
	
	
	

UPDATE dbo.vDDFHc
SET JoinClause = 'JOIN dbo.DDSG sg ON sg.SecurityGroup = udVAScGrpPacMember.SecGroup'
WHERE Form ='udVAScGrpPacMember'

UPDATE dbo.DDFIc
SET ViewName = 'sg', ColumnName='Name', ControlType=5, FieldType=0
WHERE Form = 'udVAScGrpPacMember' AND Seq = 5030

UPDATE dbo.DDFIc
SET ViewName = 'sg', ColumnName='Description', ControlType=5, FieldType=0
WHERE Form = 'udVAScGrpPacMember' AND Seq = 5035