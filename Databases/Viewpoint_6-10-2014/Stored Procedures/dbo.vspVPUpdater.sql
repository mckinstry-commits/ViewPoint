SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVPUpdater]
/********************************
* Created: GG 01/02/06
* Modified: DANF 02/20/07 - Added the process to replace standard import data.
*			DANF 03/26/07 - Added DDHD to DD list.
*			DANF 05/16/07 - Added DDTI to the DD list.
*			DANF 08/14/07 - Fixed WDQ? inserts and updates.
*			GG 12/19/07 - Replace vRPRF values for standard reports (ReportID<10000)
*			DANF 01/10/08 - Added SQL Reserved words to the data update portion of the script.
*			DANF 04/10/08 - Issue 127532 update the DDDTc table with any new data types. 
*			CC 4/14/08 - Issue 127214 - (Localized labels) added DDTM and DDCT to dd update loop, added specific insert for DDCL
*			DANF 04/30/08 - Issue 126580 - Add vDDRelatedForms to DD update.
*			CC 05/30/08 - Issue 128455 - Add vWFMailSources to update routine.
*			DANF 07/21/08 - Issue 129043 - drop and readd foreign key [FK_vDMAttachmentTypes_TextID]
*			DANF 07/21/08 - Issue 128987 - clean up Form and Tab security entries
*			DANF 07/23/08 - Added Work flow tables 
*			DANF 09/30/08 - Issue 130022 Add HQAD to update process.
*			CC	 11/05/08 - Issue 130956 Add My Viewpoint tables
*			DANF 12/10/08 - Issue 131174 Add Report clean up code.
*			AARONL 1/19/08 - Issue #131328 Remove DDTS records for forms that do not support them.
*			JONATHANP 02/10/08 - Issue ?????? Add Query tables of vDDTC,vDDQueryableColumns and vDDQueryableViews
*			AARONL 03/12/09 - Issue #132700 - Modified AllowAttachments in DDFS code to handle the schema change to AttachmentSecurityLevel 
*			CC	 03/18/09 - Issue #127519 - Added DD tables for company copy
*			JONATHANP 04/03/09 - Issue #132810 - The section that deals with vDDQueryableViews now includes the AttachmentCompanyColumn.
*			CC	04/07/09 - Issue #129920 - Add IsKeyField column to WDQF queries and IsEventQuery to WDQY queries.
*			DANF 06/15/09 - Set Active flag to N for new modules in DDMO
*			DANF 11/12/09 - Added vDDFormCountries to the process.
*			CC	10/13/09 - Issue #132545 - Added Datatype column to vVPGridColumns copy
*			DANF 12/02/2009	- Added SkipIndex column to HQAD table for populating data.'
*			DANF 04/19/2010 - Added AttachmentFormName column for table vDDQueryableViews table Issue 135649
			ADAMR 5/3/2010 - Switching orders of the vDDCT and vDDCL tables because of a foreign key constraint
			ADAMR 9/28/2010 - Updating helpKeyword in the DDMO table
*			ADAMR 11/16/2010 - Fixing issue where foreignkey needs dropped that references DDFI
							also refactored a lot of the proc
			ADAMR 12/7/2010 - Issue# 139114 - Adding in the bHQAX table to copy data
*			GARTHT 12/17/2010 - Added 'vVPCanvasTreeItemsTemplate' to My Viewpoint table copy.
*			GP	12/21/2010 - Added 'vDDCustomActions', 'vDDCustomActionParameters', and 'vDDCustomActionRecordTypes' to My Viewpoint table copy.
*			GARTHT 12/21/2010 - Added modifications to My Viewpoint table copy: vVPPartSettingsTemplate, vVPCanvasSettingsTemplate, vVPCanvasGridPartSettingsTemplate, vVPCanvasGridSettingsTemplate.
			ADAMR 1/3/2011 - 142200 - putting brackets around database names to allow for odd naming, also removed goto vperror to better capture the errors in order to debug
			ADAMR 1/10/2011 - 141179 - adding vPRAUEmployerFBTCategories to the mix
			ADAMR 1/11/2011	- 142878 - rewriting to make adding tables easier, going to just use a list
								of tables and then loop through them to delete dest and insert source data
			ADAMR 2/8/2011 -  143289 - putting brackets around the column names so reserved names don't cause a script failure
*			ADAMR 2/8/2011 -  142350 - adding collation in so that we can upgrade to a case insensitive database
*			ADAMR 2/8/2011 -  141368 - moving over the Orphaned fix because we are killing the check proc since its over kill
*			ADAMR 2/22/2011 - 143291 - adding the constraint error message table to the copy
*			Gartht 3/12/2011 - TK-02495 - Added WC DD Tables to My Viewpoint Tables list.
*			CHRISG 3/24/2001 - TK-03299 - Added vVPCanvasTemplateGroup table
*			ADAMR 3/30/2011 - 138181 - Adding vPRAUBASGSTItems and vHQBASReasonCodes 
*			GF 03/31/2011 - TK-03569 TK-03562
*			TMS 10/07/2011 - TK-08466 - adding vCalendar
*			AR 1/2/2012 - TK-11349 - adding vRPRL on request from Gail
*			AR 1/3/2012 - TK-11372 - uncommenting DDTM,DDCT on request from Gail
*			AR 1/10/2012 - TK-00000 - removing RPRL because of build issues --> standard data entries are handled in 
									  svn://vcssvn.vcs.coaxis.net/_TRUNK/Database/Viewpoint/Data/dbo.vRPRL.sql
*			JG 3/21/2012 - TK-13418  - Added vHQApprovalModule for Approval Process.
*			GPT 6/01/2012 - TK-15320 - Added vVPGridQueryLinks,vVPGridQueryLinkParameters to DD copy.
*			GPT 6/04/2012 - TK-15320 - Fixed missing comma after vVPGridQueryLinkParameters.
*			JayR 06/14/2012 TK-14356 - We need to fix an issue where RPRL entries are missing from a upgrade of an existing database.
*			DK	06/29/2012 TK-15495 - Adding vRPRSServer to keep Report Location metadata in sync
*           JayR 07/02/2012 - TK-16112 - BackingOut code that INSERTED INTO vRPRL per Manny.  The SSRS installer is going TO do this INSTEAD.
*			Paul W 10/22/2012 - TK-18583 - Added vDDAssemblyDependency
*           Eric V 01/08/2013 - TK-20573 - Populate vSMLineType table with default values.
*           Eric V 01/08/2013 - TK-20572 - Populate vSMScopePriority table with default values.
*           JayR 01/15/2014   - TK-14355 - NO longer populate vRPRSServer WITH data AS it is causing issues IN the build. SSRS Reports installer will now INSERT the ROWS needed INTO the TABLE.
*           JayR 02/27/2013   Just rolling back code that was added TO debug build issues.
*			AMR 5/24/2013 - Removing truncation because of CDC and its need for a log, changing to disable triggers 			now because truncate bypassed them too
*           JayR 06/28/2013 TFS-4281 We are moving to a more script based meta DATA copy. 
*			
* Used by the server update process to replace standard Data Dictionary and Report data.
*
* Input: 
*	@sourcedb	Database holding standard VP DD and RP data
*	@destdb		Database being updated, all standard DD and RP data replaced
*
* Output:
*	@msg		
*
* Return code:
*
*
*********************************/
(	@sourcedb varchar(30) = null, 
	@SourceServer VARCHAR(100) = '',
	@destdb varchar(30) = null,
	@msg varchar(500) output)
