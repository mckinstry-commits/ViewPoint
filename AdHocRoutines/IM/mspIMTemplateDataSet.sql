USE Viewpoint
go

SELECT * FROM IMTH ORDER by ImportTemplate
IF EXISTS (SELECT 1 FROM sysobjects WHERE type='P' AND name='mspIMTemplateDataSet')
BEGIN
	PRINT 'DROP PROCEDURE mspIMTemplateDataSet'
	DROP PROCEDURE mspIMTemplateDataSet
END
GO

PRINT 'CREATE PROCEDURE mspIMTemplateDataSet'
go

CREATE PROCEDURE mspIMTemplateDataSet
(
	@TemplateName	VARCHAR(30)	
)
as

SELECT * FROM IMTH WHERE ImportTemplate=@TemplateName
SELECT * FROM IMTD WHERE ImportTemplate=@TemplateName --and RecColumn IS NOT NULL ORDER BY RecColumn
SELECT * FROM IMTR WHERE ImportTemplate=@TemplateName
--SELECT * FROM dbo.IMTDLookup WHERE ImportTemplate=@TemplateName
SELECT * FROM dbo.IMXH WHERE ImportTemplate=@TemplateName
SELECT * FROM dbo.IMXD WHERE ImportTemplate=@TemplateName
SELECT * FROM dbo.IMXF WHERE ImportTemplate=@TemplateName

go

EXEC mspIMTemplateDataSet @TemplateName='MCKGLJE'
EXEC mspIMTemplateDataSet @TemplateName='MCKEBSTIME'


