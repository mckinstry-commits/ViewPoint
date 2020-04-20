CREATE TABLE [dbo].[vHQRoleLimit]
(
[Role] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Type] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[SubType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Limit] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vHQRoleLimit_Limit] DEFAULT ((0)),
[Threshold] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vHQRoleLimit_Threshold] DEFAULT ((0)),
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRoleLimit_Active] DEFAULT ('Y'),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
/*********************************************/
CREATE trigger [dbo].[vtHQRoleLimitd] on [dbo].[vHQRoleLimit] for DELETE as
/*----------------------------------------------------------
* Created By:	GP 2/23/2012
* Modified By:
*
*
*
*
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

begin try

	---- Audit HQ Company deletions
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vHQRoleLimit', 'HQ Role: ' + d.Role + ' Type: ' + d.Type + ' Sub Type: ' + d.SubType, null, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot delete HQ Role Limit!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
end catch   	
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtHQRoleLimiti] on [dbo].[vHQRoleLimit] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GP 2/23/2012
* Modified By:
*
*
* This trigger audits insertion in vHQRoleLimit
*
*
* Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

begin try

	/* add HQ Master Audit entry */
	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vHQRoleLimit', 'HQ Role: ' + i.Role + ' Type: ' + i.Type + ' Sub Type: ' + i.SubType, null, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot insert HQ Role Limit!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**************************************/
CREATE trigger [dbo].[vtHQRoleLimitu] on [dbo].[vHQRoleLimit] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	GP 2/23/2012
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

begin try

	/* always update HQ Master Audit */
	if update(Type)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vHQRoleLimit', 'HQ Role: ' + i.Role + ' Type: ' + i.Type + ' Sub Type: ' + i.SubType, null, 'C', 'Type', d.Type, i.Type, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Role = d.Role and i.Type = d.Type and i.SubType = d.SubType
   		where isnull(i.Type,'') <> isnull(d.Type,'')
	end
	if update(SubType)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vHQRoleLimit', 'HQ Role: ' + i.Role + ' Type: ' + i.Type + ' Sub Type: ' + i.SubType, null, 'C', 'SubType', d.SubType, i.SubType, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Role = d.Role and i.Type = d.Type and i.SubType = d.SubType
   		where isnull(i.SubType,'') <> isnull(d.SubType,'')
	end
	if update(Limit)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vHQRoleLimit', 'HQ Role: ' + i.Role + ' Type: ' + i.Type + ' Sub Type: ' + i.SubType, null, 'C', 'Limit', d.Limit, i.Limit, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Role = d.Role and i.Type = d.Type and i.SubType = d.SubType
   		where isnull(i.Limit,'') <> isnull(d.Limit,'')
	end
	if update(Threshold)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vHQRoleLimit', 'HQ Role: ' + i.Role + ' Type: ' + i.Type + ' Sub Type: ' + i.SubType, null, 'C', 'Threshold', d.Threshold, i.Threshold, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Role = d.Role and i.Type = d.Type and i.SubType = d.SubType
   		where isnull(i.Threshold,'') <> isnull(d.Threshold,'')
	end
	if update(Active)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vHQRoleLimit', 'HQ Role: ' + i.Role + ' Type: ' + i.Type + ' Sub Type: ' + i.SubType, null, 'C', 'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Role = d.Role and i.Type = d.Type and i.SubType = d.SubType
   		where isnull(i.Active,'') <> isnull(d.Active,'')
	end
	
end try	


begin catch

   	select @errmsg = @errmsg + ' - cannot update HQ Role Member!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
   
  
 




GO
ALTER TABLE [dbo].[vHQRoleLimit] ADD CONSTRAINT [PK_vHQRoleLimit] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQRoleLimit] ADD CONSTRAINT [IX_vHQRoleLimit_SubType] UNIQUE CLUSTERED  ([Role], [Type], [SubType]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQRoleLimit] WITH NOCHECK ADD CONSTRAINT [FK_vHQRoleLimit_vHQRoles] FOREIGN KEY ([Role]) REFERENCES [dbo].[vHQRoles] ([Role])
GO
ALTER TABLE [dbo].[vHQRoleLimit] NOCHECK CONSTRAINT [FK_vHQRoleLimit_vHQRoles]
GO
