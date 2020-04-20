CREATE TABLE [dbo].[vDDVS]
(
[LicenseLevel] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[UseAppRole] [dbo].[bYN] NOT NULL,
[AppRolePassword] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Version] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[DaysToKeepLogHistory] [smallint] NOT NULL,
[MaxLookupRows] [int] NOT NULL,
[MaxFilterRows] [int] NOT NULL,
[LoginMessage] [varchar] (1024) COLLATE Latin1_General_BIN NULL,
[LoginMessageActive] [char] (1) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_vDDVS_LoginMessageActive] DEFAULT ('N'),
[AnalysisServer] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CubesProcessed] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDVS_CubesProcessed] DEFAULT ('N'),
[ShowMyViewpoint] [dbo].[bYN] NULL,
[OLAPJobName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDDVS_OLAPJobName] DEFAULT ('OLAP_ProcessCube'),
[OLAPDatabaseName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDDVS_OLAPDatabaseName] DEFAULT ('Viewpoint OLAP'),
[ServicePack] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[FrameworkFilePath] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[AllowExportPrintRPRun] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDVS_AllowExportPrintRPRun] DEFAULT ('N'),
[OrganizationID] [uniqueidentifier] NULL,
[TaxUpdate] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[NumberOfWorkCenterTabs] [int] NULL,
[OnlyOneRow] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDDUP_OnlyOneRow] DEFAULT ('X'),
[SendViaSmtp] [dbo].[bYN] NOT NULL,
[FourProjectsApplicationId] [uniqueidentifier] NULL,
[FourProjectsUserName] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[FourProjectsPassword] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[FourProjectsEnterpriseName] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[FourProjectsEnterpriseId] [uniqueidentifier] NULL,
[FourProjectsBaseUrl] [varchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtDDVSd] on [dbo].[vDDVS] for delete 
/*-----------------------------------------------------------------
 *	Created: GG 06/10/05
 *	Modified:
 *
 *	This trigger adds DD Audit entry if the vDDVS (Viewpoint Security)
 *	record is deleted
 *
 */----------------------------------------------------------------

as



declare @errmsg varchar(255)
if @@rowcount = 0 return

set nocount on

-- DD Audit 
insert dbo.vDDDA (TableName, Action, KeyString, FieldName,
	OldValue, NewValue, RevDate, UserName, HostName)
select 'vDDVS', 'D', 'Viewpoint Security', null,
	null, null, getdate(), SUSER_SNAME(), host_name()
from deleted

return

-- error not used
error:
	select @errmsg = @errmsg + ' - cannot delete Viewpoint Security!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtDDVSi] on [dbo].[vDDVS] for INSERT
/*****************************
* Created: GG 06/10/05
* Modified: GG 09/13/06 - added MaxLookupRows and MaxFilterRows
*
* Insert trigger on vDDVS (DD Viewpoint Security)
*
* Rejects insert if the following conditions exist:
*	More than one row
*	Invalid UseAppRole flag 
*	Invalid DaysToKeepLogHistory
*
* Adds DD Audit entry
*
*************************************/

as


declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate # of rows
if @numrows <> 1
  	begin
  	select @errmsg = 'Only a single row can be added to vDDVS'
  	goto error
  	end
-- validate UseAppRole
if exists(select top 1 1 from inserted where UseAppRole <> 'Y' and UseAppRole <> 'N')
	begin
  	select @errmsg = 'Invalid UseAppRole - must be either "Y" or "N"'
  	goto error
  	end
-- validate DaysToKeepLogHistory
if exists(select top 1 1 from inserted where DaysToKeepLogHistory < 0)
	begin
	select @errmsg = 'Invalid DaysToKeepLogHistory - must be equal to or greater than 0'
	goto error
	end
-- validate MaxFilterRows
if exists(select top 1 1 from inserted where MaxFilterRows < 0)
	begin
	select @errmsg = 'Invalid MaxFilterRows - must be equal to or greater than 0'
	goto error
	end
-- validate MaxLookupRows
if exists(select top 1 1 from inserted where MaxLookupRows < 0)
	begin
	select @errmsg = 'Invalid MaxLookupRows - must be equal to or greater than 0'
	goto error
	end

-- DD Audit  
insert vDDDA (TableName, Action, KeyString, FieldName, OldValue, 
  	NewValue, RevDate, UserName, HostName)
select 'vDDVS', 'I', 'Viewpoint Security', null, null,
	null, getdate(), SUSER_SNAME(), host_name()
from inserted 

