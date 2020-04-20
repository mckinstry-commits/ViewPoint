CREATE TABLE [dbo].[vINLocationRole]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Role] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Lead] [dbo].[bYN] NOT NULL,
[Active] [dbo].[bYN] NOT NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
CREATE trigger [dbo].[vtINLocationRoled] on [dbo].[vINLocationRole] for DELETE as
/*----------------------------------------------------------
* Created By:	NH 3/16/2012
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

	---- Audit IN Location Role deletions
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vINLocationRole', 'INCo: ' + cast(d.INCo as varchar(3)) + ' Loc: ' + d.Loc + ' Role: ' + d.Role + ' VP User Name: ' + d.VPUserName, null, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	
end try	

begin catch

	select @errmsg = @errmsg + ' - cannot delete IN Location Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
end catch   	
   
   
   
  
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtINLocationRolei] on [dbo].[vINLocationRole] for INSERT as
/*-----------------------------------------------------------------
* Created By:	NH 3/16/2012
* Modified By:
*
*
* This trigger audits insertion in vINLocationRole
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
	select 'vINLocationRole', 'INCo: ' + cast(i.INCo as varchar(3)) + ' Loc: ' + i.Loc + ' Role: ' + i.Role + ' VP User Name: ' + i.VPUserName, null, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot insert IN Location Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
  
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**************************************/
CREATE trigger [dbo].[vtINLocationRoleu] on [dbo].[vINLocationRole] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	NH 3/16/2012
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
	if update(Lead)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vINLocationRole', 'INCo : ' + cast(i.INCo as varchar(3)) + ' Loc: ' + i.Loc + ' Role: ' + i.Role + ' VP User Name: ' + i.VPUserName, null, 'C', 'Lead', d.Lead, i.Lead, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.INCo = d.INCo and i.Loc = d.Loc and i.Role = d.Role and i.VPUserName = d.VPUserName
   		where isnull(i.Lead,'') <> isnull(d.Lead,'')
	end
	if update(Active)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vINLocationRole', 'INCo : ' + cast(i.INCo as varchar(3)) + ' Loc: ' + i.Loc + ' Role: ' + i.Role + ' VP User Name: ' + i.VPUserName, null, 'C', 'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.INCo = d.INCo and i.Loc = d.Loc and i.Role = d.Role and i.VPUserName = d.VPUserName
   		where isnull(i.Active,'') <> isnull(d.Active,'')
	end
	
end try	

begin catch

   	select @errmsg = @errmsg + ' - cannot update IN Location Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
   
  
 







GO
ALTER TABLE [dbo].[vINLocationRole] ADD CONSTRAINT [PK_vINLocationRole] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_vINLocationRole_Role] ON [dbo].[vINLocationRole] ([INCo], [Loc], [VPUserName], [Role]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vINLocationRole] WITH NOCHECK ADD CONSTRAINT [FK_vINLocationRole_bINLM] FOREIGN KEY ([INCo], [Loc]) REFERENCES [dbo].[bINLM] ([INCo], [Loc])
GO
ALTER TABLE [dbo].[vINLocationRole] WITH NOCHECK ADD CONSTRAINT [FK_vINLocationRole_vHQRoles] FOREIGN KEY ([Role]) REFERENCES [dbo].[vHQRoles] ([Role])
GO
