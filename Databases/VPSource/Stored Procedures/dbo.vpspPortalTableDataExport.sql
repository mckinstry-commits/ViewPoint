SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE      procedure [dbo].[vpspPortalTableDataExport]
(
	@ServerName as varchar(100),
	@Filepath as varchar(100),
    @User as varchar(100),
    @Password as varchar(100)
)
AS

DECLARE @Name varchar(1000)

--Export the data for the Portal 'DD' type tables
SET @Name = @ServerName + '.dbo.pLinkTypes'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

--SET @Name = @ServerName + '.dbo.pStyleProperties'
--exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalStoredProcedures'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalStoredProcedureParameters'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalMessages'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalHTMLTables'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalDetailsFieldLookup'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalDetailsField'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalDetails'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalDataGridColumns'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalDataGrid'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalDataFormat'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalControls'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalControlLayout'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalControlButtons'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalButtons'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pLookups'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pLookupColumns'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

--Export the data for the Portal 'Template' type tables
SET @Name = @ServerName + '.dbo.pAttachmentTypes'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pContactTypes'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pMenuTemplateLinkRoles'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pMenuTemplateLinks'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pMenuTemplates'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPageTemplateControls'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPageTemplateControlSecurity'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPageTemplates'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPortalControlSecurityTemplate'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pRoles'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pPasswordRules'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

SET @Name = @ServerName + '.dbo.pLinkTypes'
exec vpspPortalExportBCP @Name, @Filepath, @User, @Password

GO
GRANT EXECUTE ON  [dbo].[vpspPortalTableDataExport] TO [VCSPortal]
GO