AS
SET NOCOUNT ON

DECLARE @dd varchar(MAX),
		@rcode int,
		@t varchar(128),
		@tab varchar(128),
		@tsql varchar(max),
		@quote char(1),
		@vcCol varchar(max),
		@vcFK varchar(128)

SET @rcode = 0
-- revamping to handle more than just 4 char tables
SET @dd = 'vDDCB,vDDCI,vDDCS,vDDDT,vDDFH,vDDFI,vDDFL,vDDFR,'
		+ 'vDDFT,vDDHD,vDDLD,vDDLH,vDDLT,vDDMF,vDDSL,vDDTD,'
		+ 'vDDTF,vDDTH,vDDTI,'
		+ 'vRPFD,vRPFR,vRPPL,vRPRM,vRPRP,vRPRT,vRPTP,vRPTY,'
		+ 'vPRAUEmployerFBTCategories,vPRAUItems,vPRAUItemsATOCategories,'   
		+ 'bRPRLV5,bRPTYV5,bRPRTV5,bRPRMV5,bRPRPV5,bRPFRV5,bRPPLV5,'
		+ 'vDMAttachmentTypes,vDDTM,vDDRelatedForms,vDDCL,vDDCT,'
		+ 'vDDTC,vDDQueryableViews,vDDQueryableColumns,vDDFormCountries,vDDCustomConstraintErrorMsg,'
		--My Viewpoint tables 
		+ 'vVPCanvasSettingsTemplate,vRPRQ,vRPTM,vVPPartSettingsTemplate,' 
		+ 'vVPGridQueryAssociation,vVPGridQueries,vVPGridColumns,vVPGridQueryParameters,'
		+ 'vVPCanvasTreeItemsTemplate,vVPCanvasGridSettingsTemplate,vVPCanvasGridPartSettingsTemplate,'
		+ ''
		+ ''
		+ 'vVPCanvasTemplateGroup,vVPGridQueryLinks,vVPGridQueryLinkParameters,'
		--Work Flow Tables
		+ 'vWFVPTemplates,vWFVPTemplateTasks,vWFVPTemplateSteps,'
		--DD Company copy tables 
		+ 'vDDTables,vDDTableForms,'
		-- BAS Tables
		+ 'vPRAUBASGSTItems,vSQLReservedWords,'
		-- DD Related form tables TK-03562 TK-03569
		+ 'vDDFormRelated, vDDFormRelatedInfo,'
		-- BI Tables
		+ 'vCalendar,'
		-- Audit tables
		+ 'vAuditFlags,vAuditTables,vAuditFlagTables,vAuditColumns,vAuditFlagGroup,'
		-- HQ Approval Process
		+ 'vHQApprovalModule,'
		-- Assembly Dependency 
		+ 'vDDAssemblyDependency,'
		+ 'vSMLineType,'
		+ 'vSMScopePriority,'
		+ 'vPCCertificateTypes'
		
