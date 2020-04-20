CREATE TABLE [dbo].[bMSSurchargeGroups]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[SurchargeGroup] [smallint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btMSSurchargeGroupsd] on [dbo].[bMSSurchargeGroups] for DELETE as
/*-----------------------------------------------------------------
*  Created By:		TRL  03/22/2010 - Issue 129350
*  Modified By:
*
* Validates and inserts HQ Master Audit entry.  Rolls back
* deletion if one of the following conditions is met.
*
*
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount

set nocount on

if @numrows = 0 return
   
--Check MS Company Params
select @validcnt = count(*) 
from bMSCO r with(nolock) 
inner join  deleted d on r.MSCo=d.MSCo and r.DfltSurchargeGroup=d.SurchargeGroup
if @validcnt > 0
begin
	select @errmsg = 'Surcharge Group on file in MS Company Parameters as the default Surcharge Group!'
     goto error
end
  
 --Check MSSurchargeGroupCodes
select @validcnt = count(*) 
from bMSSurchargeGroupCodes g with(nolock)
inner join  deleted d on g.MSCo=d.MSCo and g.SurchargeGroup=d.SurchargeGroup
if @validcnt > 0
begin
	select @errmsg = 'Surcharge Codes on file for MS Surcharge Group!'
     goto error
end

 --Check MS Quote Detail for Surcharges 
select @validcnt = count(*) 
from bMSQH q with(nolock)
inner join  deleted d on q.MSCo=d.MSCo and q.SurchargeGroup=d.SurchargeGroup
if @validcnt > 0
begin
	select @errmsg = 'Surcharge Group and Code Overrides on file for MS Quote Detail!'
     goto error
end
   
   
-- Audit HQ deletions
INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bMSSurchargeGroups',' SurchargeGroup: ' + convert(varchar,d.SurchargeGroup), d.MSCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM deleted d JOIN bMSCO c ON d.MSCo=c.MSCo
where c.AuditSurcharges = 'Y'
   
return
   
error:
   	select @errmsg = @errmsg + ' - cannot delete MS Surcharge Group!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btMSSurchargeGroupsi] on [dbo].[bMSSurchargeGroups] for INSERT as
/*-----------------------------------------------------------------
*  Created By:  TRL 03/23/2010 - Issue 129350
*  Modified By: 
*
*  Validates MS Company, Surcharge Group
*  If Surcharge Groups flagged for auditing, inserts HQ Master Audit entry .
*
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int
   
select @numrows = @@rowcount

if @numrows = 0 return

set nocount on
   
-- validate MS Company
select @validcnt = count(*) from inserted i join bMSCO c with(nolock)on c.MSCo = i.MSCo
IF @validcnt <> @numrows
begin
	select @errmsg = 'Invalid MS company!'
	goto error
end
   
-- Audit inserts
INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bMSSurchargeGroups',' Surcharge Group: ' + convert(varchar,i.SurchargeGroup), i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM inserted i join bMSCO c on c.MSCo = i.MSCo
where i.MSCo = c.MSCo and c.AuditSurcharges = 'Y'
   
return

error:
	SELECT @errmsg = @errmsg +  ' - cannot insert MS Surcharge Group!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btMSSurchargeGroupsu] on [dbo].[bMSSurchargeGroups] for UPDATE as
/*-----------------------------------------------------------------
*  Created By:  TRL  03/22/2010 - Issue 129350
*  Modified By:  
*
*  Validates MS Company, Surcharge Group
*  If Surcharge Groups flagged for auditing, inserts HQ Master Audit entry .
*
* Cannot change Primary key - MS Company, Surcharge Code
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int

select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

-- check for key changes
select @validcnt = count(*) from deleted d join inserted i on d.MSCo = i.MSCo
if @validcnt <> @numrows
begin
	select @errmsg = 'Cannot change MS Company'
	goto error
end

select @validcnt = count(*) from deleted d
join inserted i on d.MSCo = i.MSCo and d.SurchargeGroup = i.SurchargeGroup
if @validcnt <> @numrows
begin
select @errmsg = 'Cannot change Surcharge Group'
goto error
end

-- Insert records into HQMA for changes made to audited fields
IF UPDATE(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeGroups','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Group: ' +convert(varchar,i.SurchargeGroup),
	i.MSCo, 'C','Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeGroup=i.SurchargeGroup
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.Description,'')<>isnull(i.Description,'')

return


error:
select @errmsg = @errmsg + ' - cannot update MS Surcharge Group!'
RAISERROR(@errmsg, 11, -1);
rollback transaction







GO
ALTER TABLE [dbo].[bMSSurchargeGroups] ADD CONSTRAINT [PK_bMSSurchargeGroups] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bMSSurchargeGroups] ON [dbo].[bMSSurchargeGroups] ([MSCo], [SurchargeGroup]) ON [PRIMARY]
GO
