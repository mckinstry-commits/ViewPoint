SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspPortalTemplateReseed]
/********************************
* Created: George Clingerman
* Modified: Tim Stevens - 01/20/2009
*
* Used by VPUpdate to prepare tables for importing metadata for VP Connects
*
* Input: 
*	@destdb - Database where will be configuring VP Connects product
*
* Output:
*	@msg		
*
* Return code:
* @rcode - anything except 0 indicates an error
*
*********************************/
(
	@destdb varchar(100),
	@rcode int output,
	@msg varchar(500) output
)
AS

DECLARE @SQLString varchar(1000), 
		@ExecuteString NVARCHAR(1000)
		


--SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pStyleProperties'', RESEED, 50000)'
--Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
--exec sp_executesql @ExecuteString

--SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pStyleProperties'', RESEED)'
--Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
--exec sp_executesql @ExecuteString

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pPortalControls'', RESEED, 50000)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pPortalControls'', RESEED)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pAttachmentTypes'', RESEED, 50000)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pAttachmentTypes'', RESEED)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pContactTypes'', RESEED, 50000)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pContactTypes'', RESEED)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pMenuTemplates'', RESEED, 50000)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pMenuTemplates'', RESEED)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pPageTemplateControls'', RESEED, 50000)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pPageTemplateControls'', RESEED)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pPageTemplates'', RESEED, 50000)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pPageTemplates'', RESEED)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pRoles'', RESEED, 50000)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

SET @SQLString = 'DBCC CHECKIDENT(''' + @destdb + '.dbo.pRoles'', RESEED)'
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString
if @@error <> 0 goto vsperror

-- No problems - normal exit
set @rcode = 0
set @msg = ''
goto vspexit

vsperror: -- problems with SQL execution 
	select @msg = 'Error during update, unable to complete.' + char(13) + @ExecuteString
	select @rcode = 1
		

vspexit: 
	select @rcode, @msg
	return





GO
GRANT EXECUTE ON  [dbo].[vpspPortalTemplateReseed] TO [VCSPortal]
GO