SET @quote = char(39);
SET @SourceServer = [dbo].[vfFormatServerName](@SourceServer);

DECLARE @tabMetaData TABLE (TabName varchar(150))
-- lets build a table of tables to update
INSERT INTO @tabMetaData (TabName)
SELECT RTRIM(LTRIM([Names])) -- just in case someone puts white space into the list
FROM dbo.vfTableFromArray(@dd)

BEGIN TRY
	-- disable triggers to avoid auditing and integrity checks
	-- disable the foreign keys and check constraints, relying on source data to be clean
	-- truncate the table
	-- insert from source
	-- renable the constraints
	-- renable triggers	
	WHILE EXISTS (SELECT 1 FROM @tabMetaData)
	BEGIN 
		SET @t = NULL
		SET @tab = NULL
		SELECT TOP (1) @tab = TabName
		FROM @tabMetaData
		
		SET @t = '.dbo.' + @tab 
		
		-- let's disable existing FKs
		BEGIN TRAN
			SET @vcCol = ''
			-- get columns so we don't do blind inserts
			SELECT @vcCol = @vcCol +  '[' + [name] + '],'
			FROM   sys.columns AS c
			WHERE  [object_id] = OBJECT_ID(@tab)

			-- remove last comma
			IF LEN(@vcCol) < 2
			BEGIN 
				SET @msg = 'Table not found ' + @tab
			   RAISERROR (@msg,15,1)
			END
			
			SET @vcCol = LEFT(@vcCol, LEN(@vcCol) - 1)
			SET @tsql = 'ALTER TABLE [' + @destdb + ']'+  @t + ' DISABLE TRIGGER ALL'
			EXEC (@tsql)
			
			-- disable foreign keys
			SET @tsql =	 'ALTER TABLE [' + @destdb + ']' +  @t + ' NOCHECK CONSTRAINT ALL'
			EXEC (@tsql)
			-- lets disable referencing FKs
			SET @tsql = 'EXEC [' + @destdb + '].dbo.vspDisableForeignKeyOnTable ''dbo.' + @tab + ''',' + '0'
			EXEC(@tsql)
			
			-- because of FKs I'm going to delete, these aren't huge tables normally so 
			-- the logged activity should be a slight hit
			SET @tsql = 'DELETE FROM [' + @destdb + ']'+ @t
			EXEC (@tsql)

			-- if we have an idenity lets insert it			
			IF EXISTS (SELECT 1
						FROM sys.columns AS c 
						WHERE [object_id] = OBJECT_ID(@t) 
							AND is_identity = 1			
						)
			BEGIN
				SET @tsql = 'SET IDENTITY_INSERT [' + @destdb + ']' + @t + ' ON;'
			END
			ELSE
			BEGIN 
				SET @tsql = ''
			END 
						
			SET @tsql = @tsql + 'INSERT [' + @destdb +']'+  @t  + ' (' + @vcCol + ') 
				  SELECT ' + @vcCol + ' FROM ' + @SourceServer + '[' + @sourcedb + ']' + @t
			EXEC(@tsql)
			
			-- enable the foreign keys
			SET @tsql =	 'ALTER TABLE [' + @destdb + ']' +  @t + ' CHECK CONSTRAINT ALL'
			EXEC (@tsql)
			-- lets enable referencing FKs
			SET @tsql = 'EXEC [' + @destdb + '].dbo.vspDisableForeignKeyOnTable ''dbo.' + @tab + ''',' + '1'
			EXEC(@tsql)
			
			-- enable the triggers
			SET @tsql = 'ALTER TABLE [' + @destdb + ']' +  @t + ' ENABLE TRIGGER ALL'
			EXEC (@tsql)
		COMMIT
		-- remove this record
		DELETE FROM @tabMetaData WHERE TabName = @tab
	END
	
	-- adding some collation stuff for column compares
	DECLARE @destCollation AS varchar(128)
	DECLARE @srcCollation AS varchar(128)
	-- pull the source and dest collations from the database
	SELECT @srcCollation = collation_name FROM sys.databases WHERE [name] = @sourcedb
	SELECT @destCollation = collation_name FROM sys.databases WHERE [name] = @destdb	

	IF @srcCollation = @destCollation
	BEGIN
	   SET @destCollation = ''
	END
	ELSE
	BEGIN
	   SET @destCollation = 'COLLATE ' + @destCollation
	END

	-- update the odd ball tables here where we have to do special queries
	-- replace Import data in DDUF and DDUD
	SET @tsql = 'alter table [' + @destdb + '].dbo.bDDUF disable trigger all'
	EXEC(@tsql)

	SET @tsql = 'alter table [' + @destdb + '].dbo.bDDUD disable trigger all'
	EXEC(@tsql)

	SET @tsql = 'delete [' + @destdb
		+ '].dbo.bDDUF where substring(Form,1,2) <> ' + @quote + 'ud' + @quote
	EXEC(@tsql)

	SET @tsql = 'delete [' + @destdb
		+ '].dbo.bDDUD where substring(ColumnName,1,2) <> ' + @quote + 'ud'
		+ @quote
	EXEC(@tsql)

	SET @tsql = 'insert [' + @destdb + '].dbo.bDDUF select * from ' + @SourceServer + '[' + @sourcedb
		+ '].dbo.bDDUF where substring(Form,1,2) <> ' + @quote + 'ud' + @quote
	EXEC(@tsql)

	SET @tsql = 'insert [' + @destdb + '].dbo.bDDUD select * from ' + @SourceServer + '[' + @sourcedb
		+ '].dbo.bDDUD where substring(ColumnName,1,2) <> ' + @quote + 'ud'
		+ @quote
	EXEC(@tsql)

	SET @tsql = 'alter table [' + @destdb + '].dbo.bDDUF  enable trigger all'
	EXEC(@tsql)

	SET @tsql = 'alter table [' + @destdb + '].dbo.bDDUD  enable trigger all'
	EXEC(@tsql)

	-- replace RPRF entries for all standard reports (ReportID <10000)
	SET @tsql = 'delete [' + @destdb + '].dbo.vRPRF where ReportID < 10000' 
	exec(@tsql)

	SET @tsql = 'insert [' + @destdb + '].dbo.vRPRF select * from ' + @SourceServer + '[' + @sourcedb + '].dbo.vRPRF where ReportID < 10000'
	exec(@tsql)

	-- add any new Modules to vDDMO
	SET @tsql = 'INSERT [' + @destdb
		+ '].dbo.vDDMO ([Mod], Title, Active, LicLevel ) SELECT [Mod], Title, '
		+ @quote + 'N' + @quote + ', LicLevel from ' + @SourceServer + '[' + @sourcedb
		+ '].dbo.vDDMO where [Mod] ' + @destCollation + ' not in (select [Mod] from [' + @destdb
		+ '].dbo.vDDMO)'
	EXEC(@tsql)

	-- update helpkeywords
	SELECT  @tsql = 'UPDATE destDDMO SET [HelpKeyword] = srcDDMO.[HelpKeyword] FROM ['
			+ @destdb + '].dbo.vDDMO destDDMO JOIN ' + @SourceServer + '[' + @sourcedb
			+ '].dbo.vDDMO srcDDMO ON srcDDMO.[Mod] ' + @destCollation + ' = destDDMO.[Mod]'
	EXEC(@tsql)

	-- update Version # to vDDVS
	SET @tsql = 'update [' + @destdb + '].dbo.vDDVS set Version = (select Version ' + @destCollation + ' from ' + @SourceServer + '['
		+ @sourcedb + '].dbo.vDDVS)' 
	exec(@tsql)

	-- add any new data types to DDDTc
	SET @tsql = 'INSERT INTO [' + @destdb + '].dbo.vDDDTc(Datatype, InputMask, InputLength, Prec, Secure, DfltSecurityGroup, Label, InputType) '
	SET @tsql = @tsql + 'select v.Datatype, v.InputMask, v.InputLength, v.Prec, '+ @quote + 'N' + @quote + ', char(null), char(null), v.InputType '
	SET @tsql = @tsql + 'from [' + @destdb + '].dbo.vDDDT v '
	SET @tsql = @tsql + 'where not exists (select 1 from [' + @destdb + '].dbo.vDDDTc c where c.Datatype = v.Datatype)'
	exec(@tsql)


