CREATE TABLE [dbo].[bMSSurchargeGroupCodes]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[SurchargeGroup] [smallint] NOT NULL,
[SurchargeCode] [smallint] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btMSSurchargeGroupCodesd] on [dbo].[bMSSurchargeGroupCodes] for DELETE as
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
   
-- Audit HQ deletions
INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bMSSurchargeGroupCodes',' SurchargeGroup: ' + convert(varchar,d.SurchargeGroup)+ ', SurchargeCode: ' + convert(varchar,d.SurchargeCode), 
d.MSCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM deleted d JOIN bMSCO c ON d.MSCo=c.MSCo
where c.AuditSurcharges = 'Y'
   
return
   
error:
   	select @errmsg = @errmsg + ' - cannot delete MS Surcharge Group Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btMSSurchargeGroupCodesi] on [dbo].[bMSSurchargeGroupCodes] for INSERT as
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
select @validcnt = count(*) from inserted i inner join bMSCO c with(nolock)on c.MSCo = i.MSCo
IF @validcnt <> @numrows
begin
	select @errmsg = 'Invalid MS company!'
	goto error
end

select @validcnt = count(*) from inserted i 
inner join dbo.MSSurchargeGroups g with(nolock)on g.MSCo = i.MSCo and g.SurchargeGroup = i.SurchargeGroup 
if @validcnt <> @numrows
begin
	select @errmsg = 'Missing or Invalid Surcharge Group!'
	goto error
end
   
select @validcnt = count(*) from inserted i
inner join dbo.MSSurchargeCodes c with(nolock)on c.MSCo = i.MSCo and  c.SurchargeCode=i.SurchargeCode
if @validcnt <> @numrows
begin
	select @errmsg = 'Missing or Invalid Surcharge Code!'
	goto error
end
   
return

error:
	SELECT @errmsg = @errmsg +  ' - cannot insert MS Surcharge Group Code!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btMSSurchargeGroupCodesu] on [dbo].[bMSSurchargeGroupCodes] for UPDATE as
/*-----------------------------------------------------------------
*  Created By:  TRL  03/22/2010 - Issue 129350
*  Modified By:  
*
*  Validates MS Company, Surcharge Group, Surcharge Code
*  If Surcharge Groups flagged for auditing, inserts HQ Master Audit entry .
*
* Cannot change Primary key - MS Company, Surcharge Group, Surcharge Code
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

select @validcnt = count(*) from deleted d
join inserted i on d.MSCo = i.MSCo and d.SurchargeGroup = i.SurchargeGroup and d.SurchargeCode=i.SurchargeCode
if @validcnt <> @numrows
begin
	select @errmsg = 'Cannot change Surcharge Code'
	goto error
end

return

error:
	select @errmsg = @errmsg + ' - cannot update MS Surcharge Group Code!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction







GO
ALTER TABLE [dbo].[bMSSurchargeGroupCodes] ADD CONSTRAINT [PK_bMSSurchargeGroupCodes] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bMSSurchargeGroupCodes] WITH NOCHECK ADD CONSTRAINT [FK_bMSSurchargeGroupCodes_bMSSurchargeGroups] FOREIGN KEY ([MSCo], [SurchargeGroup]) REFERENCES [dbo].[bMSSurchargeGroups] ([MSCo], [SurchargeGroup])
GO
ALTER TABLE [dbo].[bMSSurchargeGroupCodes] NOCHECK CONSTRAINT [FK_bMSSurchargeGroupCodes_bMSSurchargeGroups]
GO
