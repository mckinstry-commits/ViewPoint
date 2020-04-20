SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE        PROCEDURE [dbo].[vpspPortalTableDataImport]
/********************************
* Created: Jeremiah Barley
* Modified: Tom J -2/17/2009 - Added Portal License Types to the equation
			Adam R 3/21/2011 - 142200 adding brackets for weird DB names
			Adam R 10/26/2011 - buiding list and loop through tables for FKs and Trigger functions
			Gene Y 12/08/2011 - Merge Code from pConnectsDirectoryBrowser.sql  This script cannot be a post script due to 
								this metadata script and must be here because of proc calls and drop call scripts that munge
								the pPortalControlInsert table.
			Tom J  01/10/2012 - Modified how we clean up old Directory Browser settings.
			JayR   10/31/2012 - We need to disable more triggers so that we do not blow out the audit table.
*           JayR 2013-03-13  Add an additional parameter of SourceServer so we can cross DB Links
*
* Import/Synchronize the Connects data from a source database to a target database.
* Returns a 0 if successful, any other number indicates failure.  Flip the debug flag 
* turn useful debugging messages on.
*
* Parameters: 
*   @SourceDB:		The database name to copy data from.	
	@TargetDB:		The database name to copy data to.
*
*
*********************************/


    (
      @SourceDB VARCHAR(100),
      @SourceServer VARCHAR(100) = '',
      @TargetDB VARCHAR(100),
      @rcode INT OUTPUT,
      @msg VARCHAR(5000) OUTPUT
    )
AS 

/***********************************************************
*	Merging pConnectsDirectoryBrowser
*	Created:  Joe AmRhein 11/29/2011
*	Description:  TK-10391 Created scripts to replace Directory Browser control with File Browser
*	Modified: Tom J - 12/02/2011, TK-00000 Script cleanup
*			  Gene Yoo - 12/05/2011, TK-00000 fix upgrade errors of initial check to check off the ID instead of the name, and add this header
*			  Gene Yoo - 12/07/2011, D-03893 - Fix upgrade error because 'Title' column in pPageSiteControls doesn't exist in 6.3.1 sp4 - code reviewed by Adam R.
*	
************************************************************/
DECLARE @fbPageTemplateID int
DECLARE @fbPortalControlID int
DECLARE @dbPortalControlID int
DECLARE @dbPageTemplateID int

SET @fbPageTemplateID = 727			
SET @fbPortalControlID = 610	
SET @SourceServer = [dbo].[vfFormatServerName](@SourceServer);

IF NOT EXISTS (SELECT 1 FROM pPortalControls where PortalControlID = @fbPortalControlID )
BEGIN
	SET IDENTITY_INSERT [dbo].[pPortalControls] ON
	INSERT [dbo].[pPortalControls] ([PortalControlID], [Name], [Description], [ChildControl], [Path], [Notes], [Status], [Help], 
		   [ClientModified], [PrimaryTable]) 
	VALUES (@fbPortalControlID, N'File Browser', N'File management control for the upload, browsing and sharing of files.', 0, 
			N'~/Controls/PortalControls/Files/PCFileManagement.ascx', NULL, 0, N'', 1, NULL)
	SET IDENTITY_INSERT [dbo].[pPortalControls] OFF
END


IF NOT EXISTS (SELECT 1 FROM pPageTemplates where PageTemplateID = @fbPageTemplateID )
BEGIN
	SET IDENTITY_INSERT pPageTemplates ON		
	INSERT INTO pPageTemplates(PageTemplateID, RoleID, PatriarchID, AvailableToMenu, Name, Description, Notes) 
	VALUES (@fbPageTemplateID, 1, NULL, 1, N'File Browser', N'File management control for the upload, browsing and sharing of files.', NULL);		
	SET IDENTITY_INSERT pPageTemplates OFF
			
	EXEC	[vpspPageTemplateControlsInsert]
			@PageTemplateID = @fbPageTemplateID,
			@PortalControlID = @fbPortalControlID,
			@ControlPosition = 2,
			@ControlIndex = 1,
			@RoleID = 0,
			@HeaderText = NULL
END

SET @dbPageTemplateID = 505			
SET @dbPortalControlID = 357

IF (	
		@fbPageTemplateID IS NOT NULL AND
		@fbPortalControlID IS NOT NULL AND
		@dbPageTemplateID IS NOT NULL AND
		@dbPortalControlID IS NOT NULL
	)