-- add any new message sources to vWFMailSources
	SET @tsql = 'INSERT INTO [' + @destdb + '].dbo.vWFMailSources SELECT [Source] FROM ' + @SourceServer + '[' + @sourcedb
		 + '].dbo.vWFMailSources WHERE [Source] ' + @destCollation + ' NOT IN (SELECT [Source] FROM [' + @destdb + '].dbo.vWFMailSources)'
	exec(@tsql)
	
	SET @tsql = 'delete [' + @destdb + '].dbo.bWDQYSave; delete [' + @destdb + '].dbo.bWDQPSave; delete [' + @destdb + '].dbo.bWDQFSave'
	exec(@tsql)
	
	SET @tsql = 'insert [' + @destdb + '].dbo.bWDQYSave (QueryName,Description,Title,SelectClause,FromWhereClause,Standard,Notes,UniqueAttchID,IsEventQuery) '
	SET @tsql = @tsql +'select y.QueryName,y.Description,y.Title,y.SelectClause,y.FromWhereClause,y.Standard,y.Notes,y.UniqueAttchID,y.IsEventQuery '
	SET @tsql = @tsql + 'from [' + @destdb + '].dbo.bWDQY y '
	SET @tsql = @tsql + 'where y.Standard <>' + @quote + 'Y' + @quote
	exec(@tsql)

	SET @tsql = 'insert [' + @destdb + '].dbo.bWDQPSave (QueryName,Param,Description) '
	SET @tsql = @tsql +'select p.QueryName,p.Param,p.Description '
	SET @tsql = @tsql + 'from [' + @destdb + '].dbo.bWDQP p join [' + @destdb + '].dbo.bWDQY y on p.QueryName = y.QueryName '
	SET @tsql = @tsql + ' where y.Standard <>' + @quote + 'Y' + @quote
	exec(@tsql)

	SET @tsql = 'insert [' + @destdb + '].dbo.bWDQFSave(QueryName,Seq,TableColumn,EMailField,IsKeyField) '
	SET @tsql = @tsql +'select p.QueryName,p.Seq,p.TableColumn,p.EMailField,p.IsKeyField '
	SET @tsql = @tsql + 'from [' + @destdb + '].dbo.bWDQF p join [' + @destdb + '].dbo.bWDQY y on p.QueryName = y.QueryName '
	SET @tsql = @tsql + ' where y.Standard <>' + @quote + 'Y' + @quote
	exec(@tsql)

	SET @tsql = 'USE [' + @destdb + '];  DISABLE TRIGGER ALL ON dbo.bWDQY; ' 
	SET @tsql = @tsql + 'DELETE [' + @destdb + '].dbo.bWDQY;' 
	SET @tsql = @tsql + 'ENABLE TRIGGER ALL ON dbo.bWDQY;' 
	exec(@tsql)

	SET @tsql = 'USE [' + @destdb + ']; DISABLE TRIGGER ALL ON dbo.bWDQP;' 
	SET @tsql = @tsql + 'DELETE [' + @destdb + '].dbo.bWDQP;'
	SET @tsql = @tsql + 'ENABLE TRIGGER ALL ON dbo.bWDQP;' 
	exec(@tsql)
	
	--139114 - adding the bHQAX tab
	BEGIN TRY
		SET @tsql = 'DELETE [' + @destdb + '].dbo.bHQAX;' + CHAR(13) + CHAR(10)
		SET @tsql = @tsql + 'SET IDENTITY_INSERT [' + @destdb + '].dbo.bHQAX ON;' + CHAR(13) + CHAR(10)
	
		SET @tsql = @tsql +
					'INSERT INTO [' + @destdb + '].dbo.bHQAX
					(	KeyID,
						ParentColumn,
						Description,
						Notes,
						UniqueAttchID
					)
					SELECT	KeyID,
							ParentColumn,
							Description,
							Notes,
							UniqueAttchID
					FROM ' + @SourceServer + '[' + @sourcedb + '].dbo.bHQAX'

		 EXEC(@tsql)
	END TRY
	BEGIN CATCH
		GOTO vsperror
	END CATCH
 
