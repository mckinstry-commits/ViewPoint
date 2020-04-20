CREATE TABLE [dbo].[vJCJobRoles]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Role] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Lead] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vJCJobRoles_Lead] DEFAULT ('N'),
[Active] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vJCJobRoles_Active] DEFAULT ('Y')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vJCJobRoles] ADD
CONSTRAINT [FK_vJCJobRoles_bJCJM] FOREIGN KEY ([JCCo], [Job]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************************/
CREATE trigger [dbo].[btJCJobRolesd] on [dbo].[vJCJobRoles] for DELETE as
/*****************************************************************
* Created By:	GF 11/16/2009 - issue #135527
* Modified By:	
*
*
*
* add HQMA audit record
*****************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- delete vJCJPRoles - Job Phase Roles
delete vJCJPRoles from vJCJPRoles e join deleted d on e.JCCo=d.JCCo and e.Job=d.Job and e.Role=d.Role



/***************************/
/* Audit inserts           */
/***************************/
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vJCJobRoles','JCCo: ' + convert(char(3), d.JCCo) + ' Job: ' + d.Job + ' Role: ' + d.Role,
		d.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM deleted d JOIN dbo.bJCCO c (nolock) ON d.JCCo = c.JCCo
where c.AuditJobs='Y'


return

error:
   select @errmsg = @errmsg + ' - cannot delete JC Job Role!'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction                                                         

   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE trigger [dbo].[btJCJobRolesi] on [dbo].[vJCJobRoles] for INSERT as
/******************************************************************
* Created By:	GF 11/15/2009 - issue #135527
* Modified By:
*
* validates JCCo, Job, Role, and User
*
* adds HQMA audit record
********************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int

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

---- validate role
select @validcnt = count(*) from dbo.vHQRoles r with (nolock) join inserted i on i.Role=r.Role
if @validcnt <> @numrows 
	begin
	select @errmsg = 'Invalid HQ Role'
	goto error
	end

---- validate User name
select @validcnt = count(*) from dbo.vDDUP p with (nolock) join inserted i on i.VPUserName=p.VPUserName
if @validcnt <> @numrows 
	begin
	select @errmsg = 'Invalid User Name'
	goto error
	end



---- Audit inserts
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vJCJobRoles','JCCo: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job + ' Role: ' + i.Role,
		i.JCCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME() 
from inserted i join dbo.bJCCO c on i.JCCo = c.JCCo
where c.AuditJobs = 'Y'



return

error:
   select @errmsg = @errmsg + ' - cannot insert JC Job Role!'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction                                                         

   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************/
CREATE trigger [dbo].[btJCJobRolesu] on [dbo].[vJCJobRoles] for UPDATE as
/*--------------------------------------------------------------
* Created By:	GF 11/16/2009 - issue #135527 
* Modified By:
*
*
*  Update trigger on JC Job Roles
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int     

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- Check if primary key has changed
if UPDATE(JCCo)
    begin
    select @errmsg = 'JC Co# may not be updated'
    goto error
    end
if UPDATE(Job)
    begin
    select @errmsg = 'Job may not be updated'
    goto error
    end
if UPDATE(Role)
    begin
    select @errmsg = 'Job Role may not be updated'
    goto error
    end
    

---- validate User name
if update(VPUserName)
	begin
	select @validcnt = count(*) from dbo.vDDUP p with (nolock) join inserted i on i.VPUserName=p.VPUserName
	if @validcnt <> @numrows 
		begin
		select @errmsg = 'Invalid User Name'
		goto error
		end
	end


---------- Audit inserts ----------
IF UPDATE(VPUserName)
	BEGIN
	INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCJobRoles','JCCo: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job + ' Role: ' + i.Role,
		i.JCCo, 'C', 'VPUserName',  d.VPUserName, i.VPUserName, getdate(), SUSER_SNAME()
    FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job and d.Role=i.Role
    JOIN dbo.bJCCO c ON i.JCCo=c.JCCo
	where c.AuditJobs='Y' and isnull(d.VPUserName,'') <> isnull(i.VPUserName,'')
	END


return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update JC Job Role'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
ALTER TABLE [dbo].[vJCJobRoles] ADD CONSTRAINT [CK_vJCJobRoles_Active] CHECK (([Active]='Y' OR [Active]='N'))
GO
ALTER TABLE [dbo].[vJCJobRoles] ADD CONSTRAINT [CK_vJCJobRoles_Lead] CHECK (([Lead]='Y' OR [Lead]='N'))
GO
ALTER TABLE [dbo].[vJCJobRoles] ADD CONSTRAINT [PK_vJCJobRoles] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vJCJobRoles_Roles] ON [dbo].[vJCJobRoles] ([JCCo], [Job], [Role], [VPUserName]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vJCJobRoles] WITH NOCHECK ADD CONSTRAINT [FK_vJCJobRoles_vHQRoles] FOREIGN KEY ([Role]) REFERENCES [dbo].[vHQRoles] ([Role])
GO
