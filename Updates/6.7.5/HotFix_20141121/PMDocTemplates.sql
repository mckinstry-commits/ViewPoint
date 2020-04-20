/*****************************************************************************************************************************
****  This file is genereated by: Viewpoint\Data Dictionary\Programs\DD Form Header\Export(tab)  
****  DO NOT EDIT MANUALLY 

ScottP 02/05/2014 TFS-70346 Implement a default for the Edit checkbox given the selected Template
ScottP 02/21/2014 TFS-74937 Merge C&S Edit Workflow modifications from 6.8
****************************************************************************************************************************/

 BEGIN TRANSACTION 
    BEGIN TRY
    DECLARE @errMsg VARCHAR(2000);
    SET @errMsg = ''; 
  
 -- Disable Forgein Keys on table 
ALTER TABLE [vDDFH] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDFI] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDFL] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDMF] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDFT] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDTD] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vRPFR] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vRPFD] NOCHECK CONSTRAINT ALL;
ALTER TABLE [pPortalDetailsField] NOCHECK CONSTRAINT ALL;
ALTER TABLE [bDDUD] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDRelatedForms] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDFormRelated] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDQueryableColumns] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDQueryableViews] NOCHECK CONSTRAINT ALL;
ALTER TABLE [bHQAD] NOCHECK CONSTRAINT ALL;
ALTER TABLE [bDDUF] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDFormCountries] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vDDFormRelatedInfo] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vVPPartFormChangedMessages] NOCHECK CONSTRAINT ALL;
ALTER TABLE [vVPPartFormChangedParameters] NOCHECK CONSTRAINT ALL;