begin TRY
	SET @tsql = 'DISABLE TRIGGER ALL ON [' + @destdb + '].dbo.bWDQF GO'
	SET @tsql = @tsql + 'DELETE [' + @destdb + '].dbo.bWDQF GO'
	SET @tsql = @tsql + 'ENABLE TRIGGER ALL ON [' + @destdb + '].dbo.bWDQF GO'
	exec(@tsql)
end try
begin catch
	
end catch

begin try
	SET @tsql = 'alter table [' + @destdb + '].dbo.bWDQY disable trigger all; insert [' + @destdb + '].dbo.bWDQY (QueryName, Description, Title, SelectClause, FromWhereClause, Standard, Notes, UniqueAttchID,IsEventQuery) select QueryName, Description, Title, SelectClause, FromWhereClause, Standard, Notes, UniqueAttchID, IsEventQuery from ' + @SourceServer + '[' + @sourcedb + '].dbo.bWDQY; alter table [' + @destdb + '].dbo.bWDQY enable trigger all;'
	exec(@tsql)
end try
begin catch
	
end catch

begin try
	SET @tsql = 'alter table [' + @destdb + '].dbo.bWDQP disable trigger all; insert [' + @destdb + '].dbo.bWDQP (QueryName, Param, Description, UniqueAttchID) select QueryName, Param, Description, UniqueAttchID from ' + @SourceServer + '[' + @sourcedb + '].dbo.bWDQP; alter table [' + @destdb + '].dbo.bWDQP enable trigger all;'
	exec(@tsql)
