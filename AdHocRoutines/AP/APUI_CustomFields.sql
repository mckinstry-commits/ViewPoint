IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bAPUI' AND COLUMN_NAME = 'udAPBatchProcessedYN')
begin
	ALTER TABLE [dbo].[bAPUI] DROP COLUMN [udAPBatchProcessedYN]
end 
go

IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bAPUI' AND COLUMN_NAME = 'udDestAPCo')
begin
	ALTER TABLE [dbo].[bAPUI] DROP COLUMN [udDestAPCo]
end 
go

--Add Custom Columns to datbase table
IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bAPUI' AND COLUMN_NAME = 'udAPBatchProcessedYN')
BEGIN
	ALTER TABLE [dbo].[bAPUI] ADD [udAPBatchProcessedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWD_udBatchProcessedYN]  DEFAULT ('N')
END
GO

 
IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bAPUI' AND COLUMN_NAME = 'udDestAPCo')
BEGIN
	ALTER TABLE [dbo].[bAPUI] ADD [udDestAPCo] [dbo].[bCompany] NULL 
END
GO

--Refresh the View so it reflects new columns.
sp_refreshview APUI

--Custom Lookup

--select * from vDDLHc where Lookup='udAPCONotCurrent'
--select * from vDDLDc where Lookup='udAPCONotCurrent'

if exists ( select 1 from vDDLHc where Lookup='udAPCONotCurrent' )
begin
	delete vDDLHc where Lookup='udAPCONotCurrent'
	delete vDDLDc  where Lookup='udAPCONotCurrent'
end
go

begin
	insert vDDLHc (Lookup,Title,FromClause,WhereClause,JoinClause,OrderByColumn,Memo,GroupByClause,Version)
	values ('udAPCONotCurrent','Alternate AP Company','APCO with (nolock)','APCo <> ?','Join HQCO with(nolock) on APCO.APCo=HQCO.HQCo',0,'AP Companies',NULL,6)

	insert vDDLDc (Lookup,Seq,ColumnName,ColumnHeading,Hidden,Datatype,InputType,InputLength,InputMask,Prec)
	values ('udAPCONotCurrent',0,'APCo','Company','N','bAPCo',NULL,NULL,NULL,NULL)

	insert vDDLDc (Lookup,Seq,ColumnName,ColumnHeading,Hidden,Datatype,InputType,InputLength,InputMask,Prec)
	values ('udAPCONotCurrent',1,'HQCO.Name','Name','N',NULL,0,30,NULL,NULL)
end
go


--Custom Validator
--select * from bUDVH where ValProc='uspAltHQCOVal'
--select * from bUDVT where ValProc='uspAltHQCOVal'
--select * from bUDVD where ValProc='uspAltHQCOVal'

if exists ( select 1 from bUDVH where ValProc='uspAltHQCOVal' )
begin
	delete bUDVH where ValProc='uspAltHQCOVal'
	delete bUDVT  where ValProc='uspAltHQCOVal'
	delete bUDVD  where ValProc='uspAltHQCOVal'
end
go

begin
	insert bUDVH (ValProc,ProcView,Notes,Description,UniqueAttchID/* ,KeyID */)
	values 
	(
		'uspAltHQCOVal'
	,	'
		/** User Defined Validation Procedure **/
		(@? varchar(100), @msg varchar(255) output)
		AS

		declare @rcode int
		select @rcode = 0


		/****/
		if exists(select * from [HQCO] with (nolock) where   @? = [HQCo] And  @? <> [HQCo] )
		begin
		select @msg = isnull([Name],@msg) from [HQCO] with (nolock) where   @? = [HQCo] And  @? <> [HQCo] 
		end
		else
		begin
		select @msg = ''Not a valid company'', @rcode = 1
		goto spexit
		end

		spexit:

		return @rcode

		end
		'
	,	null
	,	'Alternate HQCO Validation'
	,	NULL
	--,	91
	)

	insert bUDVT (ValProc,TableName,ErrorMessage,DescriptionColumn,UniqueAttchID /*,KeyID */)
	values ('uspAltHQCOVal','HQCO','Not a valid company','Name',NULL/*,102*/)
	
	insert bUDVD (Seq,TypePC,Parameter,ValProc,TableName,AndOr,Operator,Type,ColumnName,Value,Notes,UniqueAttchID/*,KeyID*/)
	values (1,	'P',	'DescCo',	'uspAltHQCOVal',	'HQCO',	NULL,	'=',	'C',	'HQCo',	NULL,	NULL,	NULL/*,	179*/)

	insert bUDVD (Seq,TypePC,Parameter,ValProc,TableName,AndOr,Operator,Type,ColumnName,Value,Notes,UniqueAttchID/*,KeyID*/)
	values (2,	'P',	'CurCo',	'uspAltHQCOVal',	'HQCO',	'And',	'<>',	'C',	'HQCo',	NULL,	NULL,	NULL/*,	181*/)