-- [vDDFH]
ALTER TABLE [vDDFH] DISABLE TRIGGER ALL; 
DELETE FROM [vDDFH] WHERE [Form] = 'PMDocTemplates' 
INSERT INTO [vDDFH] ([Form],[Title],[FormType],[ShowOnMenu],[IconKey],[ViewName],[JoinClause],[WhereClause],[AssemblyName],[FormClassName],[ProgressClip],[FormNumber],[HelpFile],[HelpKeyword],[NotesTab],[LoadProc],[LoadParams],[PostedTable],[AllowAttachments],[Version],[Mod],[HasProgressIndicator],[CoColumn],[BatchProcessForm],[OrderByClause],[V5xForm],[DefaultTabPage],[LicLevel],[AllowCustomFields],[CustomFieldTable],[SecurityForm],[QueryView],[TitleID],[OldHelpID],[oldHelpFile],[ShowFormProperties],[ShowFieldProperties],[AlwayInheritAddUpdateDelete],[CustomFieldView],[MenuCategoryID],[FormattedNotesTab],[ChangeNotes])VALUES('PMDocTemplates','PM Create & Send Templates',1,'Y','f_Maintenance','HQWD','left join HQWT with (nolock) on HQWT.TemplateType=HQWD.TemplateType',NULL,'PM','frmPMDocTemplates',NULL,243,'Viewpoint.mchelp','24000060',5,'vspCompanyVal','-1,''PM''',NULL,'Y',6,'PM','N',NULL,NULL,NULL,'PMDocTemplates',1,2,'Y','bHQWD','PMDocTemplates',NULL,NULL,NULL,NULL,'Y','Y',NULL,NULL,2,NULL,'ScottP 02/05/2014 TFS-70346 Implement a default for the Edit checkbox given the selected Template
ScottP 02/21/2014 TFS-74937 Merge C&S Edit Workflow modifications from 6.8')
ALTER TABLE [vDDFH] ENABLE TRIGGER ALL 


-- [vDDFI]
ALTER TABLE [vDDFI] DISABLE TRIGGER ALL; 
DELETE FROM [vDDFI] WHERE [Form] = 'PMDocTemplates' 
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',0,'HQWD','TemplateName','Template Name',NULL,0,NULL,40,NULL,'N',NULL,0,NULL,NULL,'Enter the template name.',NULL,'Y',NULL,NULL,0,NULL,0,2,'24000473',NULL,0,0,NULL,NULL,NULL,NULL,NULL,'Y','Y','Template Name','PMDocTemplates',0,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',10,'HQWD','Location','Location',NULL,0,NULL,10,NULL,'N',NULL,0,'PMDocLocations','-1,10','Enter a valid PM Document Template Location.',1,'Y','bspHQWLVal','10',3,NULL,0,0,'24000474','dbo.vfPMLocationPath(HQWD.Location) as [Location Path]',10,0,NULL,NULL,NULL,NULL,NULL,'Y','Y','Location','PMDocTemplates',10,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',20,'HQWD','FileName','File Name',NULL,0,NULL,60,NULL,'N',NULL,0,NULL,NULL,'Enter the file name of the document template',1,'Y','bspHQWDFileNameVal','0,10,20,-21,-23',2,NULL,0,0,'24000475',NULL,20,0,NULL,NULL,NULL,NULL,NULL,'Y','Y','File Name','PMDocTemplates',20,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',21,NULL,NULL,'FileName Template Type',NULL,0,NULL,0,NULL,'N',NULL,NULL,NULL,NULL,'holds template type for template file if any',NULL,'N',NULL,NULL,0,NULL,99,0,NULL,NULL,21,0,NULL,NULL,NULL,NULL,NULL,'N','N','DfltTempType',NULL,NULL,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',22,NULL,NULL,'FileName Submittal Type',NULL,0,NULL,0,NULL,'N',NULL,NULL,NULL,NULL,'holds template file default submittal type if any',NULL,'N',NULL,NULL,0,NULL,99,0,NULL,NULL,22,0,NULL,NULL,NULL,NULL,NULL,'N','N','DfltSubmitType',NULL,NULL,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',23,NULL,NULL,'FileName Word Type',NULL,1,NULL,0,0,'N',NULL,NULL,NULL,NULL,'holds default template file word table if any',NULL,'N',NULL,NULL,0,NULL,99,0,NULL,NULL,23,0,NULL,NULL,NULL,NULL,NULL,'N','N','DfltWordTable',NULL,NULL,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',30,'HQWD','TemplateType','Template Type',NULL,0,NULL,10,NULL,'N',NULL,0,NULL,NULL,'Specify the type of document template.',1,'Y','bspHQWTVal','30,-31,-999,-999',2,NULL,0,0,'24000476','HQWT.Description as [Template Type Desc]',30,0,NULL,NULL,NULL,NULL,NULL,'Y','Y','Template Type','PMDocTemplates',30,NULL,'N',0,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',31,'HQWT','WordTable','Word Table flag','bYN',NULL,NULL,NULL,NULL,'N',NULL,0,NULL,NULL,'hidden column holds flag to indicate if the template type has word table object',NULL,'N',NULL,NULL,0,NULL,99,0,NULL,NULL,31,0,NULL,NULL,NULL,NULL,NULL,'N','Y','WordTable Flag','PMDocTemplates',31,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',40,'HQWD','StdObject','Standard Object','bYN',NULL,NULL,NULL,NULL,'N',NULL,0,NULL,NULL,'hidden flag for standard template',1,'Y',NULL,NULL,0,NULL,1,0,NULL,NULL,40,0,NULL,NULL,NULL,NULL,NULL,'N','N','Std Object',NULL,NULL,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',45,'HQWD','CreateFileType','Create type of document',NULL,0,NULL,4,NULL,'N',NULL,NULL,NULL,NULL,'Specify the type of document to create (i.e. doc, docx, pdf.)',1,'Y',NULL,NULL,3,NULL,3,0,'350000512',NULL,45,0,NULL,NULL,NULL,'Specify the type of document to create: (doc), (docx), (pdf)','PMTypeOfDoc','Y','Y','Type of Document',NULL,NULL,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',47,'HQWD','AutoResponse','Automated Response','bYN',NULL,NULL,NULL,NULL,'N',NULL,NULL,NULL,NULL,'Check to generate an Automated Response document.',NULL,'Y',NULL,NULL,0,NULL,1,0,'350000511',NULL,47,0,NULL,NULL,NULL,NULL,NULL,'Y','Y','Automated Response',NULL,NULL,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',50,'HQWD','Active','Active','bYN',NULL,NULL,NULL,NULL,'N',NULL,0,NULL,NULL,'Check to show in document list boxes.',1,'Y',NULL,NULL,3,NULL,1,0,'24000478',NULL,50,0,NULL,NULL,NULL,NULL,NULL,'Y','Y','Active','PMDocTemplates',50,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',55,'HQWD','EditDocDefault','Edit Doc in Create and Send','bYN',NULL,NULL,NULL,NULL,'N',NULL,NULL,NULL,NULL,NULL,NULL,'Y',NULL,NULL,3,NULL,1,0,NULL,NULL,55,0,NULL,NULL,NULL,NULL,NULL,'Y','Y','Edit Doc in Create and Send',NULL,NULL,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N','N')
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',60,'HQWD','WordTable','Word Table',NULL,1,NULL,2,0,'N',NULL,0,NULL,NULL,'Enter the word table # if changed from standard.',1,'Y',NULL,NULL,3,NULL,0,0,'24000479',NULL,60,0,NULL,NULL,NULL,NULL,NULL,'Y','Y','Word Table','PMDocTemplates',60,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
INSERT INTO [vDDFI] ([Form],[Seq],[ViewName],[ColumnName],[Description],[Datatype],[InputType],[InputMask],[InputLength],[Prec],[ActiveLookup],[LookupParams],[LookupLoadSeq],[SetupForm],[SetupParams],[StatusText],[Tab],[Req],[ValProc],[ValParams],[ValLevel],[UpdateGroup],[ControlType],[FieldType],[HelpKeyword],[DescriptionColumn],[GridCol],[AutoSeqType],[MinValue],[MaxValue],[ValExpression],[ValExpError],[ComboType],[ShowGrid],[ShowForm],[GridColHeading],[V5xForm],[V5xSeq],[HeaderLinkSeq],[Computed],[ShowDesc],[ColWidth],[DescriptionColWidth],[IsFormFilter],[LabelTextID],[ColumnTextID],[ShowInQueryFilter],[ShowInQueryResultSet],[QueryColumnName],[OldHelpID],[ExcludeFromRecordCopy],[ExcludeFromAggregation])VALUES('PMDocTemplates',99,'HQWD','Notes','Notes','bNotes',NULL,NULL,NULL,NULL,'N',NULL,0,NULL,NULL,'Enter notes',5,'N',NULL,NULL,0,NULL,0,1,'350000677',NULL,99,0,NULL,NULL,NULL,NULL,NULL,'Y','Y','Notes','PMDocTemplates',99,NULL,'N',2,NULL,NULL,'N',NULL,NULL,'N','N',NULL,NULL,'N',NULL)
ALTER TABLE [vDDFI] ENABLE TRIGGER ALL 


