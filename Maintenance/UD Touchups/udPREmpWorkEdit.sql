USE Viewpoint
GO

--SELECT * 
--FROM dbo.udPREmpImport
--	JOIN dbo.udPREmpWorkEdit prew ON prew.ImportID = dbo.udPREmpImport.ImportID
--	JOIN dbo.PREH e ON prew.PRCo=e.PRCo AND prew.Employee = e.Employee

--SELECT * FROM dbo.vDDFHc
--WHERE Form = 'udPREmpImport'

UPDATE dbo.vDDFHc
SET JoinClause = 'LEFT JOIN dbo.mvwPREH e ON udPREmpWorkEdit.PRCo=e.V_PRCo AND udPREmpWorkEdit.Employee = e.V_Employee'
WHERE Form = 'udPREmpWorkEdit'



UPDATE dbo.vDDFIc
SET ViewName = 'e'
	, ControlType = 5
	, FieldType = 0
	--, InputType = 0
--SELECT * FROM dbo.vDDFIc
WHERE Form = 'udPREmpWorkEdit'
	AND ColumnName LIKE 'V_%'
	AND Seq NOT IN (7205,7210,7215, 7220)

--REMOVED SECTION AND READDED BELOW

--UPDATE dbo.vDDFIc
--SET FieldType = 4, ControlType=6, ShowGrid ='N',ShowForm='N', StatusText = NULL
--WHERE Form = 'udPREmpWorkEdit'
--	AND ColumnName LIKE 'V_%'
--	AND Seq IN (7205,7210,7215, 7220)


UPDATE dbo.DDFIc
SET Req = 'N'
--SELECT Req, * 
--FROM dbo.DDFIc
WHERE Form = 'udPREmpWorkEdit'
	AND ViewName = 'e'
	AND ColumnName LIKE 'V_%'
	AND Req = 'Y'


UPDATE dbo.DDFIc
SET ShowGrid = 'N', ShowForm = 'N',
	FieldType = 4, ControlType = 6, StatusText = NULL
WHERE Form = 'udPREmpWorkEdit'
	AND Seq IN (7205, 7210, 7215, 7220, 7255, 7270, 7350, 7515, 7365, 7390, 7405, 7450, 7455, 7585, 7680, 7700, 7705, 7710, 7735,7715,7730,5015,7380,7225)