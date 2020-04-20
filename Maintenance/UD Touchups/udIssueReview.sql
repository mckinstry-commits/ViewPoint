UPDATE dbo.vDDFHc
SET JoinClause='LEFT JOIN mvwLastCommentAll c ON c.Co=udIssueReview.Co AND c.Contract = udIssueReview.Contract AND c.Project = udIssueReview.Project AND c.LegDoc = udIssueReview.DocType AND c.DocSeq = udIssueReview.Seq AND c.LegIss = udIssueReview.Issue
JOIN dbo.udLegalGuide g ON g.Issue = dbo.udIssueReview.Issue'
WHERE Form = 'udIssueReview'


UPDATE dbo.DDFIc
SET ViewName = 'c', ColumnName = 'Date', ControlType=5, FieldType=0
WHERE Form = 'udIssueReview' AND Seq = 5025

UPDATE dbo.DDFIc
SET ViewName = 'g', ColumnName='Guideline', ControlType = 17, FieldType = 4
WHERE Form = 'udIssueReview' AND Seq = 5060