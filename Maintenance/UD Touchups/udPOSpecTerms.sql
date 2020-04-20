
--SELECT * FROM dbo.vDDFHc
--WHERE Form = 'udPOSpecTerms'

--SELECT * FROM dbo.vDDFHc
--WHERE Form = 'udSpecTerms'

--SELECT * FROM dbo.DDFIc
--WHERE Form = 'udPOSpecTerms'



--SELECT t.* 
--FROM udPOSpecTerms
--	JOIN dbo.udSpecTerms t ON t.Code = udPOSpecTerms.Code



UPDATE dbo.vDDFHc
SET JoinClause='JOIN dbo.udSpecTerms t ON t.Code = udPOSpecTerms.Code'
WHERE Form = 'udPOSpecTerms'

UPDATE dbo.DDFIc
SET ViewName='t', ColumnName = 'Text', InputType = 0, ControlType=5
WHERE Form = 'udPOSpecTerms' AND Seq = 5010
