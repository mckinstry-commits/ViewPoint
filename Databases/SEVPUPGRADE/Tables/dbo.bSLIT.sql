CREATE TABLE [dbo].[bSLIT]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NOT NULL,
[ItemType] [tinyint] NOT NULL,
[Addon] [tinyint] NULL,
[AddonPct] [dbo].[bPct] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[WCRetPct] [dbo].[bPct] NOT NULL,
[SMRetPct] [dbo].[bPct] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Supplier] [dbo].[bVendor] NULL,
[OrigUnits] [dbo].[bUnits] NOT NULL,
[OrigUnitCost] [dbo].[bUnitCost] NOT NULL,
[OrigCost] [dbo].[bDollar] NOT NULL,
[CurUnits] [dbo].[bUnits] NOT NULL,
[CurUnitCost] [dbo].[bUnitCost] NOT NULL,
[CurCost] [dbo].[bDollar] NOT NULL,
[StoredMatls] [dbo].[bDollar] NOT NULL,
[InvUnits] [dbo].[bUnits] NOT NULL,
[InvCost] [dbo].[bDollar] NOT NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[AddedMth] [dbo].[bMonth] NULL,
[AddedBatchID] [dbo].[bBatchID] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[TaxType] [tinyint] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[OrigTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIT_OrigTax] DEFAULT ((0.00)),
[CurTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIT_CurTax] DEFAULT ((0.00)),
[InvTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIT_InvTax] DEFAULT ((0.00)),
[JCCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIT_JCCmtdTax] DEFAULT ((0.00)),
[TaxRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bSLIT_TaxRate] DEFAULT ((0.00)),
[GSTRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bSLIT_GSTRate] DEFAULT ((0.00)),
[JCRemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIT_JCRemCmtdTax] DEFAULT ((0.00)),
[udSLContractNo] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btSLITd    Script Date: 8/28/99 9:38:18 AM ******/
CREATE  trigger [dbo].[btSLITd] on [dbo].[bSLIT] for DELETE as

/*--------------------------------------------------------------
     *
     *  Delete trigger for SLIT
     *  Created By: LM 2/27/99
     *  Modified By: LM 11/3/99
     *               EN 3/27/00 - Added HQ Auditing and completed validation as specified in Erwin Design notes
     *               EN 4/27/00 - Only verify that Invoiced = Current if Invoiced is not 0.
     *               GF 07/17/2001 - Changed delete for PM to an update setting InterfaceDate to null and send flag to 'N'.
     *               kb 8/7/1 - issue #14268
     *				  GG 10/03/02 - #18508 - fix message for existing Change Order detail
	 *				GF 02/14/2006 - issue #120167 when purging to not update bPMSL.
     *
     *
     *--------------------------------------------------------------*/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int, @typecnt int
   
     select @numrows = @@rowcount
     if @numrows = 0 return
   
     set nocount on
    
     -- reject if Invoiced <> Current
    if exists(select * from bSLHD c join deleted d on c.SLCo=d.SLCo and c.SL=d.SL and Purge= 'Y')
      and exists(select * from deleted where (InvCost <> CurCost and InvUnits <> CurUnits))
        begin
        select @errmsg = 'Invoiced must equal Current '
        goto error
        end
    
    -- (P='N'): Cannot delete an item if there are any invoiced costs or units
    if exists(select * from bSLHD c join deleted d on c.SLCo=d.SLCo and c.SL=d.SL and Purge = 'N')
      and exists(select * from deleted where (InvCost <> 0 and InvUnits <> 0))
        begin
        select @errmsg = 'Invoiced Costs and Units must be zero '
        goto error
        end
    
    -- (P='N'):reject if Change Detail exists
    select @validcnt = count(*) from bSLHD c join deleted d on c.SLCo=d.SLCo and c.SL=d.SL
        where (exists (select * from bSLCD s where s.SLCo=d.SLCo and s.SL=d.SL and s.SLItem=d.SLItem)) and c.Purge = 'N'
    if @validcnt <> 0
        begin
        select @errmsg = 'Change Order detail exists '
        goto error
        end