end try
begin catch
	
end catch

begin try
	SET @tsql = 'alter table [' + @destdb + '].dbo.bWDQF disable trigger all; insert [' + @destdb + '].dbo.bWDQF (QueryName, Seq, TableColumn, EMailField, IsKeyField) select QueryName, Seq, TableColumn, EMailField, IsKeyField from ' + @SourceServer + '[' + @sourcedb + '].dbo.bWDQF; alter table [' + @destdb + '].dbo.bWDQF enable trigger all;'
	exec(@tsql)
end try
begin catch
	
end catch

begin try
  	SET @tsql = 'alter table [' + @destdb + '].dbo.bWDQY disable trigger all; insert [' + @destdb + '].dbo.bWDQY (QueryName,Description,Title,SelectClause,FromWhereClause,Standard,Notes,UniqueAttchID,IsEventQuery) '
	SET @tsql = @tsql +'select y.QueryName,y.Description,y.Title,y.SelectClause,y.FromWhereClause,y.Standard,y.Notes,y.UniqueAttchID,y.IsEventQuery '
	SET @tsql = @tsql + 'from [' + @destdb + '].dbo.bWDQYSave y '
	SET @tsql = @tsql + 'where y.Standard <> ' + @quote + 'Y' + @quote + ' and not exists (select QueryName from [' + @destdb + '].dbo.bWDQY y2 where y.QueryName = y2.QueryName); alter table [' + @destdb + '].dbo.bWDQY enable trigger all;'
	exec(@tsql)
end try
begin catch
	
end catch

begin try
	SET @tsql = 'alter table [' + @destdb + '].dbo.bWDQP disable trigger all; insert [' + @destdb + '].dbo.bWDQP (QueryName,Param,Description) '
	SET @tsql = @tsql +'select p.QueryName,p.Param,p.Description '
	SET @tsql = @tsql + 'from [' + @destdb + '].dbo.bWDQPSave p join [' + @destdb + '].dbo.bWDQY y on p.QueryName = y.QueryName '
	SET @tsql = @tsql + ' where y.Standard <>' + @quote +'Y' + @quote + ' and not exists (select QueryName from [' + @destdb + '].dbo.bWDQP p2 where p.QueryName = p2.QueryName and p.Param = p2.Param ); alter table [' + @destdb + '].dbo.bWDQP enable trigger all;'
	exec(@tsql)
end try
begin catch
	
end catch

begin try
	SET @tsql = 'alter table [' + @destdb + '].dbo.bWDQF disable trigger all; insert [' + @destdb + '].dbo.bWDQF(QueryName,Seq,TableColumn,EMailField,IsKeyField) '
	SET @tsql = @tsql +'select p.QueryName,p.Seq,p.TableColumn,p.EMailField,p.IsKeyField '
	SET @tsql = @tsql + 'from  [' + @destdb + '].dbo.bWDQFSave p join [' + @destdb + '].dbo.bWDQY y on p.QueryName = y.QueryName '
	SET @tsql = @tsql + ' where y.Standard <>' + @quote + 'Y' + @quote + ' and not exists (select QueryName from ['+ @destdb + '].dbo.bWDQF p2 where p.QueryName = p2.QueryName and p.Seq = p2.Seq ); alter table [' + @destdb + '].dbo.bWDQF enable trigger all;'
	exec(@tsql)
end try
begin catch
	
end catch


-- Custom Clean Up of DD and Reports
	SET @tsql = 'DELETE [' + @destdb + '].dbo.vDDTS 
				 WHERE NOT EXISTS(	SELECT 1 
									FROM [' + @destdb + '].dbo.DDFTShared t 
									WHERE t.Form = vDDTS.Form and t.Tab = vDDTS.Tab)
				'
	
	EXEC (@tsql)
	
	SET @tsql = 'DELETE [' + @destdb + '].dbo.vDDTS
				 WHERE  NOT EXISTS ( SELECT 1
										FROM  [' + @destdb + '].dbo.DDFHShared t
										WHERE  t.Form = vDDTS.Form )'
	EXEC (@tsql)
	
	SET @tsql = 'DELETE  [' + @destdb + '].dbo.vDDTS
				 WHERE  Form NOT IN (	SELECT    Form
										FROM      [' + @destdb + '].dbo.DDFHShared
										WHERE     FormType IN ( 1, 2, 6 ) ) '
	
	EXEC (@tsql)

