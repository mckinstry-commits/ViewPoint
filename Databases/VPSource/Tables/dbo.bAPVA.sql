CREATE TABLE [dbo].[bAPVA]
(
[APCo] [dbo].[bCompany] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[InvAmt] [dbo].[bDollar] NOT NULL,
[PaidAmt] [dbo].[bDollar] NOT NULL,
[DiscOff] [dbo].[bDollar] NOT NULL,
[DiscTaken] [dbo].[bDollar] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bAPVA] ADD
CONSTRAINT [CK_bAPVA_AuditYN] CHECK (([AuditYN]='Y' OR [AuditYN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPVAd    Script Date: 8/28/99 9:36:59 AM ******/
   CREATE  trigger [dbo].[btAPVAd] on [dbo].[bAPVA] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 8/10/98
    *  Modified: EN 8/10/98
    * 			MV 10/18/02 - 18878 quoted identifier cleanup.
    *
    *	Adds entry to HQ Master Audit if APCO.AuditVendors = 'Y' and
    *		APVA.AuditYN = 'Y'
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   /* Audit APVA deletions if APCO.AuditVendors = 'Y' */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bAPVA', 'VendorGroup: ' + convert(varchar(4), d.VendorGroup) +
   		' Vendor: ' + convert(varchar(6),d.Vendor) + ' Mth: ' + convert(varchar(8),d.Mth,1),
   		d.APCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d, bAPCO c
   		where d.APCo = c.APCo and c.AuditVendors = 'Y' and d.AuditYN = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Vendor Activity!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPVAi    Script Date: 8/28/99 9:36:59 AM ******/
   CREATE trigger [dbo].[btAPVAi] on [dbo].[bAPVA] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created:  EN 8/10/98
    *  Modified: EN 8/10/98
    *			  MV 10/18/02 - 18878 quoted identifier cleanup.
    *			  GF 08/11/2003 - issue #22112 - performance improvements
    *
    * 
    *	This trigger rejects insertion in bAPVA (Vendor Activity)
    *	if any of the following error conditions exist:
    *
    *		APCo not exists in APCO
    *		VendorGroup not exists in HQGP
    *		VendorGroup not the active VendorGroup in HQCO
    *		VendorGroup and Vendor not exists in APVM
    *
    *	Adds HQ Master Audit entry if APCO.AuditVendors = 'Y'
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate AP Company 
   select @validcnt = count(*) from bAPCO c with (nolock), inserted i where c.APCo = i.APCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid AP Company'
   	goto error
   	end
   
   -- validate VendorGroup
   select @validcnt = count(*) from bHQGP g with (nolock), inserted i where i.VendorGroup = g.Grp
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Vendor Group not setup in HQ'
   	goto error
   	end
   
   -- validate VendorGroup in HQCO
   select @validcnt = count(*) from bHQCO c with (nolock), inserted i
   where i.APCo = c.HQCo and i.VendorGroup = c.VendorGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Vendor Group not setup as active for HQ company'
   	goto error
   	end
   
   -- validate Vendor vs APVM
   select @validcnt = count(*) from bAPVM v with (nolock), inserted i
   where i.VendorGroup = v.VendorGroup and i.Vendor = v.Vendor
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Vendor not setup in AP Vendor Master'
   	goto error
   	end
   
   
   
   -- add HQ Master Audit entry if APCO.AuditVendors = 'Y'
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bAPVA', 'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
   	' Vendor: ' + convert(varchar(6),i.Vendor) + ' Month: ' + convert(varchar(8),i.Mth,1), i.APCo, 'A',
   	null, null, null, getdate(), SUSER_SNAME() from inserted i, bAPCO c with (nolock)
   	where i.APCo = c.APCo and c.AuditVendors = 'Y'
   
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert AP Vendor Activity!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPVAu    Script Date: 8/28/99 9:36:59 AM ******/
   CREATE   trigger [dbo].[btAPVAu] on [dbo].[bAPVA] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created:  EN 8/10/98
    * Modified: EN 11/3/98
    *			 MV 10/18/02 - 18878 quoted identifier cleanup.
    *			 GF 08/11/2003 - issue #22112 - performance improvements
    *
    *
    *	This trigger rejects update in bAPVA (AP Vendor Activity) if any of the
    *	following error conditions exist:
    *
    *		Cannot change APCo
    *		Cannot change VendorGroup
    *		Cannot change Vendor
    *		Cannot change Mth
    *
    *	Adds entry to HQ Master Audit if APCO.AuditVendors = 'Y' and
    *		APVA.AuditYN = 'Y'
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- verify primary key not changed 
   select @validcnt = count(*) from deleted d, inserted i
   where d.APCo = i.APCo and d.VendorGroup = i.VendorGroup and d.Vendor = i.Vendor and d.Mth = i.Mth
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Primary Key'
   	goto error
   	end
   
   
   
   -- Add HQ Master Audit if applicable
   if not exists(select TOP 1 1 from bAPCO c with (nolock) join inserted i	on i.APCo = c.APCo 
   	where c.AuditVendors = 'Y' and i.AuditYN = 'Y') 
   	return
   
   if update(InvAmt)
   BEGIN
   	insert into bHQMA select  'bAPVA',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
   	' Vendor: ' + convert(varchar(6),i.Vendor) + ' Mth: ' + convert(varchar(8),i.Mth,1),
   	i.APCo, 'C', 'InvAmt', convert(varchar(16),d.InvAmt),
   	convert(varchar(16),i.InvAmt),	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bAPCO c with (nolock)
   	where i.APCo = d.APCo and i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor and
   	i.Mth = d.Mth and i.InvAmt <> d.InvAmt and c.APCo = i.APCo and c.AuditVendors = 'Y'
   	and i.AuditYN = 'Y'
   END
   
   if update(PaidAmt)
   BEGIN
   	insert into bHQMA select  'bAPVA',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
   	' Vendor: ' + convert(varchar(6),i.Vendor) + ' Mth: ' + convert(varchar(8),i.Mth,1),
   	i.APCo, 'C', 'PaidAmt', convert(varchar(16),d.PaidAmt),
   	convert(varchar(16),i.PaidAmt),	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bAPCO c  with (nolock)
   	where i.APCo = d.APCo and i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor and
   	i.Mth = d.Mth and i.PaidAmt <> d.PaidAmt and c.APCo = i.APCo and c.AuditVendors = 'Y'
   	and i.AuditYN = 'Y'
   END
   
   if update(DiscOff)
   BEGIN
   	insert into bHQMA select  'bAPVA',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
   	' Vendor: ' + convert(varchar(6),i.Vendor) + ' Mth: ' + convert(varchar(8),i.Mth,1),
   	i.APCo, 'C', 'DiscOff', convert(varchar(16),d.DiscOff),
   	convert(varchar(16),i.DiscOff),	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bAPCO c  with (nolock)
   	where i.APCo = d.APCo and i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor and
   	i.Mth = d.Mth and i.DiscOff <> d.DiscOff and c.APCo = i.APCo and c.AuditVendors = 'Y'
   	and i.AuditYN = 'Y'
   END
   
   if update(DiscTaken)
   BEGIN
   	insert into bHQMA select  'bAPVA',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
   	' Vendor: ' + convert(varchar(6),i.Vendor) + ' Mth: ' + convert(varchar(8),i.Mth,1),
   	i.APCo, 'C', 'DiscTaken', convert(varchar(16),d.DiscTaken),
   	convert(varchar(16),i.DiscTaken),	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bAPCO c  with (nolock)
   	where i.APCo = d.APCo and i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor and
   	i.Mth = d.Mth and i.DiscTaken <> d.DiscTaken and c.APCo = i.APCo and c.AuditVendors = 'Y'
   	and i.AuditYN = 'Y'
   END
   
   
   
   return
   
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update AP Vendor Activity!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPVA] ON [dbo].[bAPVA] ([APCo], [VendorGroup], [Vendor], [Mth]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPVA] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVA].[AuditYN]'
GO
