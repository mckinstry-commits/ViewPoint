CREATE TABLE [dbo].[bPMTH]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMTH] ON [dbo].[bPMTH] ([PMCo], [Template]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMTH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/****** Object:  Trigger dbo.btPMTHd    Script Date: 9/10/99 1:21:17 AM ******/
CREATE trigger [dbo].[btPMTHd] on [dbo].[bPMTH] for DELETE as 
/*-------------------------------------------------------------- 
 * Delete trigger for PMTH
 * Created By:	GR 09/10/99
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				JayR 03/28/2012 TK-00000 Remove unused variables
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMTH', ' Template: ' + isnull(d.Template,''), d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d join bPMCO c on c.PMCo = d.PMCo
where d.PMCo = c.PMCo and c.AuditPMTH = 'Y'


RETURN 
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMTHi    Script Date: 8/28/99 9:37:59 AM ******/
CREATE  trigger [dbo].[btPMTHi] on [dbo].[bPMTH] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMTH
 * Created By:	GF 12/13/2006 - 6.x HQMA
 * Modified By:  JayR 03/28/2012 TK-00000 Remove unused variables
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMTH', ' Template: ' + isnull(i.Template,''), i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMTH = 'Y'

RETURN 
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMTHu    Script Date: 8/28/99 9:37:59 AM ******/
CREATE trigger [dbo].[btPMTHu] on [dbo].[bPMTH] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMTH
 * Created By:	GF 12/13/2006 - 6.x auditing
 * Modified By:  JayR 03/28/2012 TK-00000 Remove unused variables
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMTH', 'Template: ' + isnull(i.Template,''), i.PMCo, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Template=i.Template 
	join bPMCO c on c.PMCo=i.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditPMTH = 'Y'

RETURN 
   
  
 





GO