--select * from vDDFS  -- Form Security
	SET @tsql =	 '	DELETE [' + @destdb + '].dbo.vDDFS
					WHERE  NOT EXISTS ( SELECT 	1
									 FROM   [' + @destdb + '].dbo.DDFHShared t
									 WHERE  t.Form = vDDFS.Form ) '
	EXEC (@tsql)
									 
	SET @tsql = '	DELETE  [' + @destdb + '].dbo.vRPRS
					WHERE  NOT EXISTS ( SELECT 1
										FROM   [' + @destdb + '].dbo.RPRTShared t
										WHERE  t.ReportID = vRPRS.ReportID ) '
    EXEC (@tsql)								

	SET @tsql = '	DELETE [' + @destdb + '].dbo.vRPUP
					WHERE  NOT EXISTS ( SELECT 1
										FROM   [' + @destdb + '].dbo.RPRTShared t
										WHERE  t.ReportID = vRPUP.ReportID ) '

	EXEC (@tsql)
--
-- HQ Attachment Save

-- Set Form Security Allow attachments needs to match the Allow Attachment flag in Form Header
 SET @tsql = 'UPDATE [' + @destdb + '].dbo.vDDFS
			 SET    AttachmentSecurityLevel = NULL
			 FROM   [' + @destdb + '].dbo.vDDFS s
					JOIN [' + @destdb + '].dbo.vDDFH h ON s.Form = h.Form
			 WHERE  s.AttachmentSecurityLevel IN ( 0, 1, 2 )
					AND h.AllowAttachments = ''N'''
 EXEC (@tsql)
					

-- Remove columns that have been dropped from the schema
SET @tsql = 'DELETE FROM  [' + @destdb + '].dbo.vDDTC
			 FROM    [' + @destdb + '].dbo.vDDTC c
					JOIN ( SELECT   TableName,
									ColumnName
						   FROM      [' + @destdb + '].dbo.vDDTC
						   EXCEPT
							
							SELECT   TABLE_NAME AS TableName,
									 COLUMN_NAME AS ColumnName
							FROM      [' + @destdb + '].INFORMATION_SCHEMA.COLUMNS
					 ) s ON c.TableName = s.TableName
							AND c.ColumnName = s.ColumnName	 '
							
EXEC (@tsql)

END TRY
BEGIN CATCH
	IF @@TRANCOUNT <> 0
	BEGIN
		ROLLBACK
	END
	
	SET @msg = 'Error during update, unable to complete.' 
		+ char(13)+ char(10) +  @tsql + char(13)+ char(10) + ERROR_MESSAGE()
		
	RAISERROR(@msg,15,1) 
	
	SET @rcode = 1
	RETURN (@rcode)
END CATCH


begin try
	SET @tsql = 'use [' + @destdb + '] if exists (select top 1 1 from INFORMATION_SCHEMA.TABLES where TABLE_CATALOG =' + @quote + @destdb + @quote + ' and TABLE_NAME = ' + @quote + 'bHQADSave' + @quote + ' and TABLE_TYPE = ' + @quote + 'BASE TABLE' + @quote + ') ' 
	SET @tsql = @tsql + 'drop table [' + @destdb + '].dbo.bHQADSave'
	exec (@tsql)
end try
begin catch
	
end catch

begin try
	SET @tsql = 	'select * into [' + @destdb + '].dbo.bHQADSave from [' + @destdb + '].dbo.bHQAD where Custom=' + @quote + 'Y' + @quote
	exec (@tsql)
end try
begin catch
	
end catch

begin try
	SET @tsql = 'DELETE [' + @destdb + '].dbo.bHQAD'
	exec(@tsql)
end try
begin catch
	
end catch

begin try
	SET @tsql = 'insert [' + @destdb + '].dbo.bHQAD (RecID, ColumnName, Description, ParentColumn, Custom, Module, Form, SkipIndex) select RecID, ColumnName, Description, ParentColumn, Custom, Module, Form, SkipIndex from ' + @SourceServer + '[' + @sourcedb + '].dbo.bHQAD d where d.Custom = ' + @quote + 'N' + @quote + ';'
	exec(@tsql)
end try
begin catch
	
end catch

begin try
	SET @tsql = 'insert [' + @destdb + '].dbo.bHQAD(RecID, ColumnName, Description, ParentColumn, Custom, Module, Form, SkipIndex) '
	SET @tsql = @tsql +'select row_number() over (order by RecID) + isnull((select Max(RecID) from [' + @destdb + '].dbo.bHQAD ),0), ColumnName, Description, ParentColumn, Custom, Module, Form, SkipIndex '
	SET @tsql = @tsql + 'from [' + @destdb + '].dbo.bHQADSave p '
	SET @tsql = @tsql + ' where p.Custom =' + @quote + 'Y' + @quote
	exec(@tsql)
end try
begin catch
	
end CATCH

--138181 - only copy reason codes first time through, if rows are in table, do not change
BEGIN TRY
	SET @tsql = 'IF NOT EXISTS (SELECT 1 FROM [' + @destdb + '].dbo.vHQBASReasonCodes) BEGIN ' +
			+ 'SET IDENTITY_INSERT [' + @destdb + '].dbo.vHQBASReasonCodes ON; '
			+ 'INSERT INTO [' + @destdb + '].dbo.vHQBASReasonCodes (ReasonCode,Reason,Notes,UniqueAttchID,KeyID) '
			+ 'SELECT ReasonCode,Reason,Notes,UniqueAttchID,KeyID '
			+ 'FROM ' + @SourceServer + '[' + @sourcedb + '].dbo.vHQBASReasonCodes '
			+ 'END'
	EXEC(@tsql)
END TRY 
BEGIN CATCH 
	IF @@TRANCOUNT <> 0
	BEGIN
		ROLLBACK
	END
	
	SET @msg = 'Error during update, cannot copy vHQBASReasonCodes.' 
		+ char(13)+ char(10) +  @tsql + char(13)+ char(10) + ERROR_MESSAGE()
		
	RAISERROR(@msg,15,1) 
	
	SET @rcode = 1
	RETURN (@rcode)
END CATCH

--handle my viewpoint non-customer facing messages
--vVPPartFormChangedParameters,vVPPartFormChangedMessages
BEGIN TRY
	--delete all under 1,000,000 over 1 mil is customer data
	SET @tsql =	 '	DELETE [' + @destdb + '].dbo.vVPPartFormChangedParameters WHERE KeyID < 1000000;
					DELETE [' + @destdb + '].dbo.vVPPartFormChangedMessages WHERE KeyID < 1000000;'
	EXEC (@tsql)
	-- readd those rows from our source DB
	SET @tsql = 'SET IDENTITY_INSERT [' + @destdb + '].dbo.vVPPartFormChangedMessages ON;
				 INSERT [' + @destdb + '].dbo.vVPPartFormChangedMessages(FormName,FormTitle,KeyID)
				 SELECT FormName,FormTitle,KeyID
				 FROM ' + @SourceServer + '[' + @sourcedb + '].dbo.vVPPartFormChangedMessages WHERE KeyID < 1000000;
				 SET IDENTITY_INSERT [' + @destdb + '].dbo.vVPPartFormChangedMessages OFF;'
	EXEC(@tsql)
	
	SET @tsql = 'SET IDENTITY_INSERT [' + @destdb + '].dbo.vVPPartFormChangedParameters ON;
				 INSERT [' + @destdb + '].dbo.vVPPartFormChangedParameters(KeyID,ColumnName,Name,SqlType,ParameterValue,ViewName,FormChangedID,ParameterOrder)
				 SELECT KeyID,ColumnName,Name,SqlType,ParameterValue,ViewName,FormChangedID,ParameterOrder
				 FROM ' + @SourceServer + '[' + @sourcedb + '].dbo.vVPPartFormChangedParameters WHERE KeyID < 1000000;
				 SET IDENTITY_INSERT [' + @destdb + '].dbo.vVPPartFormChangedParameters OFF;'
	EXEC(@tsql)
	
END TRY
BEGIN CATCH
	IF @@TRANCOUNT <> 0
	BEGIN
		ROLLBACK
	END
	
	SET @msg = 'Error during update, cannot copy vVPPartFormChangedParameters.' 
		+ char(13)+ char(10) +  @tsql + char(13)+ char(10) + ERROR_MESSAGE()
		
	RAISERROR(@msg,15,1) 
	
	SET @rcode = 1
	RETURN (@rcode)
END CATCH

-- issue 136482
-- adding call to remove custom meta data that no longer is valid  
DECLARE @ntsql nvarchar(MAX)
SET @ntsql = N'EXEC [' + @destdb + '].dbo.vspVPUpdaterDDFIOrphanedMetaDataFix' ;

EXECUTE sp_executesql 
    @ntsql;
 
goto vspexit

vsperror: -- problems with update
	select @msg = 'Error during update, unable to complete.' + char(13) + @tsql
	select @rcode = 1
		
vspexit:
	return
GO
GRANT EXECUTE ON  [dbo].[vspVPUpdater] TO [public]
GO
