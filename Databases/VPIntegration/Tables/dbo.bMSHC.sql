CREATE TABLE [dbo].[bMSHC]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[HaulCode] [dbo].[bHaulCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[HaulBasis] [tinyint] NOT NULL,
[UM] [dbo].[bUM] NULL,
[Taxable] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[RevBased] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSHC_RevBased] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSHCd] on [dbo].[bMSHC] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/10/2000
    *  Modified By:
    *
    * Validates and inserts HQ Master Audit entry.  Rolls back
    * deletion if one of the following conditions is met.
    *
    * No detail records in MS Haul Rates MSHR. No quote records
    * exists in MSHX.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- check MSHR - Haul Rates
   select @validcnt = count(*)
   from bMSHR, deleted d
   where bMSHR.MSCo=d.MSCo and bMSHR.HaulCode=d.HaulCode
   if @validcnt > 0
      begin
      select @errmsg = 'Haul Rates on file for Haul Code'
      goto error
      end
   
   -- check MSHX - Quote Haul Rates
   select @validcnt = count(*)
   from bMSHX, deleted d
   where bMSHX.MSCo=d.MSCo and bMSHX.HaulCode=d.HaulCode
   if @validcnt > 0
       begin
       select @errmsg = 'Haul Code is being used in MS Quote Haul Rates'
       goto error
       end
   
   -- Audit HQ deletions
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bMSHC',' Haul Code:' + d.HaulCode, d.MSCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM deleted d JOIN bMSCO c ON d.MSCo=c.MSCo
   where c.AuditHaulCodes = 'Y'
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Haul Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSHCi] on [dbo].[bMSHC] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 02/29/2000
    *  Modified By: GF 09/01/2000 - Added UM
    *
    *  Validates MS Company, Haul Basis, and Taxable flag.
    *  If Haul Codes flagged for auditing, inserts HQ Master Audit entry .
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate MS Company
   select @validcnt = count(*) from inserted i join bMSCO c on c.MSCo = i.MSCo
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid MS company!'
       goto error
       end
   
   -- validate subject to sales tax
   select @validcnt = count(*) from inserted where Taxable in ('Y','N')
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Subject to sales tax flag must be (Y) or (N)!'
       goto error
       end
   
   -- validate Haul Basis
   select @validcnt = count(*) from inserted where HaulBasis in (1,2,3,4,5)
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Haul Basis, must be (1,2,3,4,5)!'
       goto error
       end
   
   -- validate UM
   select @validcnt = count(*) from inserted where HaulBasis in (1,2) and UM is not null
   if @validcnt <> 0
       begin
   	select @errmsg = 'UM must be null if Haul Basis is 1 or 2!'
   	goto error
   	end
   
   select @validcnt = count(*) from inserted where HaulBasis in (3,4,5) and UM is null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'UM required if Haul Basis is 3, 4, or 5!'
   	goto error
   	end
   
   select @validcnt = count(*) from inserted i join bHQUM h on h.UM = i.UM
   select @nullcnt = count(*) from inserted where UM is null
   if @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid UM!'
       goto error
       end
   
   -- Audit inserts
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bMSHC',' Haul Code: ' + i.HaulCode, i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditHaulCodes = 'Y'
   
   return
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert MS Haul Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSHCu] on [dbo].[bMSHC] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 02/29/2000
    *  Modified By: GF 09/01/2000 - Added UM, fixed HQMA inserts
    *				 GF 12/03/2003 - issue #23147 changes for ansi nulls
    *
    *
    * Validates and inserts HQ Master Audit entry.
    *
    * Cannot change Primary key - MS Company, Haul Code
    */----------------------------------------------------------------
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
       join inserted i on d.MSCo = i.MSCo and d.HaulCode = i.HaulCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change Haul Code'
   	goto error
   	end
   
   -- validate subject to sales tax
   select @validcnt = count(*) from inserted where Taxable in ('Y','N')
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Subject to sales tax flag must be (Y) or (N)!'
       goto error
       end
   
   -- validate Haul Basis
   select @validcnt = count(*) from inserted where HaulBasis in (1,2,3,4,5)
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Haul Basis, must be (1,2,3,4,5)!'
       goto error
       end
   
   -- validate UM
   select @validcnt = count(*) from inserted where HaulBasis in (1,2) and UM is not null
   if @validcnt <> 0
       begin
   	select @errmsg = 'UM must be null if Haul Basis is 1 or 2!'
   	goto error
   	end
   select @validcnt = count(*) from inserted where HaulBasis in (3,4,5) and UM is null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'UM required if Haul Basis is 3, 4, or 5!'
   	goto error
   	end
   
   select @validcnt = count(*) from inserted i join bHQUM h on h.UM = i.UM
   select @nullcnt = count(*) from inserted where UM is null
   if @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid UM!'
       goto error
       end
   
   -- Insert records into HQMA for changes made to audited fields
   IF UPDATE(Description)
       insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       select 'bMSHC','MS Co#: ' + convert(char(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       	i.MSCo, 'C','Description', d.Description, i.Description, getdate(), SUSER_SNAME()
       from inserted i join deleted d on d.MSCo=i.MSCo  AND d.HaulCode=i.HaulCode
       join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       where isnull(d.Description,'')<>isnull(i.Description,'')
   
   IF UPDATE(Taxable)
       insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       select 'bMSHC','MS Co#: ' + convert(char(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       	i.MSCo, 'C','Taxable', d.Taxable, i.Taxable, getdate(), SUSER_SNAME()
       from inserted i join deleted d on d.MSCo=i.MSCo  AND d.HaulCode=i.HaulCode
       join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       where isnull(d.Taxable,'') <> isnull(i.Taxable,'')
   
   IF UPDATE(HaulBasis)
       insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       select 'bMSHC','MS Co#: ' + convert(char(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       	i.MSCo, 'C','Haul Basis', convert(varchar(3),d.HaulBasis), convert(varchar(3),i.HaulBasis), getdate(), SUSER_SNAME()
       from inserted i join deleted d on d.MSCo=i.MSCo  AND d.HaulCode=i.HaulCode
       join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       where isnull(d.HaulBasis,'') <> isnull(i.HaulBasis,'')
   
   IF UPDATE(UM)
       insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       select 'bMSHC','MS Co#: ' + convert(char(3), i.MSCo) + ' Haul Code: ' + i.HaulCode,
       	i.MSCo, 'C','UM', d.UM, i.UM, getdate(), SUSER_SNAME()
       from inserted i join deleted d on d.MSCo=i.MSCo  AND d.HaulCode=i.HaulCode
       join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditHaulCodes='Y'
       where isnull(d.UM,'')<>isnull(i.UM,'')
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update MS Haul Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
CREATE NONCLUSTERED INDEX [biMSHaulCodeNoCo] ON [dbo].[bMSHC] ([HaulCode]) INCLUDE ([Description]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSHC] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSHC] ON [dbo].[bMSHC] ([MSCo], [HaulCode]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSHC].[Taxable]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSHC].[RevBased]'
GO