end
go


if exists ( select 1 from sysobjects where name='uspAltHQCOVal' and type='P')
begin
	drop procedure uspAltHQCOVal
end
go

CREATE procedure [dbo].[uspAltHQCOVal] /** User Defined Validation Procedure **/
(@DescCo varchar(100), @CurCo varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [HQCO] with (nolock) where   @DescCo = [HQCo] And  @CurCo <> [HQCo] )
begin
select @msg = isnull([Name],@msg) from [HQCO] with (nolock) where   @DescCo = [HQCo] And  @CurCo <> [HQCo] 
end
else
begin
select @msg = 'Not a valid company', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO


--Custom Fields
--select * from vDDFIc where Form='APUnappInv' and ColumnName in ('udDestAPCo','udAPBatchProcessedYN')
if exists ( select 1 from vDDFIc where Form='APUnappInv' and ColumnName='udDestAPCo')
begin
	delete vDDFIc where Form='APUnappInv' and ColumnName='udDestAPCo'
end
if exists ( select 1 from vDDFIc where Form='APUnappInv' and ColumnName='udAPBatchProcessedYN')
begin
	delete vDDFIc where Form='APUnappInv' and ColumnName='udAPBatchProcessedYN'
end

begin
	insert vDDFIc (Form,Seq,ViewName,ColumnName,Description,Datatype,InputType,InputMask,InputLength,Prec,ActiveLookup,LookupParams,LookupLoadSeq,SetupForm,SetupParams,StatusText,Tab,TabIndex,Req,ValProc,ValParams,ValLevel,UpdateGroup,ControlType,ControlPosition,FieldType,DefaultType,DefaultValue,InputSkip,Label,ShowGrid,ShowForm,GridCol,AutoSeqType,MinValue,MaxValue,ValExpression,ValExpError,ComboType,GridColHeading,HeaderLinkSeq,CustomControlSize,Computed,ShowDesc,ColWidth,DescriptionColWidth,IsFormFilter,ExcludeFromAggregation)
	values ('APUnappInv',	5010,	'APUI',	'udDestAPCo',			'Destination Company',	'bAPCo',	1,	NULL,	NULL,	NULL,	'N',	NULL,	0,	NULL,	NULL,	'Select the company you would like this entry to be re-associ',	1,	99,	'N',	'uspAltHQCOVal',	'5010,-1',	2,	NULL,	6,	'107,221,372,21',	4,	0,	NULL,	NULL,	'Destination Company',	'Y',	'Y',	5010,	0,	NULL,	NULL,	NULL,	NULL,	NULL,	'Destination Company',	NULL,	NULL,		NULL,	NULL,	NULL,	NULL,	NULL,	'N')

	insert vDDFIc (Form,Seq,ViewName,ColumnName,Description,Datatype,InputType,InputMask,InputLength,Prec,ActiveLookup,LookupParams,LookupLoadSeq,SetupForm,SetupParams,StatusText,Tab,TabIndex,Req,ValProc,ValParams,ValLevel,UpdateGroup,ControlType,ControlPosition,FieldType,DefaultType,DefaultValue,InputSkip,Label,ShowGrid,ShowForm,GridCol,AutoSeqType,MinValue,MaxValue,ValExpression,ValExpError,ComboType,GridColHeading,HeaderLinkSeq,CustomControlSize,Computed,ShowDesc,ColWidth,DescriptionColWidth,IsFormFilter,ExcludeFromAggregation)
	values ('APUnappInv',	5015,	'APUI',	'udAPBatchProcessedYN',	'Batch Processed',		'bYN',		0,	NULL,	NULL,	NULL,	'N',	NULL,	0,	NULL,	NULL,	'Y/N to indicate whether the Batch is processed.',				1,	99,	'Y',	NULL,				NULL,		2,	NULL,	14,	'107,610,132,21',	4,	2,	'N'	,	NULL,	'AP Batch Processed',	'N',	'N',	5015,	0,	NULL,	NULL,	NULL,	NULL,	NULL,	'AP Batch Processed',	NULL,	'0,132',	NULL,	NULL,	NULL,	NULL,	NULL,	'N')
end
go


--Custom Form Field Validator Assignment
--select * from vDDFLc  where Form='APUnappInv'
if exists ( select 1 from vDDFLc where Form='APUnappInv' and Seq=5010)
begin
	delete vDDFLc where Form='APUnappInv' and Seq=5010
end

begin
	insert vDDFLc (Form,Seq,Lookup,LookupParams,Active,LoadSeq)
	values ('APUnappInv',5010,'udAPCONotCurrent','-1','Y',1)
end
go



