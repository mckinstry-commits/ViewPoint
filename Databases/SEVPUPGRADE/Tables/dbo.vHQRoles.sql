CREATE TABLE [dbo].[vHQRoles]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Role] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Active] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vHQRoles_Active] DEFAULT ('Y'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[UsableInPC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRoles_UsableInPC] DEFAULT ('Y'),
[UsableInPM] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRoles_UsableInPM] DEFAULT ('Y'),
[UsableInSM] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRoles_UsableInSM] DEFAULT ('Y')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/*********************************************/
CREATE trigger [dbo].[btHQRolesd] on [dbo].[vHQRoles] for DELETE as
/*----------------------------------------------------------
* Created By:	GF 11/15/2009 - issue #135527
* Modified By:
*
*
*
* This trigger rejects delete in vHQRoles if a dependent
* record is found in vJCJobRoles.
*
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/* check vJCJobRoles */
if exists(select top 1 1 from dbo.vJCJobRoles j with (nolock) join deleted d on d.Role = j.Role)
	begin
	select @errmsg = 'Role is assigned to a job in Job Cost.'
	goto error
	end



---- Audit HQ Company deletions
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vHQRoles', 'HQ Role: ' + d.Role, null, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted d



return

error:
	select @errmsg = @errmsg + ' - cannot delete HQ Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQRolesi] on [dbo].[vHQRoles] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GF 11/15/2009 - issue #135527
* Modified By:
*
*
* This trigger audits insertion in vHQRoles
*
*
* Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vHQRoles', 'HQ Role: ' + i.Role, null, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted i


return

error:
	select @errmsg = @errmsg + ' - cannot insert HQ Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************/
CREATE trigger [dbo].[btHQRolesu] on [dbo].[vHQRoles] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	GF 11/15/2009 - issue #135527
* Modified By:
*
* No current error checks for update.	
*
* Adds records to HQ Master Audit.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int,
		@hqco bCompany, @name varchar(60), @oldname varchar(60)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


/* always update HQ Master Audit */
if update(Description)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vHQRoles', 'HQ Role: ' + i.Role, null, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.Role = d.Role
   	where isnull(i.Description,'') <> isnull(d.Description,'')
   	end
if update(Active)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vHQRoles', 'HQ Role: ' + i.Role, null, 'C', 'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.Role = d.Role
   	where isnull(i.Active,'') <> isnull(d.Active,'')
	end


return

error:
   	select @errmsg = @errmsg + ' - cannot update HQ Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
ALTER TABLE [dbo].[vHQRoles] ADD CONSTRAINT [CK_vHQRoles_Active] CHECK (([Active]='N' OR [Active]='Y'))
GO
ALTER TABLE [dbo].[vHQRoles] ADD CONSTRAINT [CK_vHQRoles_UsableInPC] CHECK (([UsableInPC]='N' OR [UsableInPC]='Y'))
GO
ALTER TABLE [dbo].[vHQRoles] ADD CONSTRAINT [CK_vHQRoles_UsableInPM] CHECK (([UsableInPM]='N' OR [UsableInPM]='Y'))
GO
ALTER TABLE [dbo].[vHQRoles] ADD CONSTRAINT [CK_vHQRoles_UsableInSM] CHECK (([UsableInSM]='N' OR [UsableInSM]='Y'))
GO
ALTER TABLE [dbo].[vHQRoles] ADD CONSTRAINT [PK_vHQRoles] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vHQRoles_Role] ON [dbo].[vHQRoles] ([Role]) ON [PRIMARY]
GO
