
UPDATE dbo.vDDFHc
SET JoinClause='JOIN DDUP u ON u.VPUserName = udIssueComments.VPUserName'
WHERE Form = 'udIssueComments'


UPDATE dbo.DDFIc
SET ViewName = 'u', ColumnName = 'FullName', ControlType=5, FieldType=0
WHERE Form = 'udIssueComments' AND Seq = 5031



UPDATE dbo.vDDFHc
SET JoinClause = 'JOIN DDUP u ON u.VPUserName = udLegalComments.VPUserName'
WHERE Form = 'udLegalComments'


UPDATE dbo.DDFIc
SET ViewName = 'u', ColumnName = 'FullName', ControlType=5, FieldType=0
WHERE Form = 'udLegalComments' AND Seq = 5031