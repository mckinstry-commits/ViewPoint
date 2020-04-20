CREATE TABLE [dbo].[bMSSurchargeCodes]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[SurchargeCode] [smallint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[SurchargeBasis] [tinyint] NOT NULL,
[SurchargeMaterial] [dbo].[bMatl] NOT NULL,
[TaxableYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSSurchargeCodes_TaxableYN] DEFAULT ('N'),
[PayCode] [dbo].[bPayCode] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSSurchargeCodes_Active] DEFAULT ('Y'),
[DiscountsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSSurchargeCodes_DiscountsYN] DEFAULT ('N'),
[RevCode] [dbo].[bRevCode] NULL,
[EffectiveDate] [dbo].[bDate] NULL,
[SurchargePhaseCT] [tinyint] NOT NULL CONSTRAINT [DF_bMSSurchargeCodes_SurchargePhaseCT] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btMSSurchargeCodesd] on [dbo].[bMSSurchargeCodes] for DELETE as
/*-----------------------------------------------------------------
*  Created By: 
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
   
--Check MS Surcharge Code Rates 
select @validcnt = count(*) 
from bMSSurchargeCodeRates r with(nolock)
inner join  deleted d on r.MSCo=d.MSCo and r.SurchargeCode=d.SurchargeCode
if @validcnt > 0
begin
	select @errmsg = 'Surcharge Rates on file for MS Surcharge Code!'
     goto error
end
  
 --Check MSSurchargeGroupCodes
select @validcnt = count(*) 
from bMSSurchargeGroupCodes g with(nolock)
inner join  deleted d on g.MSCo=d.MSCo and g.SurchargeCode=d.SurchargeCode
if @validcnt > 0
begin
	select @errmsg = 'Surcharge Code on file for MS Surcharge Group!'
     goto error
end

 --Check MS Quote Detail for Surcharges 
select @validcnt = count(*) 
from bMSSurchargeOverrides r with(nolock)
inner join  deleted d on r.MSCo=d.MSCo and r.SurchargeCode=d.SurchargeCode
if @validcnt > 0
begin
	select @errmsg = 'Surcharge Code Overrides on file for MS Quote Detail!'
     goto error
end
   
--Check Open Ticket Batchs
select @validcnt = count(*) 
from bMSTB t with(nolock)
inner join  deleted d on t.Co=d.MSCo and t.SurchargeCode=d.SurchargeCode 
if @validcnt > 0
begin
	select @errmsg = 'Surcharge Code on file for open MS Ticket Batch!'
     goto error
end  
   
-- Audit HQ deletions
INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bMSSurchargeCodes',' SurchargeCode: ' + convert(varchar,d.SurchargeCode), d.MSCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM deleted d JOIN bMSCO c ON d.MSCo=c.MSCo
where c.AuditSurcharges = 'Y'
   
return
   
error:
   	select @errmsg = @errmsg + ' - cannot delete MS Surcharge Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btMSSurchargeCodesi] on [dbo].[bMSSurchargeCodes] for INSERT as
/*-----------------------------------------------------------------
*  Created By:  TRL 03/23/2010 - Issue 129350
*  Modified By: 
*
*  Validates MS Company, Surcharge Basis, Surcharge Material, UM and PayCode 
*  If Surcharge Codes flagged for auditing, inserts HQ Master Audit entry .
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
   
-- validate Haul Basis
select @validcnt = count(*) from inserted where SurchargeBasis in (1,2,3,4,5,6,7)
IF @validcnt <> @numrows
begin
	select @errmsg = 'Invalid Surcharge Basis, must be (1,2,3,4,5,6,7)!'
	goto error
end

-- validate SurchargeMaterial is not null
select @validcnt = count(*) from inserted where SurchargeMaterial is not null
if @validcnt <> @numrows
begin
	select @errmsg = 'Missing Surcharge Material!'
	goto error
end 

--validate Surcharge Material to HQ Material
select @validcnt = count(*) 
from bHQMT m with(nolock) 
inner join inserted i on i.SurchargeMaterial=m.Material
inner join bHQCO c with(nolock)on c.HQCo=i.MSCo
where m.MatlGroup=c.MatlGroup 
if @validcnt <> @numrows
begin
	select @errmsg = 'Invalid Surcharge Material!'
	goto error
end 
       

-- validate SurchargePhaseCT
select @validcnt = count(*) from inserted where SurchargePhaseCT in (1,2) 
if @validcnt <> @numrows
begin
	select @errmsg = 'Phase and CT must be 1-Material or 2-Haul!'
	goto error
end


-- validate Pay Code
select @validcnt = count(*) from inserted i  inner join bMSPC c with(nolock)on  c.MSCo = i.MSCo and c.PayCode = i.PayCode
select @nullcnt = count(*) from inserted where PayCode is null
if @validcnt + @nullcnt  <> @numrows
begin
        select @errmsg = 'Invalid Pay Code!'
        goto error
end
   
--validate Rev Code
/*Not required at this time, Rev Code can be used across multiple companies, they just have to be set up in the respective co*/
   
-- Audit inserts
INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bMSSurchargeCodes',' Surcharge Code: ' + convert(varchar,i.SurchargeCode), i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM inserted i join bMSCO c on c.MSCo = i.MSCo
where i.MSCo = c.MSCo and c.AuditSurcharges = 'Y'
   
