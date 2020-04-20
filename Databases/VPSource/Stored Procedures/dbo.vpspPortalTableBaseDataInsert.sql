SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************
* Created: Jeremiah Barley
* Modified: Chris G 6/7/12 - TK-15500 | D-05228 - Removed pUsers copy and moved to 
*												  Data\dbo.pUsers.sql (see that file for details).
*
*
* Description: fks must be dropped and re-added
*
* Parameters: 
*   @SourceDB:		The database name to copy data from.	
	@TargetDB:		The database name to copy data to.
*
*
*********************************/
CREATE PROCEDURE [dbo].[vpspPortalTableBaseDataInsert]
(
	@SourceDB VARCHAR(100),
	@TargetDB VARCHAR(100),
	@rcode INT OUTPUT,
	@msg VARCHAR(5000) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @Name VARCHAR(100),
		@SQLString VARCHAR(1000),
		@ExecuteString NVARCHAR(1000),
		@Debug BIT
		
	-- Set to 0 for no comments, 1 to print comments
	SET @Debug = 1
		
	BEGIN TRY
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pUsers', -- sysname
											@Enable = 0 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pSites', -- sysname
											@Enable = 0 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pPageSiteControls', -- sysname
											@Enable = 0 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pPageSiteControlSecurity', -- sysname
											@Enable = 0 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pPageSiteTemplates', -- sysname
											@Enable = 0 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pMenuSiteLinks', -- sysname
											@Enable = 0 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pMenuSiteLinkRoles', -- sysname
											@Enable = 0 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pContacts', -- sysname
											@Enable = 0 -- bit	
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pLinkControl', -- sysname
											@Enable = 0 -- bit	
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pSiteAttachments', -- sysname
											@Enable = 0 -- bit	
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pSiteAttachmentBinaries', -- sysname
											@Enable = 0 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pSiteFooterLinks', -- sysname
											@Enable = 0 -- bit																
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pPasswordRules', -- sysname
											@Enable = 0 -- bit
																										
											
		IF (@Debug = 1) PRINT 'Copying Base Portal Data (5.x to 6.x).'	
		
		SET @Name = 'pSites'
		EXEC vpspPortalTableDataSynchByValue @SourceDB, @TargetDB, @Name, 'SiteID', 'SiteID', '0'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		SET @Name = 'pPageSiteControls'
		EXEC vpspPortalTableDataSynchByValue @SourceDB, @TargetDB, @Name, 'PageSiteControlID', 'SiteID', '0'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		SET @Name = 'pPageSiteControlSecurity'
		EXEC vpspPortalTableDataSynchMultiKeyByValue @SourceDB, @TargetDB, @Name, 'SiteID', '0', 'PageSiteControlID', 'RoleID'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		SET @Name = 'pPageSiteTemplates'
		EXEC vpspPortalTableDataSynchByValue @SourceDB, @TargetDB, @Name, 'PageSiteTemplateID', 'SiteID', '0'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		SET @Name = 'pMenuSiteLinks'
		EXEC vpspPortalTableDataSynchByValue @SourceDB, @TargetDB, @Name, 'MenuSiteLinkID', 'SiteID', '0'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		SET @Name = 'pMenuSiteLinkRoles'
		EXEC vpspPortalTableDataSynchMultiKeyByValue @SourceDB, @TargetDB, @Name, 'SiteID', '0', 'MenuSiteLinkID', 'SiteID', 'RoleID'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		SET @Name = 'pContacts'
		EXEC vpspPortalTableDataSynchByValue @SourceDB, @TargetDB, @Name, 'ContactID', 'SiteID', '0'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		SET @Name = 'pLinkControl'
		EXEC vpspPortalTableDataSynchByValue @SourceDB, @TargetDB, @Name, 'LinkControlID', 'SiteID', '0'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		SET @Name = 'pSiteAttachments'
		EXEC vpspPortalTableDataSynchByValue @SourceDB, @TargetDB, @Name, 'SiteAttachmentID', 'SiteID', '0'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		

		-- Search for and insert attachment binaries
		SET @Name = 'pSiteAttachmentBinaries'
		SET @SQLString = 'INSERT INTO ' + @TargetDB + '.[dbo].' + @Name
		+ ' ([SiteAttachmentID], [Type], [Data])'
		+ ' (SELECT [SiteAttachmentID], [Type], [Data]'
		+ ' FROM ' + @SourceDB + '.[dbo].' + @Name + ' s'
		+ ' WHERE s.[SiteAttachmentID] IN (SELECT [SiteAttachmentID]'
		+ ' FROM ' + @SourceDB + '.[dbo].[pSiteAttachments]'
		+ ' WHERE SiteID = 0) AND s.[SiteAttachmentID]'
		+ ' NOT IN (SELECT [SiteAttachmentID] FROM ' + @TargetDB 
		+ '.[dbo].' + @Name + '));'
		
		SELECT @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
		EXEC sp_executesql @ExecuteString
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
	
		SET @Name = 'pSiteFooterLinks'
		EXEC vpspPortalTableDataSynchByValue @SourceDB, @TargetDB, @Name, 'SiteFooterLinkID', 'SiteID', '0'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		
		SET @Name = 'pPasswordRules'
		EXEC vpspPortalTableDataSynchByValue @SourceDB, @TargetDB, @Name, 'PasswordRuleID', 'PasswordRuleID', '1'
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		-- Search for and insert directory browser stuff...
		SET @Name = 'pDirectoryBrowser'
		SET @SQLString = 'INSERT INTO ' + @TargetDB + '.[dbo].' + @Name
		+ ' ([PageSiteControlID], [Directory])'
		+ ' (SELECT [PageSiteControlID], [Directory]'
		+ ' FROM ' + @SourceDB + '.[dbo].' + @Name + ' s'
		+ ' WHERE s.[PageSiteControlID] IN (SELECT [PageSiteControlID]'
		+ ' FROM ' + @SourceDB + '.[dbo].[pPageSiteControls]'
		+ ' WHERE SiteID = 0) AND s.[PageSiteControlID]'
		+ ' NOT IN (SELECT [PageSiteControlID] FROM ' + @TargetDB 
		+ '.[dbo].' + @Name + '));'
		
		SELECT @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
		EXEC sp_executesql @ExecuteString
		IF (@Debug = 1) PRINT 'Synch Complete: ' + @Name
		
		IF (@Debug = 1) PRINT 'Copying Base Portal Data Complete.'
		-- set output var for the app
		SET @rcode = 0
		
			EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pUsers', -- sysname
											@Enable = 1 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pSites', -- sysname
											@Enable = 1 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pPageSiteControls', -- sysname
											@Enable = 1 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pPageSiteControlSecurity', -- sysname
											@Enable = 1 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pPageSiteTemplates', -- sysname
											@Enable = 1 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pMenuSiteLinks', -- sysname
											@Enable = 1 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pMenuSiteLinkRoles', -- sysname
											@Enable = 1 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pContacts', -- sysname
											@Enable = 1 -- bit	
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pLinkControl', -- sysname
											@Enable = 1 -- bit	
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pSiteAttachments', -- sysname
											@Enable = 1 -- bit	
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pSiteAttachmentBinaries', -- sysname
											@Enable = 1 -- bit
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pSiteFooterLinks', -- sysname
											@Enable = 1 -- bit																
		EXEC dbo.vspDisableForeignKeyOnTable @TableName = 'pPasswordRules', -- sysname
											@Enable = 1 -- bit
	END TRY
	BEGIN CATCH
		SET @msg = 'Error Copying Base Data'
		SET @rcode = -1
		IF (@Debug = 1) SET @msg = @msg + ' - ' + CONVERT(varchar(10),ERROR_NUMBER()) + ': ' + ERROR_MESSAGE()
		SELECT @rcode, @msg
		RETURN
	END CATCH
END




GO
GRANT EXECUTE ON  [dbo].[vpspPortalTableBaseDataInsert] TO [VCSPortal]
GO
