CREATE TABLE [dbo].[bMSPC]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[PayCode] [dbo].[bPayCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[PayBasis] [tinyint] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSPCd] on [dbo].[bMSPC] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/03/2000
    *  Modified By:
    *
    * Validates and inserts HQ Master Audit entry.  Rolls back
    * deletion if one of the following conditions is met.
    *
    * No detail records in MS Pay Rates MSPR.
    * No quote records exists in MSPX.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- check MSPR - Pay Rates
   select @validcnt = count(*)
   from bMSPR, deleted d
   where bMSPR.MSCo=d.MSCo and bMSPR.PayCode=d.PayCode
   if @validcnt > 0
      begin
      select @errmsg = 'Pay Rates exist!'
      goto error
      end
   
   -- check MSPX - Quote Pay Rates
   select @validcnt = count(*)
   from bMSPX, deleted d
   where bMSPX.MSCo=d.MSCo and bMSPX.PayCode=d.PayCode
   if @validcnt > 0
       begin
       select @errmsg = 'Pay Code is being used in MS Quote Pay Rates'
       goto error
       end
   
   -- Audit deletions
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bMSPC',' Pay Code:' + d.PayCode, d.MSCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM deleted d JOIN bMSCO c ON d.MSCo=c.MSCo
   where c.AuditPayCodes = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Pay Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSPCi] on [dbo].[bMSPC] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/03/2000
    *  Modified By:	DAN SO 04/02/2010 - ISSUE: #129350 - added 7-Percent of Surcharge Total
    *
    *  Validates MS Company, Pay Basis.
    *  If Pay Codes flagged for auditing, inserts HQ Master Audit entry .
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   
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
   
   -- validate Pay Basis
   select @validcnt = count(*) from inserted where PayBasis in (1,2,3,4,5,6,7)	--ISSUE: #129350
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Pay Basis, must be (1,2,3,4,5,6,7)!'
       goto error
       end
   
   -- Audit inserts
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bMSPC',' Pay Code: ' + i.PayCode, i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditPayCodes = 'Y'
   
   return
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert MS Pay Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSPCu] on [dbo].[bMSPC] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/03/2000
    *  Modified By: GF 12/03/2003 - issue #23147 changes for ansi nulls
    *				DAN SO 04/02/2010 - ISSUE: #129350 - added 7-Percent of Surcharge Total
    *
    * Validates and inserts HQ Master Audit entry.
    *
    * Cannot change Primary key - MS Company, Pay Code
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   if update(MSCo)
   	begin
   	select @errmsg = 'Cannot change MS Company'
   	goto error
   	end
   
   if update(PayCode)
   	begin
   	select @errmsg = 'Cannot change Pay Code'
   	goto error
   	end
   
   -- validate Pay Basis
   select @validcnt = count(*) from inserted where PayBasis in (1,2,3,4,5,6,7)	--ISSUE: #129350
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Pay Basis, must be (1,2,3,4,5,6,7)!'
       goto error
       end
   
   -- Insert records into HQMA for changes made to audited fields
   IF UPDATE(Description)
       insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       select 'bMSPC','MS Co#: ' + convert(char(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C','Description', d.Description, i.Description, getdate(), SUSER_SNAME()
       from inserted i join deleted d on d.MSCo=i.MSCo  AND d.PayCode=i.PayCode
       join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       where isnull(d.Description,'') <> isnull(i.Description,'')
   
   IF UPDATE(PayBasis)
       insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       select 'bMSPC','MS Co#: ' + convert(char(3), i.MSCo) + ' Pay Code: ' + i.PayCode,
       i.MSCo, 'C','Pay Basis', d.PayBasis, i.PayBasis, getdate(), SUSER_SNAME()
       from inserted i join deleted d on d.MSCo=i.MSCo  AND d.PayCode=i.PayCode
       join bMSCO on i.MSCo=bMSCO.MSCo and bMSCO.AuditPayCodes='Y'
       where isnull(d.PayBasis,'') <> isnull(i.PayBasis,'')
   
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update MS Pay Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSPC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSPC] ON [dbo].[bMSPC] ([MSCo], [PayCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
