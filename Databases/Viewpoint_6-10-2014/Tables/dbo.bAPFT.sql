CREATE TABLE [dbo].[bAPFT]
(
[APCo] [dbo].[bCompany] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[YEMO] [dbo].[bMonth] NOT NULL,
[V1099Type] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Box1Amt] [dbo].[bDollar] NOT NULL,
[Box2Amt] [dbo].[bDollar] NOT NULL,
[Box3Amt] [dbo].[bDollar] NOT NULL,
[Box4Amt] [dbo].[bDollar] NOT NULL,
[Box5Amt] [dbo].[bDollar] NOT NULL,
[Box6Amt] [dbo].[bDollar] NOT NULL,
[Box7Amt] [dbo].[bDollar] NOT NULL,
[Box8Amt] [dbo].[bDollar] NOT NULL,
[Box9Amt] [dbo].[bDollar] NOT NULL,
[Box10Amt] [dbo].[bDollar] NOT NULL,
[Box11Amt] [dbo].[bDollar] NOT NULL,
[Box12Amt] [dbo].[bDollar] NOT NULL,
[Box13Amt] [dbo].[bDollar] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[Box14Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPFT_Box14Amt] DEFAULT ((0)),
[Box15Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPFT_Box15Amt] DEFAULT ((0)),
[Box16Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPFT_Box16Amt] DEFAULT ((0)),
[Box17Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPFT_Box17Amt] DEFAULT ((0)),
[Box18Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPFT_Box18Amt] DEFAULT ((0)),
[OtherData] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[DIVBox7FC] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ICRptDate] [dbo].[bDate] NULL,
[TIN2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPFT_TIN2] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CorrectedErrorType] [tinyint] NULL,
[OldVendorName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldVendorAddr] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldVendorCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldVendorState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OldVendorZip] [dbo].[bZip] NULL,
[OldVendorTaxId] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CorrectedFilingYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPFT_CorrectedFilingYN] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btAPFTd    Script Date: 8/28/99 9:36:53 AM ******/
   CREATE  trigger [dbo].[btAPFTd] on [dbo].[bAPFT] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/3/98
    *  Modified: EN 11/3/98
    *			MV 10/17/02 - 18878 quoted identifier
    *
    *	Adds entry to HQ Master Audit if APCO.AuditVendors = 'Y' and
    *		APFT.AuditYN = 'Y'
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   /* Audit APFT deletions if APCO.AuditVendors = 'Y' */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bAPFT', 'VendorGroup: ' + convert(varchar(4), d.VendorGroup) +
   		' Vendor: ' + convert(varchar(6),d.Vendor) +
   		' YEMO: ' + convert(varchar(8),d.YEMO,1) +
   		' V1099Type: ' + d.V1099Type,
   		d.APCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d, bAPCO c
   		where d.APCo = c.APCo and c.AuditVendors = 'Y' and d.AuditYN = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP 1099 Totals!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btAPFTi    Script Date: 8/28/99 9:36:53 AM ******/
    CREATE    trigger [dbo].[btAPFTi] on [dbo].[bAPFT] for INSERT as
    

/*-----------------------------------------------------------------
     *  Created: EN 11/3/98
     *  Modified: EN 11/3/98
     *			MV 10/17/02 - 18878 quoted identifier cleanup.
     *
     *	This trigger rejects insertion in bAPFT (1099 Totals)
     *	if any of the following error conditions exist:
     *
     *		APCo not exists in APCO
     *		VendorGroup not exists in HQGP
     *		VendorGroup not the active VendorGroup in HQCO
     *		VendorGroup and Vendor not exists in APVM
     *		YEMO is not in the month of December
     *		V1099Type is not set up in APTT
     *
     *	Adds HQ Master Audit entry if APCO.AuditVendors = 'Y'
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    /* validate AP Company */
    select @validcnt = count(*) from bAPCO c, inserted i
    	where c.APCo = i.APCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid AP Company'
    	goto error
    	end
    /* validate VendorGroup */
    select @validcnt = count(*) from bHQGP g, inserted i
    	where i.VendorGroup = g.Grp
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Vendor Group not setup in HQ'
    	goto error
    	end
    /* validate VendorGroup in HQCO */
    select @validcnt = count(*) from bHQCO c, inserted i
    	where i.APCo = c.HQCo and i.VendorGroup = c.VendorGroup
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Vendor Group not setup as active for HQ company'
    	goto error
    	end
    /* validate Vendor vs APVM */
    select @validcnt = count(*) from bAPVM v, inserted i
    	where i.VendorGroup = v.VendorGroup and i.Vendor = v.Vendor
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Vendor not setup in AP Vendor Master'
    	goto error
    	end
    /* validate YEMO (must be in month of December) */
    select @validcnt = count(*) from inserted where datepart(month,YEMO) = 12
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Month must be December'
    	goto error
    	end
    /* validate V1099Type vs APTT */
    select @validcnt = count(*) from bAPTT v, inserted i
    	where i.V1099Type = v.V1099Type
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Vendor not setup in AP 1099 Types'
    	goto error
    	end
    /* add HQ Master Audit entry if APCO.AuditVendors = 'Y' */
    insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bAPFT', 'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) +
    	' YEMO: ' + convert(varchar(8),i.YEMO,1) +
    	' V1099Type: ' + i.V1099Type, i.APCo, 'A',
    	null, null, null, getdate(), SUSER_SNAME() from inserted i, bAPCO c
    	where i.APCo = c.APCo and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    return
    error:
    	select @errmsg = @errmsg + ' - cannot insert AP 1099 Totals!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btAPFTu    Script Date: 8/28/99 9:36:53 AM ******/
    CREATE    trigger [dbo].[btAPFTu] on [dbo].[bAPFT] for UPDATE as
    