BEGIN
	--change all existing portal control instances from directory browser to file browser
	UPDATE pPageSiteControls
	SET PortalControlID = @fbPortalControlID
	WHERE PortalControlID = @dbPortalControlID

	--change overridden titles to use default control name
	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'pPageSiteControls' AND COLUMN_NAME = N'Title')
	BEGIN
		EXEC 
			('
				UPDATE pPageSiteControls
				SET Title = NULL
				WHERE Title = ''Directory Browser''
			')
	END

	--change overridden headertext to use default control text
	UPDATE pPageSiteControls
	SET HeaderText = NULL
	WHERE HeaderText = 'Directory Browser'

	--change all templates to use File Browser template
	UPDATE pMenuTemplateLinks
	SET PageTemplateID = @fbPageTemplateID
	WHERE Caption like '%File%'

	-- If they haven't renamed the Directory Browser we will rename it as well as setting the new PageTemplateID
	UPDATE pPageSiteTemplates
	   SET  PageTemplateID = @fbPageTemplateID, 
			Name = 'File Browser', 
			Description = 'File management control for the upload, browsing and sharing of files.'
	WHERE PageTemplateID = @dbPageTemplateID AND Name = 'Directory Browser'

	-- The ones that haven't renamed it we'll just reset the Description and the PageTemplateID
	UPDATE pPageSiteTemplates
	   SET  PageTemplateID = @fbPageTemplateID, 
	   Description = 'File management control for the upload, browsing and sharing of files.'
	WHERE PageTemplateID = @dbPageTemplateID 
END




    DECLARE @Name VARCHAR(100),
        @SQLString VARCHAR(1000),
        @ExecuteString NVARCHAR(1000),
        @Debug BIT,
        @ListOfTabs VARCHAR(MAX),
        @TabName VARCHAR(128)

	-- Set to 0 for no comments, 1 to print comments
    SET @Debug = 0;
		
	-- Disable the Triggers on all template tables so modified flags aren't fired
    BEGIN TRY
        IF ( @Debug = 1 ) 
            PRINT 'Section 1: Disabling Triggers...'
	
        SET @ListOfTabs = 'pPortalControls,pLookups,pAttachmentTypes,pContactTypes,pMenuTemplateLinkRoles,'
            + 'pMenuTemplateLinks,pMenuTemplates,pPageTemplateControls,pPageTemplateControlSecurity,'
            + 'pPageTemplates,pPortalControlSecurityTemplate,pRoles,pPortalDataGridColumnsLookup,'
            + 'pDates,pLinkTypes,pReportControls,pReportParametersPortalControl,pReportPortalControlSecurity,'
            + 'pReportSecurity,pPortalDataGrid,pLookupColumns,pPortalDataGrid,pPortalHTMLTables,'
            + 'pPortalDataGridColumnsCustom,pReportViewerControl,'
            + 'pPortalControlLicenseType,pPortalDetails,pPortalStoredProcedures,'  --We need to turn more triggers off
            + 'pPortalDetailsFieldLookup,pPortalStoredProcedureParameters,'
            + 'pPortalControlButtons,pPortalDataGridColumns,pPortalDetailsField'
	
        DECLARE @TriggerTab TABLE ( TabName VARCHAR(128) )
		
        INSERT  INTO @TriggerTab
                ( TabName
                )
                SELECT  [Names]
                FROM    dbo.vfTableFromArray(@ListOfTabs)
		
        DECLARE cDTrg CURSOR FAST_FORWARD
        FOR
            SELECT  TabName
            FROM    @TriggerTab AS tt
		
        OPEN cDTrg	
        FETCH NEXT FROM cDTrg INTO @TabName
		
        WHILE @@FETCH_STATUS = 0 
            BEGIN
                SET @SQLString = 'ALTER TABLE ' + QUOTENAME(@TargetDB)
                    + '.dbo.' + QUOTENAME(@TabName) + ' DISABLE TRIGGER ALL'
                SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
                EXEC sp_executesql @ExecuteString
                EXEC (@TargetDB+'.dbo.vspDisableForeignKeyOnTable '+ @TabName + ', 0')
			
                FETCH NEXT FROM cDTrg INTO @TabName
            END
		
        CLOSE cDTrg
        DEALLOCATE cDTrg
		
        IF ( @Debug = 1 ) 
            PRINT 'Section 1: Complete.'
    END TRY
    BEGIN CATCH
        SET @msg = 'Error Disabling Triggers and FKs'
        SET @rcode = -1
        IF ( @Debug = 1 ) 
            SET @msg = @msg + ' - ' + ERROR_NUMBER() + ': ' + ERROR_MESSAGE()
        SELECT  @rcode,
                @msg
        CLOSE cDTrg
        DEALLOCATE cDTrg
        RETURN
    END CATCH

	---------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------

	-- Empty the Tables that we can completely empty
    BEGIN TRY
        IF ( @Debug = 1 ) 
            PRINT 'Section 2: Deleting Data From Tables...'
		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalControlButtons'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalControlButtons'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalButtons'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalButtons'

        SET @SQLString = 'TRUNCATE TABLE ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalControlLayout'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalControlLayout'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalHTMLTables'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalHTMLTables'

        SET @SQLString = 'TRUNCATE TABLE ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalDetailsFieldLookup'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalDetailsFieldLookup'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalDetailsField'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalDetailsField'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalDetails'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalDetails'

        SET @SQLString = 'UPDATE ' + QUOTENAME(@TargetDB)
            + '.dbo.pLookups SET DefaultSortID = NULL, ReturnColumnID = NULL, DisplayColumnID = NULL'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pLookupColumns'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pLookupColumns'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pLookups'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pLookups'	

        SET @SQLString = 'UPDATE ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalDataGrid SET IDColumn = NULL, DefaultSortID = NULL'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalDataGridColumns'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalDataGridColumns'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalDataGrid'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalDataGrid'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalStoredProcedureParameters'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalStoredProcedureParameters'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalStoredProcedures'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalStoredProcedures'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalMessages'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: pPortalMessages'

        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalDataFormat'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalDataFormat'

		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalDataGridColumnsLookup'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalDataGridColumnsLookup'
		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB) + '.dbo.pDates'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pDates'
		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pReportControls'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pReportControls'
		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pReportParametersPortalControl'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pReportParametersPortalControl'
		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pReportPortalControlSecurity'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pReportPortalControlSecurity'
		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pReportSecurity'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pReportSecurity'
		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalControls'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalControls'
		
        SET @SQLString = 'DELETE FROM ' + QUOTENAME(@TargetDB)
            + '.dbo.pPortalControlLicenseType'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString
        IF ( @Debug = 1 ) 
            PRINT 'Delete Complete: pPortalControlLicenseType'
		
		
        IF ( @Debug = 1 ) 
            PRINT 'Section 2 Complete.'
    END TRY
    BEGIN CATCH
        SET @msg = 'Error Removing Existing Data' + ERROR_MESSAGE()
        SET @rcode = -1
        IF ( @Debug = 1 ) 
            SET @msg = @msg + ' - ' + ERROR_NUMBER() + ': ' + ERROR_MESSAGE()
        SELECT  @rcode,
                @msg
        RETURN
    END CATCH

	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------


	-- Synchronize data (Update existing rows and Insert new rows from source)
    BEGIN TRY
        IF ( @Debug = 1 ) 
            PRINT 'Section 3: Synchronizing Tables'
		
        SET @Name = 'pPortalControls'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'PortalControlID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pDates'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name, 'DateID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalDataFormat'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'DataFormatID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalMessages'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name, 'MessageID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalStoredProcedures'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'StoredProcedureID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name

        SET @Name = 'pPortalStoredProcedureParameters'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'ParameterID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalDataGrid'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'DataGridID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalDataGridColumns'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'DataGridColumnID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name

        SET @Name = 'pPortalDataGridColumnsLookup'
        EXEC vpspPortalImportDataNonIdentity @SourceDB, @SourceServer, @Name
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalDetails'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name, 'DetailsID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalDetailsField'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'DetailsFieldID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalDetailsFieldLookup'
        EXEC vpspPortalImportDataNonIdentity @SourceDB, @SourceServer, @Name
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalHTMLTables'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'HTMLTableID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalControlLayout'
        EXEC vpspPortalImportDataNonIdentity @SourceDB, @SourceServer, @Name
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name

        SET @Name = 'pLinkTypes'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'LinkTypeID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalButtons'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name, 'ButtonID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalControlButtons'
        EXEC vpspPortalImportDataNonIdentity @SourceDB, @SourceServer, @Name
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pLookups'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name, 'LookupID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pLookupColumns'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'LookupColumnID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPageTemplates'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'PageTemplateID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPageTemplateControls'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'PageTemplateControlID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pMenuTemplates'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'MenuTemplateID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pReportControls'
        EXEC vpspPortalImportDataNonIdentity @SourceDB, @SourceServer, @Name
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name

        SET @Name = 'pReportParametersPortalControl'
        EXEC vpspPortalImportDataNonIdentity @SourceDB, @SourceServer, @Name
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name

        SET @Name = 'pReportPortalControlSecurity'
        EXEC vpspPortalImportDataNonIdentity @SourceDB, @SourceServer, @Name
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name

        SET @Name = 'pReportSecurity'
        EXEC vpspPortalImportDataNonIdentity @SourceDB, @SourceServer, @Name
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name

        SET @Name = 'pPortalControlLicenseType'
        EXEC vpspPortalImportDataNonIdentity @SourceDB, @SourceServer, @Name
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name	
			
		--------------------------------------------------------
		---- Synch tables that have unique key fields.
        SET @Name = 'pAttachmentTypes'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'AttachmentTypeID', '[Name]'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pContactTypes'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name,
            'ContactTypeID', '[Name]'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pRoles'
        EXEC vpspPortalTableDataSynch @SourceDB, @SourceServer, @TargetDB, @Name, 'RoleID',
            '[Name]'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
		--------------------------------------------------------
		---- Synch tables that use multi part keys
		
        SET @Name = 'pMenuTemplateLinks'
        EXEC vpspPortalTableDataSynchMultiKey @SourceDB, @SourceServer, @TargetDB, @Name,
            'MenuTemplateLinkID', 'MenuTemplateID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pMenuTemplateLinkRoles'
        EXEC vpspPortalTableDataSynchMultiKey @SourceDB, @SourceServer, @TargetDB, @Name,
            'MenuTemplateLinkID', 'MenuTemplateID', 'RoleID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPortalControlSecurityTemplate'
        EXEC vpspPortalTableDataSynchMultiKey @SourceDB, @SourceServer, @TargetDB, @Name,
            'PortalControlID', 'RoleID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        SET @Name = 'pPageTemplateControlSecurity'
        EXEC vpspPortalTableDataSynchMultiKey @SourceDB, @SourceServer, @TargetDB, @Name,
            'PageTemplateControlID', 'RoleID'
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
		--------------------------------------------------------
		---- Synch pLicenseType table - this is a special handler so we don't blow out the assigned license counts
		---- but make sure the checksums and names get properly updated.
        SET @Name = 'pLicenseType'
        SET @SQLString = 'UPDATE ' + QUOTENAME(@TargetDB) + '.[dbo].' + @Name
            + ' SET LicenseType = s.LicenseType, LicenseChecksum=s.LicenseChecksum'
            + ' FROM ' + QUOTENAME(@TargetDB) + '.[dbo].' + @Name + ' d'
            + ' INNER JOIN ' + @SourceServer + QUOTENAME(@SourceDB) + '.[dbo].' + @Name + ' s'
            + ' ON s.LicenseTypeID = d.LicenseTypeID'
        SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
        EXEC sp_executesql @ExecuteString 
        IF ( @Debug = 1 ) 
            PRINT 'Synch Complete: ' + @Name
		
        IF ( @Debug = 1 ) 
            PRINT 'Section 3: Complete.'
    END TRY
    BEGIN CATCH
        SET @msg = 'Error Importing Data vpspPortalTableDataImport:'
        SET @rcode = -1
        IF ( @Debug = 1 ) 
            SET @msg = @msg + ' - ' + ERROR_NUMBER() + ': ' + ERROR_MESSAGE()
        SELECT  @rcode,
                @msg
        RETURN
    END CATCH


	-- Enable the Triggers on all template tables
    BEGIN TRY
        IF ( @Debug = 1 ) 
            PRINT 'Section 4: Enabling Triggers.'
		
        DECLARE cETrg CURSOR FAST_FORWARD
        FOR
            SELECT  TabName
            FROM    @TriggerTab AS tt
		
        OPEN cETrg	
        FETCH NEXT FROM cETrg INTO @TabName
		
        WHILE @@FETCH_STATUS = 0 
            BEGIN
                SET @SQLString = 'ALTER TABLE ' + QUOTENAME(@TargetDB)
                    + '.dbo.' + QUOTENAME(@TabName) + ' ENABLE TRIGGER ALL'
                SELECT  @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
                EXEC sp_executesql @ExecuteString
                  EXEC (@TargetDB+'.dbo.vspDisableForeignKeyOnTable '+ @TabName + ', 1')
			
                FETCH NEXT FROM cETrg INTO @TabName
            END
		
        CLOSE cETrg
        DEALLOCATE cETrg
		
        IF ( @Debug = 1 ) 
            PRINT 'Section 4: Complete.'
    END TRY
    BEGIN CATCH
        SET @msg = 'Error Enabling Triggers'
        SET @rcode = -1
        SET @msg = @msg + ' - ' + ERROR_NUMBER() + ': ' + ERROR_MESSAGE()
        SELECT  @rcode,
                @msg
        IF @@TRANCOUNT <> 0 
            BEGIN
                ROLLBACK TRAN
            END
        CLOSE cETrg
        DEALLOCATE cETrg
        RETURN
    END CATCH

GO
GRANT EXECUTE ON  [dbo].[vpspPortalTableDataImport] TO [VCSPortal]
GO