return

error:
	SELECT @errmsg = @errmsg +  ' - cannot insert MS Surcharge Code!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btMSSurchargeCodesu] on [dbo].[bMSSurchargeCodes] for UPDATE as
/*-----------------------------------------------------------------
*  Created By:  TRL  03/22/2010 - Issue 129350
*  Modified By:  
*
*  Validates MS Company, Surcharge Basis, Surcharge Material, UM and PayCode 
*  If Surcharge Codes flagged for auditing, inserts HQ Master Audit entry .
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
join inserted i on d.MSCo = i.MSCo and d.SurchargeCode = i.SurchargeCode
if @validcnt <> @numrows
begin
select @errmsg = 'Cannot change Surcharge Code'
goto error
end

-- Surcharge Basis is 1,2,3,4,5,7
select @validcnt = count(*) from inserted where SurchargeBasis in (1,2,3,4,5,6,7)
IF @validcnt <> @numrows
begin
	select @errmsg = 'Invalid Surcharge Basis, must be (1,2,3,4,5,6,7)!'
	goto error
end

-- validate SurchargePhaseCT
select @validcnt = count(*) from inserted where SurchargePhaseCT in (1,2) 
if @validcnt <> @numrows
begin
	select @errmsg = 'Phase and CT must be 1-Material or 2-Haul!'
	goto error
end

-- validate Pay Code
select @validcnt = count(*) from inserted i  inner join bMSPC c with(nolock)on  c.MSCo = i.MSCo and c.PayCode = i.PayCode
select @nullcnt = count(*) from inserted where PayCode is null
if @validcnt + @nullcnt  <> @numrows
begin
        select @errmsg = 'Invalid Pay Code!'
        goto error
end

-- Insert records into HQMA for changes made to audited fields
IF UPDATE(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeCodes','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Code: ' +convert(varchar,i.SurchargeCode),
	i.MSCo, 'C','Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeCode=i.SurchargeCode
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.Description,'')<>isnull(i.Description,'')
	
IF UPDATE(SurchargeBasis)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeCodes','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Code: ' +convert(varchar,i.SurchargeCode),
	i.MSCo, 'C','SurchargeBasis', convert(varchar(3),d.SurchargeBasis), convert(varchar(3),i.SurchargeBasis), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeCode=i.SurchargeCode
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.SurchargeBasis,'') <> isnull(i.SurchargeBasis,'')
	
IF UPDATE(SurchargeMaterial)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeCodes','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Code: ' +convert(varchar,i.SurchargeCode),
	i.MSCo, 'C','SurchargeMaterial', d.SurchargeMaterial, i.SurchargeMaterial, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeCode=i.SurchargeCode
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.SurchargeMaterial,'') <> isnull(i.SurchargeMaterial,'')
	
IF UPDATE(SurchargePhaseCT)	
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeCodes','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Code: ' +convert(varchar,i.SurchargeCode),
	i.MSCo, 'C','SurchargePhaseCT', d.SurchargePhaseCT, i.SurchargePhaseCT, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeCode=i.SurchargeCode
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.SurchargePhaseCT,'')<>isnull(i.SurchargePhaseCT,'')
	
IF UPDATE(TaxableYN)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeCodes','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Code: ' +convert(varchar,i.SurchargeCode),
	i.MSCo, 'C','TaxableYN', d.TaxableYN, i.TaxableYN, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeCode=i.SurchargeCode
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.TaxableYN,'') <> isnull(i.TaxableYN,'')

IF UPDATE(PayCode) 
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeCodes','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Code: ' +convert(varchar,i.SurchargeCode),
	i.MSCo, 'C','PayCode', d.PayCode, i.PayCode, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeCode=i.SurchargeCode
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.PayCode,'') <> isnull(i.PayCode,'')

IF UPDATE(Active)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeCodes','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Code: ' +convert(varchar,i.SurchargeCode),
	i.MSCo, 'C','Active', d.Active, i.Active, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeCode=i.SurchargeCode
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.Active,'') <> isnull(i.Active,'')

IF UPDATE(DiscountsYN)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeCodes','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Code: ' +convert(varchar,i.SurchargeCode),
	i.MSCo, 'C','DiscountsYN', d.DiscountsYN, i.DiscountsYN, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeCode=i.SurchargeCode
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.DiscountsYN,'') <> isnull(i.DiscountsYN,'')

IF UPDATE(RevCode)  
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bMSSurchargeCodes','MS Co#: ' + convert(char(3), i.MSCo) + ' Surcharge Code: ' +convert(varchar,i.SurchargeCode),
	i.MSCo, 'C','RevCode', d.RevCode, i.RevCode, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.MSCo=i.MSCo  AND d.SurchargeCode=i.SurchargeCode
	join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	where isnull(d.RevCode,'') <> isnull(i.RevCode,'')

return


error:
select @errmsg = @errmsg + ' - cannot update MS Surcharge Code!'
RAISERROR(@errmsg, 11, -1);
rollback transaction







GO
ALTER TABLE [dbo].[bMSSurchargeCodes] ADD CONSTRAINT [PK_bMSSurchargeCodes] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bMSSurchargeCodes] ON [dbo].[bMSSurchargeCodes] ([MSCo], [SurchargeCode]) ON [PRIMARY]
GO
