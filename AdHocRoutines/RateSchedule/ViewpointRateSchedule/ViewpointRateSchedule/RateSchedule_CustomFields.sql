

IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bJCRD' AND COLUMN_NAME = 'udStandardRate')
begin
	--ALTER TABLE [dbo].[bJCRD] DROP CONSTRAINT [DF_bJCRD_udStandardRate]
	ALTER TABLE [dbo].[bJCRD] DROP COLUMN [udStandardRate]
end 
go

IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bJCRD' AND COLUMN_NAME = 'udOldStandardRate')
begin
	--ALTER TABLE [dbo].[bJCRD] DROP CONSTRAINT [DF_bJCRD_udOldStandardRate]
	ALTER TABLE [dbo].[bJCRD] DROP COLUMN [udOldStandardRate]
end 
go

IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bJCRD' AND COLUMN_NAME = 'udBurdenPercent')
begin
	ALTER TABLE [dbo].[bJCRD] DROP CONSTRAINT [DF_bJCRD_udBurdenPercent]
	ALTER TABLE [dbo].[bJCRD] DROP COLUMN [udBurdenPercent]
end 
go

IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bJCRD' AND COLUMN_NAME = 'udOldBurdenPercent')
begin
	ALTER TABLE [dbo].[bJCRD] DROP CONSTRAINT [DF_bJCRD_udOldBurdenPercent]
	ALTER TABLE [dbo].[bJCRD] DROP COLUMN [udOldBurdenPercent]
end 
go



--Add Custom Columns to datbase table
IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bJCRD' AND COLUMN_NAME = 'udBurdenPercent')
BEGIN
	ALTER TABLE [dbo].[bJCRD] ADD [udBurdenPercent] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bJCRD_udBurdenPercent]  DEFAULT (0.00)
END
GO

 
IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bJCRD' AND COLUMN_NAME = 'udOldBurdenPercent')
BEGIN
	ALTER TABLE [dbo].[bJCRD] ADD [udOldBurdenPercent] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bJCRD_udOldBurdenPercent]  DEFAULT (0.00)
END
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bJCRD' AND COLUMN_NAME = 'udStandardRate')
BEGIN
	ALTER TABLE [dbo].[bJCRD] ADD [udStandardRate] AS ( NewRate/(1+udBurdenPercent)) --NOT NULL CONSTRAINT [DF_bJCRD_udStandardRate]  DEFAULT (0.00)
END
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bJCRD' AND COLUMN_NAME = 'udOldStandardRate')
BEGIN
	ALTER TABLE [dbo].[bJCRD] ADD [udOldStandardRate] AS ( OldRate/(1+udOldBurdenPercent) ) --NOT NULL CONSTRAINT [DF_bJCRD_udOldStandardRate]  DEFAULT (0.00)
END
GO

--Refresh the View so it reflects new columns.
sp_refreshview JCRD
go

--Set Initial Burden Percentage Values
update JCRD set [udBurdenPercent]=.42, [udOldBurdenPercent]=.37 where JCCo < 100 and RateTemplate=1
update JCRD set [udBurdenPercent]=.45, [udOldBurdenPercent]=.42 where JCCo < 100 and RateTemplate=1501
go

--Custom Fields
--select * from vDDFIc where Form='JCRateTemplateDetail' and ColumnName in ('udDestAPCo','udAPBatchProcessedYN')
if exists ( select 1 from vDDFIc where Form='JCRateTemplateDetail' and ColumnName='udStandardRate')
begin
	delete vDDFIc where Form='JCRateTemplateDetail' and ColumnName='udStandardRate'
end
if exists ( select 1 from vDDFIc where Form='JCRateTemplateDetail' and ColumnName='udOldStandardRate')
begin
	delete vDDFIc where Form='JCRateTemplateDetail' and ColumnName='udOldStandardRate'
end
if exists ( select 1 from vDDFIc where Form='JCRateTemplateDetail' and ColumnName='udBurdenPercent')
begin
	delete vDDFIc where Form='JCRateTemplateDetail' and ColumnName='udBurdenPercent'
end
if exists ( select 1 from vDDFIc where Form='JCRateTemplateDetail' and ColumnName='udOldBurdenPercent')
begin
	delete vDDFIc where Form='JCRateTemplateDetail' and ColumnName='udOldBurdenPercent'
end