-- -- -- Update related PMSL records
-- -- -- if not purging SL's then set interface date to null and send flag to 'N'
-- -- -- otherwise do not do anything with PMSL records
update bPMSL Set InterfaceDate=NULL ----, SendFlag='N'
from bPMSL p
join deleted d on p.PMCo=d.JCCo and p.Project=d.Job and p.SLCo=d.SLCo and p.SL=d.SL and p.SLItem=d.SLItem
join bSLHD h on d.SLCo=h.SLCo and d.SL=h.SL and h.Purge = 'N'
where p.PMCo=d.JCCo and p.Project=d.Job and p.SLCo=d.SLCo and p.SL=d.SL 
and p.SLItem=d.SLItem and p.InterfaceDate is not null
-- -- -- -- -- -- Update related PM records
-- -- -- Update PMSL Set InterfaceDate=null, SendFlag='N'
-- -- -- from PMSL p join deleted d on p.PMCo=d.JCCo and p.Project=d.Job and p.SLCo=d.SLCo and p.SL=d.SL and p.SLItem=d.SLItem
-- -- -- where p.PMCo=d.JCCo and p.Project=d.Job and p.SLCo=d.SLCo and p.SL=d.SL and p.SLItem=d.SLItem and p.InterfaceDate is not null




-- -- -- HQ Auditing
insert bHQMA select 'bSLIT', 'SL:' + d.SL + ' Item:' + convert(varchar(6),d.SLItem),
        d.SLCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d
join bSLCO c on d.SLCo = c.SLCo
join bSLHD h on d.SLCo = h.SLCo and d.SL = h.SL
where c.AuditSLs = 'Y' and h.Purge = 'N'  -- check audit and purge flags



return