return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Viewpoint Security!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtDDVSu] on [dbo].[vDDVS] for UPDATE 
/*-----------------------------------------------------------------
 * 	Created: GG 06/10/05
 *	Modified: GG 09/13/06 - added MaxLookupRows and MaxFilterRows
 *			RM 09/02/2010 - Added auditing for UseRecordingFramework,RecordUsage,ContinuousRecording
 *			RM 09/08/2010 - Added auditing into HQMA also, since customer has no access to DDDA
 *			PW 09/21/2012 - Removed Recording Framwork columns
 *
 *	This trigger rejects update in vDDVS (Viewpoint Security) if the
 *	following error condition exists:
 *
 *		Invalid UseAppRole
 *		Invalid DaysToKeepLogHistory
 *
 * Adds DD Audit entries for changed values
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate UseAppRole
if update(UseAppRole)
	begin
	if exists(select top 1 1 from inserted where UseAppRole <> 'Y' and UseAppRole <> 'N')
		begin
  		select @errmsg = 'Invalid UseAppRole - must be "Y" or "N"'
  		goto error
  		end
	end

-- validate DaysToKeepLogHistory
if update(DaysToKeepLogHistory)
	begin
	if exists(select top 1 1 from inserted where DaysToKeepLogHistory < 0)
		begin
  		select @errmsg = 'Invalid DaysToKeepLogHistory - must be equal to or greater than 0'
  		goto error
  		end
	end
-- validate MaxLookupRows
if update(MaxLookupRows)
	begin
	if exists(select top 1 1 from inserted where MaxLookupRows < 0)
		begin
  		select @errmsg = 'Invalid MaxLookupRows - must be equal to or greater than 0'
  		goto error
  		end
	end
-- validate MaxFilterRows
if update(MaxFilterRows)
	begin
	if exists(select top 1 1 from inserted where MaxFilterRows < 0)
		begin
  		select @errmsg = 'Invalid MaxFilterRows - must be equal to or greater than 0'
  		goto error
  		end
	end

-- DD Audit
if update(LicenseLevel)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDVS', 'U', 'Viewpoint Security', 'LicenseLevel',
		d.LicenseLevel, i.LicenseLevel, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on 1 = 1		-- required because no index to join on
  	where i.LicenseLevel <> d.LicenseLevel
if update(UseAppRole)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDVS', 'U', 'Viewpoint Security', 'UseAppRole',
		d.UseAppRole, i.UseAppRole, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on 1 = 1
  	where i.UseAppRole <> d.UseAppRole
if update(AppRolePassword)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDVS', 'U', 'Viewpoint Security', 'AppRolePassword',
		d.AppRolePassword, i.AppRolePassword, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on 1 = 1
  	where isnull(i.AppRolePassword,'') <> isnull(d.AppRolePassword,'')
if update(Version)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDVS', 'U', 'Viewpoint Security', 'Version',
		d.Version, i.Version, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on 1 = 1
  	where isnull(i.Version,'') <> isnull(d.Version,'')
if update(DaysToKeepLogHistory)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDVS', 'U', 'Viewpoint Security', 'DaysToKeepLogHistory',
		d.DaysToKeepLogHistory, i.DaysToKeepLogHistory, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on 1 = 1		
  	where i.DaysToKeepLogHistory <> d.DaysToKeepLogHistory
if update(MaxLookupRows)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDVS', 'U', 'Viewpoint Security', 'MaxLookupRows',
		d.MaxLookupRows, i.MaxLookupRows, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on 1 = 1
  	where i.MaxLookupRows <> d.MaxLookupRows
if update(MaxFilterRows)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDVS', 'U', 'Viewpoint Security', 'MaxFilterRows',
		d.MaxFilterRows, i.MaxFilterRows, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on 1 = 1
  	where i.MaxFilterRows <> d.MaxFilterRows
  	
return

error:
    select @errmsg = @errmsg + ' - cannot update Viewpoint Security!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction





GO
ALTER TABLE [dbo].[vDDVS] WITH NOCHECK ADD CONSTRAINT [CK_vDDVS_OnlyOneRow] CHECK (([OnlyOneRow]='X'))
GO
ALTER TABLE [dbo].[vDDVS] WITH NOCHECK ADD CONSTRAINT [CK_vDDVS_UseAppRole] CHECK (([UseAppRole]='Y' OR [UseAppRole]='N'))
GO
ALTER TABLE [dbo].[vDDVS] ADD CONSTRAINT [PK_vDDVS] PRIMARY KEY CLUSTERED  ([OnlyOneRow]) ON [PRIMARY]
GO