-- [vDDFL]
ALTER TABLE [vDDFL] DISABLE TRIGGER ALL; 
DELETE FROM [vDDFL] WHERE [Form] = 'PMDocTemplates' 
INSERT INTO [vDDFL] ([Form],[Seq],[Lookup],[LookupParams],[LoadSeq])VALUES('PMDocTemplates',0,'HQWD',NULL,1)
INSERT INTO [vDDFL] ([Form],[Seq],[Lookup],[LookupParams],[LoadSeq])VALUES('PMDocTemplates',10,'HQWL',NULL,1)
INSERT INTO [vDDFL] ([Form],[Seq],[Lookup],[LookupParams],[LoadSeq])VALUES('PMDocTemplates',30,'HQWT',NULL,1)
ALTER TABLE [vDDFL] ENABLE TRIGGER ALL 


-- [vDDMF]
ALTER TABLE [vDDMF] DISABLE TRIGGER ALL; 
DELETE FROM [vDDMF] WHERE [Form] = 'PMDocTemplates' 
INSERT INTO [vDDMF] ([Mod],[Form])VALUES('PM','PMDocTemplates')
ALTER TABLE [vDDMF] ENABLE TRIGGER ALL 


-- [vDDFT]
ALTER TABLE [vDDFT] DISABLE TRIGGER ALL; 
DELETE FROM [vDDFT] WHERE [Form] = 'PMDocTemplates' 
INSERT INTO [vDDFT] ([Form],[Tab],[Title],[GridForm],[LoadSeq],[TitleID])VALUES('PMDocTemplates',0,'Grid',NULL,0,NULL)
INSERT INTO [vDDFT] ([Form],[Tab],[Title],[GridForm],[LoadSeq],[TitleID])VALUES('PMDocTemplates',1,'Info',NULL,1,NULL)
INSERT INTO [vDDFT] ([Form],[Tab],[Title],[GridForm],[LoadSeq],[TitleID])VALUES('PMDocTemplates',2,'Merge Fields','PMDocTemplatesMerge',2,NULL)
INSERT INTO [vDDFT] ([Form],[Tab],[Title],[GridForm],[LoadSeq],[TitleID])VALUES('PMDocTemplates',3,'Table Merge Fields','PMDocTemplatesTable',3,NULL)
INSERT INTO [vDDFT] ([Form],[Tab],[Title],[GridForm],[LoadSeq],[TitleID])VALUES('PMDocTemplates',4,'Response Fields','PMDocTemplatesResponse',4,NULL)
INSERT INTO [vDDFT] ([Form],[Tab],[Title],[GridForm],[LoadSeq],[TitleID])VALUES('PMDocTemplates',5,'Notes',NULL,5,NULL)
ALTER TABLE [vDDFT] ENABLE TRIGGER ALL 


