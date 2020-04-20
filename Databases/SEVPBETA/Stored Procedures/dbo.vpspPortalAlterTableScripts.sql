SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE [dbo].[vpspPortalAlterTableScripts]
(
	@ServerName as varchar(100)
)
AS

DECLARE
		@SQLString as varchar(1000),
		@ExecuteString as nvarchar(1000)

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pStyleProperties ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pStyleProperties_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pPortalControls ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pPortalControls_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pAttachmentTypes ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pAttachmentTypes_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pContactTypes ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pContactTypes_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pMenuTemplateLinkRoles ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pMenuTemplateLinkRoles_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pMenuTemplateLinks ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pMenuTemplateLinks_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pMenuTemplates ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pMenuTemplates_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pPageTemplateControls ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pPageTemplateControls_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pPageTemplateControlSecurity ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pPageTemplateControlSecurity_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pPageTemplates ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pPageTemplates_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pPortalControlSecurityTemplate ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pPortalControlSecurityTemplate_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'ALTER TABLE ' + @ServerName + '.dbo.pRoles ADD
	ClientModified bit NOT NULL CONSTRAINT DF_pRoles_ClientModified DEFAULT 0'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString





GO
GRANT EXECUTE ON  [dbo].[vpspPortalAlterTableScripts] TO [VCSPortal]
GO
