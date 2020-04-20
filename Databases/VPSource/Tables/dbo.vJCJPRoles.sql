CREATE TABLE [dbo].[vJCJPRoles]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[Process] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vJCJPRoles_Process] DEFAULT ('C'),
[Role] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vJCJPRoles] ADD
CONSTRAINT [FK_vJCJPRoles_bJCJP] FOREIGN KEY ([JCCo], [Job], [PhaseGroup], [Phase]) REFERENCES [dbo].[bJCJP] ([JCCo], [Job], [PhaseGroup], [Phase]) ON DELETE CASCADE
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/*********************************************/
CREATE trigger [dbo].[btJCJPRolesd] on [dbo].[vJCJPRoles] for DELETE as
/*----------------------------------------------------------
* Created By:	GF 01/15/2010 - issue #135527
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




---- Audit inserts
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vJCJPRoles','JCCo: ' + convert(char(3), d.JCCo) + ' Job: ' + d.Job + ' Phase: ' + d.Phase + ' Role: ' + d.Role,
		d.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME() 
from deleted d join dbo.bJCCO c on d.JCCo = c.JCCo
where c.AuditPhases = 'Y'



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

CREATE trigger [dbo].[btJCJPRolesi] on [dbo].[vJCJPRoles] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GF 01/15/2010 - issue #135527
* Modified By:
*
*
* This trigger audits insertion in vJCJPRoles
*
*
* Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- validate JCCo
select @validcnt = count(*) from dbo.bJCCO c with (nolock) join inserted i on i.JCCo=c.JCCo
if @validcnt <> @numrows 
	begin
	select @errmsg = 'Invalid JC Company'
	goto error
	end

---- validate job
select @validcnt = count(*) from dbo.bJCJM j with (nolock) join inserted i on i.JCCo=j.JCCo and i.Job=j.Job
if @validcnt <> @numrows 
	begin
	select @errmsg = 'Invalid JC Job'
	goto error
	end

---- validate phase
select @validcnt = count(*) from dbo.bJCJP j with (nolock) join inserted i on i.JCCo=j.JCCo and i.Job=j.Job and i.PhaseGroup=j.PhaseGroup and i.Phase=j.Phase
if @validcnt <> @numrows 
	begin
	select @errmsg = 'Invalid JC Job Phase'
	goto error
	end
	
---- validate role
select @validcnt = count(*) from dbo.vHQRoles r with (nolock) join inserted i on i.Role=r.Role
if @validcnt <> @numrows 
	begin
	select @errmsg = 'Invalid HQ Role'
	goto error
	end

---- validate job role
select @validcnt = count(*) from dbo.vJCJobRoles r with (nolock) join inserted i on i.JCCo=r.JCCo and i.Job=r.Job and i.Role=r.Role
if @validcnt <> @numrows 
	begin
	select @errmsg = 'Invalid HQ Role'
	goto error
	end


---- Audit inserts
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vJCJPRoles','JCCo: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Role: ' + i.Role,
		i.JCCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME() 
from inserted i join dbo.bJCCO c on i.JCCo = c.JCCo
where c.AuditPhases = 'Y'


return

error:
	select @errmsg = @errmsg + ' - cannot insert JCJP Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************/
CREATE trigger [dbo].[btJCJPRolesu] on [dbo].[vJCJPRoles] for UPDATE as
/*--------------------------------------------------------------
* Created By:	GF 01/15/2010 - issue #135527 
* Modified By:
*
*
*  Update trigger on JC Job Phase Roles
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int     

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

------ validate phase
--select @validcnt = count(*) from dbo.bJCJP j with (nolock) join inserted i on i.JCCo=j.JCCo and i.Job=j.Job and i.PhaseGroup=j.PhaseGroup and i.Phase=j.Phase
--if @validcnt <> @numrows 
--	begin
--	select @errmsg = 'Invalid JC Job Phase'
--	goto error
--	end
	
------ validate role
--select @validcnt = count(*) from dbo.vHQRoles r with (nolock) join inserted i on i.Role=r.Role
--if @validcnt <> @numrows 
--	begin
--	select @errmsg = 'Invalid HQ Role'
--	goto error
--	end

------ validate job role
--select @validcnt = count(*) from dbo.vJCJobRoles r with (nolock) join inserted i on i.JCCo=r.JCCo and i.Job=r.Job and i.Role=r.Role
--if @validcnt <> @numrows 
--	begin
--	select @errmsg = 'Invalid HQ Role'
--	goto error
--	end



---------- Audit inserts ----------
IF UPDATE(Process)
	BEGIN
	INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCJPRoles','JCCo: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + ' Role: ' + i.Role,
		i.JCCo, 'C', 'Process',  d.Role, i.Role, getdate(), SUSER_SNAME()
    FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo AND d.Job=i.Job and d.Phase=i.Phase and d.Role=i.Role
    JOIN dbo.bJCCO c ON i.JCCo=c.JCCo
	where c.AuditPhases='Y' and isnull(d.Process,'') <> isnull(i.Process,'')
	END


return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update JCJP Role'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
ALTER TABLE [dbo].[vJCJPRoles] ADD CONSTRAINT [CK_vJCJPRoles_Process] CHECK (([Process]='C' OR [Process]='P'))
GO
ALTER TABLE [dbo].[vJCJPRoles] ADD CONSTRAINT [PK_vJCJPRoles] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vJCJPRoles_Role] ON [dbo].[vJCJPRoles] ([JCCo], [Job], [PhaseGroup], [Phase], [Process], [Role]) ON [PRIMARY]
GO
