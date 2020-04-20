CREATE TABLE [dbo].[bHQTL]
(
[TaxGroup] [dbo].[bGroup] NOT NULL,
[TaxCode] [dbo].[bTaxCode] NOT NULL,
[TaxLink] [dbo].[bTaxCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btHQTLd    Script Date: 8/28/99 9:37:36 AM ******/
   CREATE     trigger [dbo].[btHQTLd] on [dbo].[bHQTL] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created by:  CMW 04/11/02
    *  Modified by: CMW 07/12/02 Fixed multiple entry problem (issue # 17902).
    *               CMW 08/12/02 Fixed string/integer problem (issue # 18249).
    *
    *	This trigger audits delete if any HQ Company has the AuditTax option set.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* add HQ Master Audit entry */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQTL',  'TaxGroup/Code/Link: ' + convert(varchar(3),d.TaxGroup) + ' ' + min(d.TaxCode) + ' ' + min(d.TaxLink),
   	d.TaxGroup, 'D', null, null, null, getdate(), SUSER_SNAME() from deleted d, bHQCO h
   		where d.TaxGroup = h.TaxGroup and AuditTax = 'Y'
       group by d.TaxGroup
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete Tax Link!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btHQTLi    Script Date: 8/28/99 9:37:36 AM ******/
   CREATE    trigger [dbo].[btHQTLi] on [dbo].[bHQTL] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created by:  ??
    *  Modified by: CMW 04/11/02 - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
    *               CMW 07/12/02 - Fixed duplicate entry problem (issue # 17902).
    *               CMW 08/12/02 - Fixed string/integer problem (issue # 18249).
    *
    *	This trigger rejects insertion in bHQTL (Tax Links)
    *	if any of the following error conditions exist:
    *
    *	Invalid TaxGroup - must exist in bHQGP
    *	Invalid TaxCode or TaxLink - must exist in bHQTX
    *	TaxCode must be MultiLevel = 'Y' and TaxLink must be MultiLevel 'N'
    *
    *	Audit inserts if any HQ Company has the AuditTax option set.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* validate TaxGroup */
   select @validcnt = count(*) from bHQGP g, inserted i
   	where g.Grp = i.TaxGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Tax Group'
   	goto error
   	end
   
   /* validate TaxCode - must be multi-level - MultiLevel = 'Y' */
   select @validcnt = count(*) from bHQTX t, inserted i
   	where t.TaxGroup = i.TaxGroup and t.TaxCode = i.TaxCode
   	and t.MultiLevel = 'Y'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Tax Code - must be multi-level'
   	goto error
   	end
   
   /* validate TaxLink - must be single-level - Type 'S' */
   select @validcnt = count(*) from bHQTX t, inserted i
   	where t.TaxGroup = i.TaxGroup and t.TaxCode = i.TaxLink
   	and t.MultiLevel = 'N'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Linked Tax Code must be single-level'
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQTL',  'TaxGroup/Code/Link: ' + convert(varchar(3), i.TaxGroup) + min(i.TaxCode) + min(i.TaxLink),
   	i.TaxGroup, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i, bHQCO h
   		where i.TaxGroup = h.TaxGroup and AuditTax = 'Y'
       group by i.TaxGroup
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert Tax Link!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQTL] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQTL] ON [dbo].[bHQTL] ([TaxGroup], [TaxCode], [TaxLink]) ON [PRIMARY]
GO