-- [vDDTD]
ALTER TABLE [vDDTD] DISABLE TRIGGER ALL; 
DELETE FROM [vDDTD] WHERE MenuItem = 'PMDocTemplates'
ALTER TABLE [vDDTD] ENABLE TRIGGER ALL 


-- [vRPFR]
ALTER TABLE [vRPFR] DISABLE TRIGGER ALL; 
DELETE FROM [vRPFR] WHERE [Form] = 'PMDocTemplates' 
ALTER TABLE [vRPFR] ENABLE TRIGGER ALL 


-- [vRPFD]
ALTER TABLE [vRPFD] DISABLE TRIGGER ALL; 
DELETE FROM [vRPFD] WHERE [Form] = 'PMDocTemplates' 
ALTER TABLE [vRPFD] ENABLE TRIGGER ALL 


-- [pPortalDetailsField]
SET IDENTITY_INSERT [dbo].[pPortalDetailsField] ON;
ALTER TABLE [pPortalDetailsField] DISABLE TRIGGER ALL; 
DELETE FROM [pPortalDetailsField] WHERE [Form] = 'PMDocTemplates' 
ALTER TABLE [pPortalDetailsField] ENABLE TRIGGER ALL 
SET IDENTITY_INSERT [dbo].[pPortalDetailsField] OFF;


-- [bDDUD]
ALTER TABLE [bDDUD] DISABLE TRIGGER ALL; 
DELETE FROM [bDDUD] WHERE Form = 'PMDocTemplates' AND substring(ColumnName,1,2) <> 'ud'
ALTER TABLE [bDDUD] ENABLE TRIGGER ALL 


-- [vDDRelatedForms]
ALTER TABLE [vDDRelatedForms] DISABLE TRIGGER ALL; 
DELETE FROM [vDDRelatedForms] WHERE [Form] = 'PMDocTemplates' 
INSERT INTO [vDDRelatedForms] ([Form],[Tab],[GridKeySeq],[ParentFieldSeq])VALUES('PMDocTemplates',2,2000,0)
INSERT INTO [vDDRelatedForms] ([Form],[Tab],[GridKeySeq],[ParentFieldSeq])VALUES('PMDocTemplates',3,2000,0)
INSERT INTO [vDDRelatedForms] ([Form],[Tab],[GridKeySeq],[ParentFieldSeq])VALUES('PMDocTemplates',4,2000,0)
ALTER TABLE [vDDRelatedForms] ENABLE TRIGGER ALL 


-- [vDDFormRelated]
ALTER TABLE [vDDFormRelated] DISABLE TRIGGER ALL; 
DELETE FROM [vDDFormRelated] WHERE [Form] = 'PMDocTemplates' 
ALTER TABLE [vDDFormRelated] ENABLE TRIGGER ALL 


-- [vDDQueryableColumns]
SET IDENTITY_INSERT [dbo].[vDDQueryableColumns] ON;
ALTER TABLE [vDDQueryableColumns] DISABLE TRIGGER ALL; 
DELETE FROM [vDDQueryableColumns] WHERE [Form] = 'PMDocTemplates' 
ALTER TABLE [vDDQueryableColumns] ENABLE TRIGGER ALL 
SET IDENTITY_INSERT [dbo].[vDDQueryableColumns] OFF;


-- [vDDQueryableViews]
SET IDENTITY_INSERT [dbo].[vDDQueryableViews] ON;
ALTER TABLE [vDDQueryableViews] DISABLE TRIGGER ALL; 
DELETE FROM [vDDQueryableViews] WHERE [Form] = 'PMDocTemplates' 
ALTER TABLE [vDDQueryableViews] ENABLE TRIGGER ALL 
SET IDENTITY_INSERT [dbo].[vDDQueryableViews] OFF;