error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete from SLIT'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btSLITi    Script Date: 8/28/99 9:38:17 AM ******/
   
    CREATE    trigger [dbo].[btSLITi] on [dbo].[bSLIT] for INSERT as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @validcnt int, @validcnt2 int, @slco bCompany, @sl VARCHAR(30), --bSL, DC #135813
    @slitem bItem,
    @jcco bCompany, @job bJob, @phase bPhase, @jcctype bJCCType, @contract bContract,
    @status tinyint, @lockphases bYN, @taxcode bTaxCode, @desc varchar(60), @desc1 varchar(255),
    @override char(1), @phasegroup tinyint, @pphase bPhase, @billflag char(1), @um bUM,
    @itemunitflag bYN, @phaseunitflag bYN, @JCCHexists char(1), @costtypeout bJCCType, @errmsg varchar(255),
    @rcode int, @jcum bUM, @glco bCompany, @glacct bGLAcct
   
    /*--------------------------------------------------------------
     *
     *  Insert trigger for SLIT
     *  Created By: EN  2/27/00
     *  Modified By: EN 4/5/00 - removed SL company validation; it caused an error and was not really necessary
     *                             actually error was caused because of @numrows getting set wrong due to @rcode
     *                             being set before getting that value; moved @rcode init to be after @numrows init
     *               DANF 09/05/02 - Added Phase group to bspJobTypeVal
     *				  RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
     *					DC 6/30/10 - #135813 - expand subcontract number
     *
     *  Validate SL in bSLHD.
     *  ItemType must be 1, 2, 3, or 4.
     *  If ItemType=2, verify that all Original values = 0.
     *  If ItemType=4, validate Addon in bSLAD and verify that UM='LS'.
     *  If ItemType<>4, verify that Addon is null and AddonPct=0.
     *  JCCo must match the one in bSLHD.
     *  Validate Job, Phase, and CostType as per std.
     *  Validate UM.
     *  If UM='LS', Units and UnitCost must be 0.
     *  Validate GLCo.
     *  Validate GLAcct; it must also be active and have SubType='J' or null
     *  Validate Supplier in bAPVM is not null.
     *  Add audit in bHQMA if bSLCO option used.
     *--------------------------------------------------------------*/
   
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
     select @rcode = 0
   
   /* validate SL */
   select @validcnt = count(1) from SLHD c join inserted i on i.SLCo = c.SLCo and i.SL = c.SL
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Missing Subcontract Header ' + convert(varchar(5), @validcnt)
   	goto error
   	end
   
   -- make sure ItemType value is 1, 2, 3 or 4
   select @validcnt = count(1) from inserted
       where ItemType = 1 or ItemType = 2 or ItemType = 3 or ItemType = 4
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Item Type must be 1, 2, 3 or 4 '
       goto error
       end
   
   -- if ItemType=2, verify that all Original values = 0
   select @validcnt = count(1) from inserted
       where ItemType = 2 and (OrigUnits <> 0 or OrigUnitCost <> 0 or OrigCost <> 0)
   if @validcnt <> 0
       begin
       select @errmsg = 'Type 2 (Change Order) Original value must be 0 '
       goto error
       end
   
   -- if ItemType=4, validate Addon in bSLAD
   select @validcnt2 = count(1) from inserted where ItemType = 4 and Addon is not null
   select @validcnt = count(1) from bSLAD r
       join inserted i on i.SLCo = r.SLCo and i.Addon = r.Addon
       where i.ItemType = 4 and i.Addon is not null
   if @validcnt <> @validcnt2
      begin
      select @errmsg = 'Invalid Addon '
      goto error
      end
   
   -- if ItemType=4, verify that UM='LS'
   select @validcnt = count(1) from inserted where ItemType = 4 and UM <> 'LS'
   if @validcnt <> 0
      begin
      select @errmsg = 'UM must equal (LS) for Type 4 (Addon) Items '
      goto error
      end
   
   -- if ItemType<>4, verify that Addon is null and AddonPct=0
   select @validcnt = count(1) from inserted where ItemType <> 4 and (Addon is not null or AddonPct <> 0)
   if @validcnt <> 0
      begin
      select @errmsg = 'Addon must be null and percent equal to 0 for Items other than Type 4 '
      goto error
      end
   
   -- validate UM in bHQUM
   select @validcnt = count(1) from bHQUM r
       join inserted i on i.UM = r.UM
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Unit of Measure '
       goto error
       end
   
   -- verify that JCCo matches the one in bSLHD
   select @validcnt = count(1) from bSLHD r
       join inserted i on i.SLCo = r.SLCo and i.SL = r.SL
       where i.JCCo = r.JCCo
   if @validcnt <> @numrows
       begin
       select @errmsg = 'JC Company does not match SL Header '
       goto error
       end
   
   -- validate Job, Phase, CostType, GL Acct
   SELECT @slco=MIN(SLCo) from inserted
      WHILE @slco IS NOT NULL
      BEGIN
        SELECT @sl=MIN(SL) from inserted where SLCo=@slco
        WHILE @sl IS NOT NULL
        BEGIN
           SELECT @slitem=MIN(SLItem) from inserted where SLCo=@slco and SL=@sl
           WHILE @slitem IS NOT NULL
           BEGIN
               select @jcco=JCCo, @phasegroup = PhaseGroup, @job=Job, @phase=Phase, @jcctype=JCCType, @glco=GLCo, @glacct=GLAcct from inserted
               where SLCo=@slco and SL=@sl and SLItem=@slitem
   
       		exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
       		if @rcode <> 0 goto error
   
       		exec @rcode = bspGLACfPostable @glco, @glacct, 'J', @errmsg output
       		if @rcode <> 0 goto error
   
               SELECT @slitem=MIN(SLItem) from inserted where SLCo=@slco
               and SL=@sl and SLItem>@slitem
           END
           SELECT @sl=MIN(SL) from inserted where SLCo=@slco and SL>@sl
        END
        SELECT @slco=MIN(SLCo) from inserted where SLCo>@slco
      END
   
   -- if UM='LS', Units and UnitCost must be 0
   select @validcnt = count(*) from inserted where UM = 'LS' and (OrigUnits <> 0 or OrigUnitCost <> 0)
   if @validcnt <> 0
       begin
       select @errmsg = 'Units and Unit Cost must be 0 when Unit of Measure is (LS) '
       goto error
       end
   
   -- validate Supplier in bAPVM
   select @validcnt2 = count(1) from inserted where Supplier is null
   select @validcnt = count(1) from bAPVM c
       join inserted i on c.VendorGroup = i.VendorGroup and c.Vendor = i.Supplier
       where i.Supplier is not null
   if @validcnt + @validcnt2 <> @numrows
   	begin
   	select @errmsg = 'Invalid Supplier '
   	goto error
   	end
   
   -- HQ Auditing
   insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bSLIT', 'SL:' + i.SL + ' Item:' + convert(varchar(6),i.SLItem), i.SLCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   from inserted i
   join bSLCO c on i.SLCo = c.SLCo
   where c.AuditSLs = 'Y'
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert SL Items'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btSLITu    Script Date: 8/28/99 9:38:18 AM ******/
   CREATE trigger [dbo].[btSLITu] on [dbo].[bSLIT] for UPDATE as
   

