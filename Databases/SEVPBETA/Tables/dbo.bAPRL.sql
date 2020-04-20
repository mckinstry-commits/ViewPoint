CREATE TABLE [dbo].[bAPRL]
(
[APCo] [dbo].[bCompany] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[InvId] [char] (10) COLLATE Latin1_General_BIN NULL,
[Line] [smallint] NOT NULL,
[LineType] [tinyint] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[ItemType] [tinyint] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[EMCo] [dbo].[bCompany] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[Equip] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NULL,
[Supplier] [dbo].[bVendor] NULL,
[PayType] [tinyint] NOT NULL,
[GrossAmt] [dbo].[bDollar] NOT NULL,
[MiscAmt] [dbo].[bDollar] NOT NULL,
[MiscYN] [dbo].[bYN] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[Retainage] [dbo].[bDollar] NOT NULL,
[Discount] [dbo].[bDollar] NOT NULL,
[PayCategory] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPRLd    Script Date: 8/28/99 9:36:56 AM ******/
   CREATE  trigger [dbo].[btAPRLd] on [dbo].[bAPRL] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/2/98
    *  Modified: EN 11/2/98
    *			MV 10/18/02 - 18878 quoted identifier cleanup.
    *
    *  Adds entry to HQ Master Audit if APCO.AuditRecur = 'Y'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* Audit AP Recurring Invoice Line deletions */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPRL',' VendorGroup: ' + convert(varchar(3),d.VendorGroup)
   		 + ' Vendor: ' + convert(varchar(6),d.Vendor)
   		 + ' InvId: ' + d.InvId
   		 + ' Line: ' + convert(varchar(5),d.Line), d.APCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN bAPCO c ON d.APCo = c.APCo
           where c.AuditRecur = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Recurring Invoice Line!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btAPRLi    Script Date: 8/28/99 9:36:56 AM ******/
   CREATE trigger [dbo].[btAPRLi] on [dbo].[bAPRL] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: EN 10/29/98
    *  Modified: EN 10/29/98
    *            CMW 04/03/02 - increased InvId from 5 to 10 char (issue # 16366)
    *
    * Reject if entry in bAPRH does not exist.
    * If flagged for auditing recurring invoices, inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   set nocount on
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   /* check Recurring Invoice Header */
   SELECT @validcnt = count(*) FROM bAPRH h
   	JOIN inserted i ON h.APCo = i.APCo and h.VendorGroup = i.VendorGroup
   		and h.Vendor = i.Vendor and h.InvId = i.InvId
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Recurring Invoice Header does not exist'
   	GOTO error
   	END
   /* Audit inserts */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bAPRL',' VendorGroup: ' + convert(char(3), i.VendorGroup)
   		 + ' Vendor: ' + convert(varchar(6), i.Vendor)
   		 + ' InvId: ' + convert(char(10),i.InvId)
   		 + ' Line: ' + convert(varchar(2),i.Line), i.APCo, 'A',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
   		join bAPCO c on c.APCo = i.APCo
   		where i.APCo = c.APCo and c.AuditRecur = 'Y'
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert AP Recurring Invoice Line!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPRLu    Script Date: 8/28/99 9:36:56 AM ******/
   CREATE   trigger [dbo].[btAPRLu] on [dbo].[bAPRL] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/2/98
    *  Modified: EN 11/2/98
    *			MV 10/18/02 - 18878 quoted identifier cleanup.
    *			MV 03/04/04 - 18769 - add PayCategory to audit.
    *
    * Reject primary key changes.
    * If Recurring invoices flagged for auditing, inserts HQ Master Audit entries
    *	for changed value.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check for key changes */
   select @validcnt = count(*) from deleted d
       join inserted i on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
       	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change key information.'
   	goto error
   	end
   /* Insert records into HQMA for changes made to audited fields */
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'LineType', convert(varchar(3),d.LineType), convert(varchar(3),i.LineType), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.LineType <> i.LineType and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'PO', d.PO, i.PO, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.PO <> i.PO and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'POItem', convert(varchar(5),d.POItem), convert(varchar(5),i.POItem), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.POItem <> i.POItem and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'ItemType', convert(varchar(3),d.ItemType), convert(varchar(3),i.ItemType), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.ItemType <> i.ItemType and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'SL', d.SL, i.SL, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.SL <> i.SL and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'SLItem', convert(varchar(5),d.SLItem), convert(varchar(5),i.SLItem), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.SLItem <> i.SLItem and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'JCCo', convert(varchar(3),d.JCCo), convert(varchar(3),i.JCCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.JCCo <> i.JCCo and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Job', convert(varchar(9),d.Job), convert(varchar(9),i.Job), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Job <> i.Job and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'PhaseGroup', convert(varchar(3),d.PhaseGroup), convert(varchar(3),i.PhaseGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.PhaseGroup <> i.PhaseGroup and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Phase', convert(varchar(13),d.Phase), convert(varchar(13),i.Phase), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Phase <> i.Phase and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'JCCType', convert(varchar(3),d.JCCType), convert(varchar(3),i.JCCType), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.JCCType <> i.JCCType and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'EMCo', convert(varchar(3),d.EMCo), convert(varchar(3),i.EMCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.EMCo <> i.EMCo and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'WO', d.WO, i.WO, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.WO <> i.WO and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'WOItem', convert(varchar(5),d.WOItem), convert(varchar(5),i.WOItem), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.WOItem <> i.WOItem and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Equip', d.Equip, i.Equip, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Equip <> i.Equip and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'EMGroup', convert(varchar(3),d.EMGroup), convert(varchar(3),i.EMGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.EMGroup <> i.EMGroup and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'CostCode', d.CostCode, i.CostCode, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.CostCode <> i.CostCode and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'EMCType', convert(varchar(3),d.EMCType), convert(varchar(3),i.EMCType), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.EMCType <> i.EMCType and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'INCo', convert(varchar(3),d.INCo), convert(varchar(3),i.INCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.INCo <> i.INCo and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Loc', d.Loc, i.Loc, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Loc <> i.Loc and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'MatlGroup', convert(varchar(3),d.MatlGroup), convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.MatlGroup <> i.MatlGroup and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Material', d.Material, i.Material, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Material <> i.Material and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'GLCo', convert(varchar(3),d.GLCo), convert(varchar(3),i.GLCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.GLCo <> i.GLCo and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'GLAcct', convert(varchar(10),d.GLAcct), convert(varchar(10),i.GLAcct), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.GLAcct <> i.GLAcct and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Description <> i.Description and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.UM <> i.UM and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Units', convert(varchar(15),d.Units), convert(varchar(15),i.Units), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Units <> i.Units	 and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'UnitCost', convert(varchar(20),d.UnitCost), convert(varchar(20),i.UnitCost), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.UnitCost <> i.UnitCost and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'ECM', d.ECM, i.ECM, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.ECM <> i.ECM and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Supplier', convert(varchar(6),d.Supplier), convert(varchar(6),i.Supplier), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Supplier <> i.Supplier and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'PayType', convert(varchar(3),d.PayType), convert(varchar(3),i.PayType), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.PayType <> i.PayType and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'GrossAmt', convert(varchar(16),d.GrossAmt), convert(varchar(16),i.GrossAmt), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.GrossAmt <> i.GrossAmt and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'MiscAmt', convert(varchar(16),d.MiscAmt), convert(varchar(16),i.MiscAmt), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.MiscAmt <> i.MiscAmt and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'MiscYN', d.MiscYN, i.MiscYN, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.MiscYN <> i.MiscYN and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'TaxGroup', convert(varchar(3),d.TaxGroup), convert(varchar(3),i.TaxGroup), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.TaxGroup <> i.TaxGroup and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.TaxCode <> i.TaxCode and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'TaxType', convert(varchar(3),d.TaxType), convert(varchar(3),i.TaxType), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.TaxType <> i.TaxType and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'TaxBasis', convert(varchar(16),d.TaxBasis), convert(varchar(16),i.TaxBasis), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.TaxBasis <> i.TaxBasis and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'TaxAmt', convert(varchar(16),d.TaxAmt), convert(varchar(16),i.TaxAmt), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.TaxAmt <> i.TaxAmt and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Retainage', convert(varchar(16),d.Retainage), convert(varchar(16),i.Retainage), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Retainage <> i.Retainage and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'Discount', convert(varchar(16),d.Discount), convert(varchar(16),i.Discount), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.Discount <> i.Discount and a.AuditRecur = 'Y'
   insert into bHQMA select 'bAPRL', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   		+ ' Vendor: ' + convert(varchar(6), i.Vendor)
    		+ ' InvId: ' + i.InvId
    		+ ' Line: ' + convert(varchar(5), i.Line), i.APCo, 'C',
   	'PayCategory', convert(varchar(3),d.PayCategory), convert(varchar(3),i.PayCategory), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId and d.Line = i.Line
   	join APCO a on a.APCo = i.APCo
   	where d.PayCategory <> i.PayCategory and a.AuditRecur = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot update Recurring Invoice Line!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPRL] ON [dbo].[bAPRL] ([APCo], [VendorGroup], [Vendor], [InvId], [Line]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPRL].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPRL].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPRL].[MiscYN]'
GO