-- [bHQAD]
ALTER TABLE [bHQAD] DISABLE TRIGGER ALL; 
DELETE FROM [bHQAD]  WHERE Custom = 'N' AND [Form] = 'PMDocTemplates' 
ALTER TABLE [bHQAD] ENABLE TRIGGER ALL 


-- [bDDUF]
ALTER TABLE [bDDUF] DISABLE TRIGGER ALL; 
DELETE FROM [bDDUF] WHERE Form = 'PMDocTemplates' AND substring(Form,1,2) <> 'ud'
ALTER TABLE [bDDUF] ENABLE TRIGGER ALL 


-- [vDDFormCountries]
ALTER TABLE [vDDFormCountries] DISABLE TRIGGER ALL; 
DELETE FROM [vDDFormCountries] WHERE [Form] = 'PMDocTemplates' 
ALTER TABLE [vDDFormCountries] ENABLE TRIGGER ALL 


-- [vDDFormRelatedInfo]
ALTER TABLE [vDDFormRelatedInfo] DISABLE TRIGGER ALL; 
DELETE FROM [vDDFormRelatedInfo] WHERE [Form] = 'PMDocTemplates' 
ALTER TABLE [vDDFormRelatedInfo] ENABLE TRIGGER ALL 


-- [vVPPartFormChangedMessages]
SET IDENTITY_INSERT [dbo].[vVPPartFormChangedMessages] ON;
ALTER TABLE [vVPPartFormChangedMessages] DISABLE TRIGGER ALL; 
DELETE FROM [vVPPartFormChangedMessages] WHERE FormName = 'PMDocTemplates' AND KeyID < 1000000 
ALTER TABLE [vVPPartFormChangedMessages] ENABLE TRIGGER ALL 
SET IDENTITY_INSERT [dbo].[vVPPartFormChangedMessages] OFF;


-- [vVPPartFormChangedParameters]
SET IDENTITY_INSERT [dbo].[vVPPartFormChangedParameters] ON;
ALTER TABLE [vVPPartFormChangedParameters] DISABLE TRIGGER ALL; 
DELETE FROM [vVPPartFormChangedParameters] WHERE FormChangedID = (SELECT KeyID FROM vVPPartFormChangedMessages WHERE FormName = 'PMDocTemplates'  ) AND KeyID < 1000000 
ALTER TABLE [vVPPartFormChangedParameters] ENABLE TRIGGER ALL 
SET IDENTITY_INSERT [dbo].[vVPPartFormChangedParameters] OFF;

 -- Enable Forgein Keys on table 
ALTER TABLE [vDDFH] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDFI] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDFL] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDMF] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDFT] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDTD] CHECK CONSTRAINT ALL;
ALTER TABLE [vRPFR] CHECK CONSTRAINT ALL;
ALTER TABLE [vRPFD] CHECK CONSTRAINT ALL;
ALTER TABLE [pPortalDetailsField] CHECK CONSTRAINT ALL;
ALTER TABLE [bDDUD] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDRelatedForms] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDFormRelated] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDQueryableColumns] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDQueryableViews] CHECK CONSTRAINT ALL;
ALTER TABLE [bHQAD] CHECK CONSTRAINT ALL;
ALTER TABLE [bDDUF] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDFormCountries] CHECK CONSTRAINT ALL;
ALTER TABLE [vDDFormRelatedInfo] CHECK CONSTRAINT ALL;
ALTER TABLE [vVPPartFormChangedMessages] CHECK CONSTRAINT ALL;
ALTER TABLE [vVPPartFormChangedParameters] CHECK CONSTRAINT ALL;
 
		    COMMIT TRANSACTION;
		END TRY 
		BEGIN CATCH
			SET @errMsg = 'ERROR: Form:PMDocTemplates' + CAST(ERROR_NUMBER() as varchar(10)) + ' ' + ERROR_MESSAGE();
			ROLLBACK;
						SET IDENTITY_INSERT [pPortalDetailsField] OFF;
			SET IDENTITY_INSERT [vDDQueryableColumns] OFF;
			SET IDENTITY_INSERT [vDDQueryableViews] OFF;
			SET IDENTITY_INSERT [vVPPartFormChangedMessages] OFF;
			SET IDENTITY_INSERT [vVPPartFormChangedParameters] OFF;

			RAISERROR(@errMsg, 11, -1);
		END CATCH 