-- Add UD Fields for Viewpoint DD Tables
begin
	insert vDDFIc (Form,Seq,ViewName,ColumnName,Description,Datatype,InputType,InputMask,InputLength,Prec,ActiveLookup,LookupParams,LookupLoadSeq,SetupForm,SetupParams,StatusText,Tab,TabIndex,Req,ValProc,ValParams,ValLevel,UpdateGroup,ControlType,ControlPosition,FieldType,DefaultType,DefaultValue,InputSkip,Label,ShowGrid,ShowForm,GridCol,AutoSeqType,MinValue,MaxValue,ValExpression,ValExpError,ComboType,GridColHeading,HeaderLinkSeq,CustomControlSize,Computed,ShowDesc,ColWidth,DescriptionColWidth,IsFormFilter,ExcludeFromAggregation)
	values ('JCRateTemplateDetail',	150,	'JCRD',	'udOldStandardRate',			'Old Standard Rate',	'bUnitCost',	NULL,	NULL,	NULL,	NULL,	'N',	NULL,	0,	NULL,	NULL,	'Old Standard Rate (Calculated)',	1,	99,	'Y',	null,	null,	2,	NULL,	0,	'107,221,372,21',	4,	0,	0.00,	NULL,	'Old Standard Rate',	'Y',	'Y',	5010,	0,	null,	null,	'^[^.]*$',	'Calculated field, Entry not allowed',	NULL,	'Old Standard Rate',	NULL,	NULL,		NULL,	NULL,	NULL,	NULL,	NULL,	'N')

	insert vDDFIc (Form,Seq,ViewName,ColumnName,Description,Datatype,InputType,InputMask,InputLength,Prec,ActiveLookup,LookupParams,LookupLoadSeq,SetupForm,SetupParams,StatusText,Tab,TabIndex,Req,ValProc,ValParams,ValLevel,UpdateGroup,ControlType,ControlPosition,FieldType,DefaultType,DefaultValue,InputSkip,Label,ShowGrid,ShowForm,GridCol,AutoSeqType,MinValue,MaxValue,ValExpression,ValExpError,ComboType,GridColHeading,HeaderLinkSeq,CustomControlSize,Computed,ShowDesc,ColWidth,DescriptionColWidth,IsFormFilter,ExcludeFromAggregation)
	values ('JCRateTemplateDetail',	160,	'JCRD',	'udStandardRate',	'Standard Rate',		'bUnitCost',		NULL,	NULL,	NULL,	NULL,	'N',	NULL,	0,	NULL,	NULL,	'Standard Rate (Calculated)',				1,	99,	'Y',	NULL,				NULL,		2,	NULL,	0,	'107,610,132,21',	4,	2,	0.00	,	NULL,	'Standard Rate',	'Y',	'Y',	5015,	0,	null,	null,	'^[^.]*$',	'Calculated field, Entry not allowed',	NULL,	'Standard Rate',	NULL,	null,	NULL,	NULL,	NULL,	NULL,	NULL,	'N')

	insert vDDFIc (Form,Seq,ViewName,ColumnName,Description,Datatype,InputType,InputMask,InputLength,Prec,ActiveLookup,LookupParams,LookupLoadSeq,SetupForm,SetupParams,StatusText,Tab,TabIndex,Req,ValProc,ValParams,ValLevel,UpdateGroup,ControlType,ControlPosition,FieldType,DefaultType,DefaultValue,InputSkip,Label,ShowGrid,ShowForm,GridCol,AutoSeqType,MinValue,MaxValue,ValExpression,ValExpError,ComboType,GridColHeading,HeaderLinkSeq,CustomControlSize,Computed,ShowDesc,ColWidth,DescriptionColWidth,IsFormFilter,ExcludeFromAggregation)
	values ('JCRateTemplateDetail',	170,	'JCRD',	'udOldBurdenPercent',			'Old Burden Percent',	'bRate',	null,	NULL,	NULL,	NULL,	'N',	NULL,	0,	NULL,	NULL,	'Old Burden Percent',	1,	99,	'Y',	null,	null,	2,	NULL,	0,	'107,221,372,21',	4,	0,	0.00,	NULL,	'Old Burden Percent',	'Y',	'Y',	5020,	0,	0,	1,	NULL,	'Percentage between 0 and 1',	NULL,	'Old Burden Percent',	NULL,	NULL,		NULL,	NULL,	NULL,	NULL,	NULL,	'N')

	insert vDDFIc (Form,Seq,ViewName,ColumnName,Description,Datatype,InputType,InputMask,InputLength,Prec,ActiveLookup,LookupParams,LookupLoadSeq,SetupForm,SetupParams,StatusText,Tab,TabIndex,Req,ValProc,ValParams,ValLevel,UpdateGroup,ControlType,ControlPosition,FieldType,DefaultType,DefaultValue,InputSkip,Label,ShowGrid,ShowForm,GridCol,AutoSeqType,MinValue,MaxValue,ValExpression,ValExpError,ComboType,GridColHeading,HeaderLinkSeq,CustomControlSize,Computed,ShowDesc,ColWidth,DescriptionColWidth,IsFormFilter,ExcludeFromAggregation)
	values ('JCRateTemplateDetail',	180,	'JCRD',	'udBurdenPercent',	'Burden Percent',		'bRate',		NULL,	NULL,	NULL,	NULL,	'N',	NULL,	0,	NULL,	NULL,	'Burden Percent',				1,	99,	'Y',	NULL,				NULL,		2,	NULL,	0,	'107,610,132,21',	4,	2,	0.00	,	NULL,	'Burden Percent',	'Y',	'Y',	5025,	0,	0,	1,	NULL,	'Percentage between 0 and 1',	NULL,	'Burden Percent',	NULL,	null,	NULL,	NULL,	NULL,	NULL,	NULL,	'N')
end
go







