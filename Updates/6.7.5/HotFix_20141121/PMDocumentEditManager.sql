/*****************************************************************************************************************************
****  This file is genereated by: Viewpoint\Data Dictionary\Programs\DD Form Header\Export(tab)  
****  DO NOT EDIT MANUALLY 

ScottP 02/05/2014 TFS-70346 Implement form that manages the user editing documents
ScottP 02/21/2014 TFS-74937 Merge C&S Edit Workflow modifications from 6.8
****************************************************************************************************************************/

 BEGIN TRANSACTION 
    BEGIN TRY
    DECLARE @errMsg VARCHAR(2000);
    SET @errMsg = ''; 
  
-- [vDDFH]
DELETE FROM [dbo].[vDDFH] WHERE [Form] = 'PMDocumentEditManager' 
INSERT [dbo].[vDDFH] ([Form],[Title],[FormType],[ShowOnMenu],[IconKey],[ViewName],[JoinClause],[WhereClause],[AssemblyName],[FormClassName],[ProgressClip],[FormNumber],[HelpFile],[HelpKeyword],[NotesTab],[LoadProc],[LoadParams],[PostedTable],[AllowAttachments],[Version],[Mod],[HasProgressIndicator],[CoColumn],[BatchProcessForm],[OrderByClause],[V5xForm],[DefaultTabPage],[LicLevel],[AllowCustomFields],[CustomFieldTable],[SecurityForm],[QueryView],[TitleID],[OldHelpID],[oldHelpFile],[ShowFormProperties],[ShowFieldProperties],[AlwayInheritAddUpdateDelete],[CustomFieldView],[MenuCategoryID],[FormattedNotesTab],[ChangeNotes])VALUES('PMDocumentEditManager','PM Document Edit Manager',3,'N','',NULL,NULL,NULL,'PM_cs','frmPMDocumentEditManager',NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,'N',6,'PM','N',NULL,NULL,NULL,NULL,1,1,'Y',NULL,'PMSendDocuments',NULL,NULL,NULL,NULL,'Y','Y',NULL,NULL,NULL,NULL,'ScottP 02/05/2014 TFS-70346 Implement form that manages the user editing documents')


-- [vDDFI]
DELETE FROM [dbo].[vDDFI] WHERE [Form] = 'PMDocumentEditManager' 


-- [vDDFL]
DELETE FROM [dbo].[vDDFL] WHERE [Form] = 'PMDocumentEditManager' 


-- [vDDMF]
DELETE FROM [dbo].[vDDMF] WHERE [Form] = 'PMDocumentEditManager' 
INSERT [dbo].[vDDMF] ([Mod],[Form])VALUES('PM','PMDocumentEditManager')


-- [vDDFT]
DELETE FROM [dbo].[vDDFT] WHERE [Form] = 'PMDocumentEditManager' 


-- [vDDTD]
DELETE FROM [dbo].[vDDTD] WHERE MenuItem = 'PMDocumentEditManager'


-- [vRPFR]
DELETE FROM [dbo].[vRPFR] WHERE [Form] = 'PMDocumentEditManager' 


-- [vRPFD]
DELETE FROM [dbo].[vRPFD] WHERE [Form] = 'PMDocumentEditManager' 


-- [pPortalDetailsField]
SET IDENTITY_INSERT [dbo].[pPortalDetailsField] ON;
DELETE FROM [dbo].[pPortalDetailsField] WHERE [Form] = 'PMDocumentEditManager' 
SET IDENTITY_INSERT [dbo].[pPortalDetailsField] OFF;


-- [bDDUD]
DELETE FROM [dbo].[bDDUD] WHERE Form = 'PMDocumentEditManager' AND substring(ColumnName,1,2) <> 'ud'


-- [vDDRelatedForms]
DELETE FROM [dbo].[vDDRelatedForms] WHERE [Form] = 'PMDocumentEditManager' 


-- [vDDFormRelated]
DELETE FROM [dbo].[vDDFormRelated] WHERE [Form] = 'PMDocumentEditManager' 


-- [vDDQueryableColumns]
SET IDENTITY_INSERT [dbo].[vDDQueryableColumns] ON;
DELETE FROM [dbo].[vDDQueryableColumns] WHERE [Form] = 'PMDocumentEditManager' 
SET IDENTITY_INSERT [dbo].[vDDQueryableColumns] OFF;


-- [vDDQueryableViews]
SET IDENTITY_INSERT [dbo].[vDDQueryableViews] ON;
DELETE FROM [dbo].[vDDQueryableViews] WHERE [Form] = 'PMDocumentEditManager' 
SET IDENTITY_INSERT [dbo].[vDDQueryableViews] OFF;


-- [bHQAD]
DELETE FROM [dbo].[bHQAD]  WHERE Custom = 'N' AND [Form] = 'PMDocumentEditManager' 


-- [bDDUF]
DELETE FROM [dbo].[bDDUF] WHERE Form = 'PMDocumentEditManager' AND substring(Form,1,2) <> 'ud'


-- [vDDFormCountries]
DELETE FROM [dbo].[vDDFormCountries] WHERE [Form] = 'PMDocumentEditManager' 


-- [vDDFormRelatedInfo]
DELETE FROM [dbo].[vDDFormRelatedInfo] WHERE [Form] = 'PMDocumentEditManager' 


-- [vVPPartFormChangedMessages]
SET IDENTITY_INSERT [dbo].[vVPPartFormChangedMessages] ON;
DELETE FROM [dbo].[vVPPartFormChangedMessages] WHERE FormName = 'PMDocumentEditManager' AND KeyID < 1000000 
SET IDENTITY_INSERT [dbo].[vVPPartFormChangedMessages] OFF;


-- [vVPPartFormChangedParameters]
SET IDENTITY_INSERT [dbo].[vVPPartFormChangedParameters] ON;
DELETE FROM [dbo].[vVPPartFormChangedParameters] WHERE FormChangedID = (SELECT KeyID FROM vVPPartFormChangedMessages WHERE FormName = 'PMDocumentEditManager'  ) AND KeyID < 1000000 
SET IDENTITY_INSERT [dbo].[vVPPartFormChangedParameters] OFF;

 -- Enable Constraints\Triggers on tables 
 
		    COMMIT TRANSACTION;
		END TRY 
		BEGIN CATCH
			SET @errMsg = 'ERROR: Form:PMDocumentEditManager' + CAST(ERROR_NUMBER() as varchar(10)) + ' ' + ERROR_MESSAGE();
			ROLLBACK;
						SET IDENTITY_INSERT [pPortalDetailsField] OFF;
			SET IDENTITY_INSERT [vDDQueryableColumns] OFF;
			SET IDENTITY_INSERT [vDDQueryableViews] OFF;
			SET IDENTITY_INSERT [vVPPartFormChangedMessages] OFF;
			SET IDENTITY_INSERT [vVPPartFormChangedParameters] OFF;

			RAISERROR(@errMsg, 11, -1);
		END CATCH 