/*--------------------------------------------------------------
    * Created: GG 12/03/98
    * Modified: GG 01/14/99
    *           EN 3/27/00 - Added HQ Auditing and completed validation as specified in Erwin Design notes
    *           EN 4/4/00 - commented out code to reject changes to certain fields as it seems to be causing some problems in QA
    *                          will research whether this validation is needed at all or needs to be modified
    *           GG 05/16/00 - Dropped PrevWC and WC columns from bSLIT - removed update
    *			 GF 08/12/2003 - issue #22112 - performance
    *
    * Update trigger to validate column values.
    * Keep Work Complete units and dollars in synch with Invoiced values
    * Check for possible HQ auditing.
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   if update(SLCo) or update(SL) or update(SLItem)
   	-- select @validcnt = count(*) from deleted d
       -- join inserted i on i.SLCo=d.SLCo and i.SL=d.SL and i.SLItem=d.SLItem
   	-- if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Cannot change Primary key'
    	goto error
    	end
   
   -- reject changes to certain fields if transaction lines or change detail exists
   -- select @validcnt = count(*) from deleted d
   --     join inserted i on i.SLCo=d.SLCo and i.SL=d.SL and i.SLItem=d.SLItem
   --     where (exists (select * from bSLCD s where s.SLCo=i.SLCo and s.SL=i.SL and s.SLItem=i.SLItem) or
   --             exists (select * from bAPTL t where t.APCo=i.SLCo and t.SL=i.SL and t.SLItem=i.SLItem))
   --     and (i.ItemType<>d.ItemType or i.Addon<>d.Addon or i.JCCo<>d.JCCo or i.Job<>d.Job or i.Phase<>d.Phase or i.JCCType<>d.JCCType or i.UM<>d.UM)
   -- if @validcnt <> @numrows
   --     begin
   --     select @errmsg = 'Cannot change ItemType, Addon, Job, Phase, CostType or UM if transaction lines or change detail exists'
   --     goto error
   --     end
   
   -- validate Supplier in bAPVM
   if update(Supplier)
       begin
       select @validcnt2 = count(*) from inserted where Supplier is null
       select @validcnt = count(*) from bAPVM c with (nolock)
           join inserted i on c.VendorGroup = i.VendorGroup and c.Vendor = i.Supplier
           where i.Supplier is not null
       if @validcnt + @validcnt2 <> @numrows
       	begin
       	select @errmsg = 'Invalid Supplier '
       	goto error
       	end
       end
   
   -- removed PrevWC and WC columns from bSLIT
   /*-- keep Work Complete in sync with changes to Invoiced amounts
   if update(InvCost)
   	begin
      	update bSLIT set bSLIT.WCCost = i.InvCost - i.PrevWCCost - i.StoredMatls
      	from bSLIT join inserted i on bSLIT.SLCo = i.SLCo and bSLIT.SL = i.SL and bSLIT.SLItem = i.SLItem
         	if @@rowcount = 0
         		begin
            	select @errmsg = 'Unable to update Work Completed in SL Items. '
           	goto error
         		end
      	end
   if update(InvUnits)
   	begin
   	update bSLIT set bSLIT.WCUnits = i.InvUnits - i.PrevWCUnits
   	from bSLIT join inserted i on bSLIT.SLCo = i.SLCo and bSLIT.SL = i.SL and bSLIT.SLItem = i.SLItem
         	if @@rowcount = 0
         		begin
            	select @errmsg = 'Unable to update Work Completed Units in SL Items. '
           	goto error
         		end
      	end
   */
   
   
   -- Insert records into HQMA for changes made to audited fields
   if not exists (select top 1 1 from inserted i join bSLCO c with (nolock) on c.SLCo = i.SLCo where c.AuditSLs = 'Y')
   	return
   
   if update(ItemType)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Item Type', Convert(varchar(2),d.ItemType), Convert(varchar(2),i.ItemType), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.ItemType <> d.ItemType and c.AuditSLs = 'Y'
   
   if update(Addon)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Addon', d.Addon, i.Addon, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where isnull(i.Addon,0) <> isnull(d.Addon,0) and c.AuditSLs = 'Y'
   
   if update(AddonPct)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Addon Percent', d.AddonPct, i.AddonPct, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.AddonPct <> d.AddonPct and c.AuditSLs = 'Y'
   
   if update(JCCo)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'JC Company', convert(varchar(3),d.JCCo), convert(varchar(3),i.JCCo), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.JCCo <> d.JCCo and c.AuditSLs = 'Y'
   
   if update(Job)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Job', convert(varchar(10),d.Job), convert(varchar(10),i.Job), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.Job <> d.Job and c.AuditSLs = 'Y'
   
   if update(PhaseGroup)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Phase Group', convert(varchar(3),d.PhaseGroup), convert(varchar(3),i.PhaseGroup), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.PhaseGroup <> d.PhaseGroup and c.AuditSLs = 'Y'
   
   if update(Phase)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Phase', convert(varchar(14),d.Phase), convert(varchar(14),i.Phase), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.Phase <> d.Phase and c.AuditSLs = 'Y'
   
   if update(JCCType)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'JC Cost Type', convert(varchar(3),d.JCCType), convert(varchar(3),i.JCCType), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.JCCType <> d.JCCType and c.AuditSLs = 'Y'
   
   if update(Description)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where isnull(i.Description,'') <> isnull(d.Description,'') and c.AuditSLs = 'Y'
   
   if update(UM)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Unit of Measure', d.UM, i.UM, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.UM <> d.UM and c.AuditSLs = 'Y'
   
   if update(GLCo)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'GL Company', convert(varchar(3),d.GLCo), convert(varchar(3),i.GLCo), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.GLCo <> d.GLCo and c.AuditSLs = 'Y'
   
   if update(GLAcct)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'GL Account', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.GLAcct <> d.GLAcct and c.AuditSLs = 'Y'
   
   if update(SMRetPct)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'SM Retainage Percent', convert(varchar(8),d.SMRetPct), convert(varchar(8),i.SMRetPct), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.SMRetPct <> d.SMRetPct and c.AuditSLs = 'Y'
   
   if update(VendorGroup)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Vendor Group', convert(varchar(3),d.VendorGroup), convert(varchar(3),i.VendorGroup), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.VendorGroup <> d.VendorGroup and c.AuditSLs = 'Y'
   
   if update(Supplier)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Supplier', convert(varchar(6),d.Supplier), convert(varchar(6),i.Supplier), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where isnull(i.Supplier,'') <> isnull(d.Supplier,'') and c.AuditSLs = 'Y'
   
   if update(OrigUnits)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Original Units', convert(varchar(15),d.OrigUnits), convert(varchar(15),i.OrigUnits), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.OrigUnits <> isnull(d.OrigUnits,0) and c.AuditSLs = 'Y'
   
   if update(OrigUnitCost)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Original Unit Cost', convert(varchar(20),d.OrigUnitCost), convert(varchar(20),i.OrigUnitCost), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.OrigUnitCost <> d.OrigUnitCost and c.AuditSLs = 'Y'
   
   if update(OrigCost)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Original Cost', convert(varchar(16),d.OrigCost), convert(varchar(16),i.OrigCost), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.OrigCost <> d.OrigCost and c.AuditSLs = 'Y'
   
   if update(StoredMatls)
       insert into bHQMA select 'bSLIT', 'SL:' + i.SL + ' Item: ' + convert(varchar(6),i.SLItem), i.SLCo, 'C',
        	'Stored Materials', convert(varchar(16),d.StoredMatls), convert(varchar(16),i.StoredMatls), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL and i.SLItem = d.SLItem
       join bSLCO c with (nolock) on c.SLCo = i.SLCo
       where i.StoredMatls <> d.StoredMatls and c.AuditSLs = 'Y'
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update SL Items'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bSLIT] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biSLIT] ON [dbo].[bSLIT] ([SLCo], [SL], [SLItem]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bSLIT].[OrigUnitCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bSLIT].[CurUnitCost]'
GO