/*-----------------------------------------------------------------
     *  Created: EN 11/3/98
     *  Modified: EN 11/3/98
     *			MV 10/17/02 - 18878 quoted identifier cleanup.
     *
     *	This trigger rejects update of primary key changes
     *	in bAPFT (AP Vendor 1099 Totals).
     *	Adds entry to HQ Master Audit if APCO.AuditVendors = 'Y' and
     *		APFT.AuditYN = 'Y'
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    /* verify primary key not changed */
    select @validcnt = count(*) from deleted d, inserted i
    	where d.APCo = i.APCo and d.VendorGroup = i.VendorGroup and
    	d.Vendor = i.Vendor and d.YEMO = i.YEMO and d.V1099Type = i.V1099Type
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Primary Key'
    	goto error
    	end
    /* Add HQ Master Audit if applicable*/
    if not exists(select * from bAPCO c, inserted i	where c.APCo = i.APCo and c.AuditVendors = 'Y'
    	and i.AuditYN = 'Y') return
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box1Amt', convert(varchar(16),d.Box1Amt), convert(varchar(16),i.Box1Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box1Amt <> i.Box1Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box2Amt', convert(varchar(16),d.Box2Amt), convert(varchar(16),i.Box2Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box2Amt <> i.Box2Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box3Amt', convert(varchar(16),d.Box3Amt), convert(varchar(16),i.Box3Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box3Amt <> i.Box3Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box4Amt', convert(varchar(16),d.Box4Amt), convert(varchar(16),i.Box4Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box4Amt <> i.Box4Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box5Amt', convert(varchar(16),d.Box5Amt), convert(varchar(16),i.Box5Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box5Amt <> i.Box5Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box6Amt', convert(varchar(16),d.Box6Amt), convert(varchar(16),i.Box6Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box6Amt <> i.Box6Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box7Amt', convert(varchar(16),d.Box7Amt), convert(varchar(16),i.Box7Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box7Amt <> i.Box7Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box8Amt', convert(varchar(16),d.Box8Amt), convert(varchar(16),i.Box8Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box8Amt <> i.Box8Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box9Amt', convert(varchar(16),d.Box9Amt), convert(varchar(16),i.Box9Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box9Amt <> i.Box9Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box10Amt', convert(varchar(16),d.Box10Amt), convert(varchar(16),i.Box10Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box10Amt <> i.Box10Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box11Amt', convert(varchar(16),d.Box11Amt), convert(varchar(16),i.Box11Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box11Amt <> i.Box11Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box12Amt', convert(varchar(16),d.Box12Amt), convert(varchar(16),i.Box12Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box12Amt <> i.Box12Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    insert into bHQMA select  'bAPFT',  'VendorGroup: ' + convert(varchar(4), i.VendorGroup) +
    	' Vendor: ' + convert(varchar(6),i.Vendor) + ' YEMO: ' + convert(varchar(8),i.YEMO,1)
    	+ ' V1099Type: ' + convert(char(1),i.V1099Type), i.APCo, 'C',
    	'Box13Amt', convert(varchar(16),d.Box13Amt), convert(varchar(16),i.Box13Amt), getdate(), SUSER_SNAME()
    	from inserted i
    	join deleted d on i.APCo = d.APCo and i.VendorGroup = d.VendorGroup
    	and i.Vendor = d.Vendor and i.YEMO = d.YEMO and i.V1099Type = d.V1099Type
    	join bAPCO c on c.APCo = i.APCo
    	where d.Box13Amt <> i.Box13Amt and c.AuditVendors = 'Y' and i.AuditYN = 'Y'
    
    return
    error:
    	select @errmsg = @errmsg + ' - cannot update AP 1099 Totals!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction

GO
ALTER TABLE [dbo].[bAPFT] WITH NOCHECK ADD CONSTRAINT [CK_bAPFT_AuditYN] CHECK (([AuditYN]='Y' OR [AuditYN]='N'))
GO
ALTER TABLE [dbo].[bAPFT] WITH NOCHECK ADD CONSTRAINT [CK_bAPFT_TIN2] CHECK (([TIN2]='Y' OR [TIN2]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biAPFT] ON [dbo].[bAPFT] ([APCo], [YEMO], [VendorGroup], [Vendor], [V1099Type]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPFT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
