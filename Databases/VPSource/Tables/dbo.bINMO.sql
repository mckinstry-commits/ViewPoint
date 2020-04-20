CREATE TABLE [dbo].[bINMO]
(
[INCo] [dbo].[bCompany] NOT NULL,
[MO] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[OrderDate] [dbo].[bDate] NULL,
[OrderedBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Status] [tinyint] NOT NULL,
[AddedMth] [dbo].[bMonth] NULL,
[AddedBatchId] [dbo].[bBatchID] NULL,
[MthClosed] [dbo].[bMonth] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Purge] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Approved] [dbo].[bYN] NULL,
[ApprovedBy] [dbo].[bVPUserName] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bINMO] ADD
CONSTRAINT [CK_bINMO_Approved] CHECK (([Approved]='Y' OR [Approved]='N' OR [Approved] IS NULL))
ALTER TABLE [dbo].[bINMO] ADD
CONSTRAINT [CK_bINMO_Purge] CHECK (([Purge]='Y' OR [Purge]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    trigger [dbo].[btINMOd] on [dbo].[bINMO] for DELETE as

/*--------------------------------------------------------------
    *  Created: GF	02/18/2002
    *  Modified: GG 04/29/02 - added validation and HQ auditing	
	*				GF 02/14/2006 - issue #120167 when purging to not update bPMMF
	*				GP 05/15/2009 - Issue 133436 Added HQAT code
	*				GF 12/21/2010 - issue #141957 record association
	*				GF 01/26/2011 - tfs #398
	*
	*
    *
    *  Delete trigger for IN Material Order Header
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for MO Items
   if exists(select * from deleted d join bINMI t on d.INCo = t.INCo and d.MO = t.MO)
   	begin
   	select @errmsg = 'Material Order Items exist '
   	goto error
   	end


-- -- -- Update PMMF entries, set MO and MOItem to null
-- -- -- if running MO Purge and INMO.Purge flag is 'Y'
-- -- -- then do not update PMMF.
update bPMMF set MO = null, MOItem = null, InterfaceDate = null
from bPMMF p join deleted d on p.INCo = d.INCo and p.MO = d.MO and d.Purge = 'N'
-- -- -- when Items are deleted, PM Material entries are removed, but when a MO Header is deleted
-- -- -- bPMMF entries are not, only the MO and MO Items are set to null in bPMMF
-- -- -- update bPMMF set MO = null, MOItem = null, InterfaceDate = null
-- -- -- from bPMMF p join deleted d on p.INCo = d.INCo and p.MO = d.MO

---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bINMO' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bINMO', d.KeyID, null, null, x.Issue, 'D',
		'INCo: ' + CONVERT(VARCHAR(3), ISNULL(d.INCo,'')) + ' MO: ' + ISNULL(d.MO,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'INMO' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bINMO', d.KeyID, null, null, x.Issue, 'D',
		'INCo: ' + CONVERT(VARCHAR(3), ISNULL(d.INCo,'')) + ' MO: ' + ISNULL(d.MO,'') + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'INMO' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='INMO' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='INMO' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL



-- -- -- HQ Audit
   insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMO',' MO: ' + d.MO, d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from deleted d
   join bINCO c ON d.INCo = c.INCo
   where c.AuditMOs = 'Y' and d.Purge = 'N'	-- skip if purging
   
   	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
    where d.UniqueAttchID is not null  
   
   
   return
   error:
      select @errmsg = @errmsg + ' - cannot delete IN Material Order Header (bINMO)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btINMOi] on [dbo].[bINMO] for INSERT as
   

/**************************************************************
    *  Created: GG 04/29/02
    *  Modified:
    *
    * Insert trigger for IN Material Order Header
    * 
    ****************************************************************/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate IN Company
   select @validcnt = count(*)
   from bINCO c
   join inserted i on i.INCo = c.INCo
   if @validcnt<>@numrows
   	begin
     	select @errmsg = 'Invalid IN Company '
     	goto error
     	end
   -- validate JC Co#
   select @validcnt = count(*)
   from bJCCO j
   join inserted i on i.JCCo = j.JCCo
   if @validcnt <> @numrows
   	begin
     	select @errmsg = 'Invalid JC Company '
     	goto error
     	end
   -- validate Job
   select @validcnt = count(*)
   from bJCJM j
   join inserted i on i.JCCo = j.JCCo and i.Job = j.Job
   if @validcnt <> @numrows
     	begin
     	select @errmsg = 'Invalid Job '
     	goto error
     	end
   -- validate Status
   if exists(select 1 from inserted where Status not in (0,3))
     	begin
   	select @errmsg = 'Status must be ''Pending'' or ''Open'' '
     	goto error
     	end
   --validate Month Closed
   if exists(select 1 from inserted where MthClosed is not null)
     	begin
     	select @errmsg = 'Month Closed must be null '
     	goto error
     	end
   --validate InUseMth
   if exists(select 1 from inserted where InUseMth is not null)
     	begin
     	select @errmsg = '''InUseMonth'' must be null '
     	goto error
     	end
   --validate InUseBatchId
   if exists(select 1 from inserted where InUseBatchId is not null)
   	begin
     	select @errmsg = '''InUseBatchId'' must be null '
     	goto error
     	end
   --validate Purge flag
    if exists(select * from inserted where Purge <> 'N')
     	begin
     	select @errmsg = 'Purge flag must be set to ''N'' '
     	goto error
     	end
   
   -- HQ Auditing
   insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMO',' MO: ' + i.MO, i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from inserted i
   join bINCO c on c.INCo = i.INCo
   where i.INCo = c.INCo and c.AuditMOs = 'Y'
   
   return
   
   error:
        select @errmsg = @errmsg + ' - cannot insert IN Material Order Header (bINMO)'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btINMOu] on [dbo].[bINMO] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created: GG 04/29/02
    *  Modified: 
    *			JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
    *
    *  Update trigger for IN Material Order Header
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
    --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bINMO', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END    
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.INCo = i.INCo and d.MO = i.MO
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change IN Company or Material Order# '
    	goto error
    	end
   -- validate JC Co#
   if update(JCCo)
   	begin
   	select @validcnt = count(*)
   	from bJCCO j
   	join inserted i on i.JCCo = j.JCCo
   	if @validcnt <> @numrows
   		begin
   	  	select @errmsg = 'Invalid JC Company '
   	  	goto error
   	  	end	
   	end
   -- validate Job
   if update(JCCo) or update(Job)
   	begin
   	select @validcnt = count(*)
   	from bJCJM j
   	join inserted i on i.JCCo = j.JCCo and i.Job = j.Job
   	if @validcnt <> @numrows
   	  	begin
   	  	select @errmsg = 'Invalid Job '
   	  	goto error
   	  	end
   	end
   -- check Month Closed
   if exists(select 1 from inserted where (MthClosed is null and Status = 2)
       or (MthClosed is not null and Status <> 2))
       begin
    	select @errmsg = 'Month Closed must be null until Material Order is ''closed'' '
    	goto error
    	end
   -- validate Purge flag - mut be 'closed'
   if exists(select 1 from inserted where Purge = 'Y' and Status <> 2)
       begin
    	select @errmsg = 'Material Orders must be ''closed'' before purging '
    	goto error
    	end
   
   -- update Required Date on PM Materials using MO Order Date
   update bPMMF set ReqDate = i.OrderDate
   from bPMMF m
   join inserted i on m.INCo = i.INCo and m.MO = i.MO
   join deleted d on i.INCo = d.INCo and i.MO = d.MO
   where isnull(d.OrderDate,'') <> isnull(i.OrderDate,'') and i.OrderDate is not null
   and m.ReqDate is null     -- only if null
   
   
   -- HQ Auditing
   if exists(select 1 from inserted i join bINCO a on i.INCo = a.INCo and a.AuditMOs = 'Y')
       begin
       insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bINMO', ' MO: ' + i.MO, i.INCo, 'C', 'Description', d.Description, i.Description,
   		getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.MO = i.MO
       join bINCO a on a.INCo = i.INCo
    	where isnull(d.Description,'') <> isnull(i.Description,'') and a.AuditMOs = 'Y'
   
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bINMO', ' MO: ' + i.MO, i.INCo, 'C', 'JC Co#',
   		convert(varchar,d.JCCo), convert(varchar,i.JCCo), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.MO = i.MO
       join bINCO a on a.INCo = i.INCo
    	where d.JCCo <> i.JCCo and a.AuditMOs = 'Y'
   
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bINMO', ' MO: ' + i.MO, i.INCo, 'C', 'Job',
   		d.Job, i.Job, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.MO = i.MO
       join bINCO a on a.INCo = i.INCo
    	where d.Job <> i.Job and a.AuditMOs = 'Y'
   
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bINMO', ' MO: ' + i.MO, i.INCo, 'C', 'OrderDate',
   		convert(varchar,d.OrderDate,1), convert(varchar,i.OrderDate,1), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.MO = i.MO
       join bINCO a on a.INCo = i.INCo
    	where isnull(d.OrderDate,'') <> isnull(i.OrderDate,'') and a.AuditMOs = 'Y'
   
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bINMO', ' MO: ' + i.MO, i.INCo, 'C', 'OrderedBy',
   		d.OrderedBy, i.OrderedBy, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.MO = i.MO
       join bINCO a on a.INCo = i.INCo
    	where isnull(d.OrderedBy,'') <> isnull(i.OrderedBy,'') and a.AuditMOs = 'Y'
   
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bINMO', ' MO: ' + i.MO, i.INCo, 'C', 'Status',
   		convert(varchar,d.Status), convert(varchar,i.Status), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.MO = i.MO
       join bINCO a on a.INCo = i.INCo
    	where d.Status <> i.Status and a.AuditMOs = 'Y'
   
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bINMO', ' MO: ' + i.MO, i.INCo, 'C', 'MthClosed',
   		convert(varchar,d.MthClosed,1), convert(varchar,i.MthClosed,1), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.MO = i.MO
       join bINCO a on a.INCo = i.INCo
    	where isnull(d.MthClosed,'') <> isnull(i.MthClosed,'') and a.AuditMOs = 'Y'
       end
   
Trigger_Skip:
   
   return
   
    error:
       select @errmsg = @errmsg + ' - cannot update IN Material Order Header (bINMO)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINMO] ON [dbo].[bINMO] ([INCo], [MO]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINMO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINMO].[Purge]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINMO].[Approved]'
GO
