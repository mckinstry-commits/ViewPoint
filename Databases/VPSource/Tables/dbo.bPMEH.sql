CREATE TABLE [dbo].[bPMEH]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[BudgetNo] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMEH] ADD
CONSTRAINT [FK_bPMEH_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btPMEHd] on [dbo].[bPMEH] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMEH
 * Created By:	GF 05/24/2007
 * Modified By:  JayR 03/21/2012 Change to use FK with delete cascade.
 *
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMEH','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' BudgetNo: ' + isnull(d.BudgetNo,''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMEH = 'Y'


RETURN  

   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btPMEHi] on [dbo].[bPMEH] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMEH
 * Created By:	GF 05/24/2007
 * Modified By: JayR 03/21/2012 TK-00000 Change to using FK for constraints
 *
 *		
 *
 *--------------------------------------------------------------*/


if @@rowcount = 0 return
set nocount on

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMEH', ' PMCo: ' + convert(char(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,''),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMEH = 'Y'


RETURN 
   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

CREATE trigger [dbo].[btPMEHu] on [dbo].[bPMEH] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMEH
 * Created By:	GF 05/24/2007
 * Modified By
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- check for changes to PMCo
if update(PMCo)
	begin
	RAISERROR('Cannot change PM Company - cannot update PMEH', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

-- check for changes to Project
if update(Project)
	begin
	RAISERROR('Cannot change Project - cannot update PMEH', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

-- check for changes to estimate
if update(BudgetNo)
	begin
	RAISERROR('Cannot change estimate - cannot update PMEH', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end



---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMEH', 'PMCo: ' + convert(varchar(3),i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' BudgetNo: ' + isnull(i.BudgetNo,''),
		i.PMCo, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.BudgetNo=i.BudgetNo
	join bPMCO ON i.PMCo=bPMCO.PMCo and bPMCO.AuditPMEH='Y'
	where isnull(d.Description,'') <> isnull(i.Description,'')


RETURN 
   
  
 











GO
ALTER TABLE [dbo].[bPMEH] ADD CONSTRAINT [PK_bPMEH] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [BudgetNo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMEH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
