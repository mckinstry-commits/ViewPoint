CREATE TABLE [dbo].[bAPTL]
(
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APLine] [smallint] NOT NULL,
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
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bAPTL_UnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
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
[BurUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bAPTL_BurUnitCost] DEFAULT ((0)),
[BECM] [dbo].[bECM] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[POPayTypeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPTL_POPayTypeYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[PayCategory] [int] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Receiver#] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SLKeyID] [bigint] NULL,
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[Scope] [int] NULL,
[SMStandardItem] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[POItemLine] [int] NULL,
[SMCostType] [smallint] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[SMPhaseGroup] [dbo].[bGroup] NULL,
[SubjToOnCostYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPTL_SubjToOnCostYN] DEFAULT ('N'),
[OnCostStatus] [tinyint] NULL,
[ocApplyMth] [dbo].[bMonth] NULL,
[ocApplyTrans] [dbo].[bTrans] NULL,
[ocApplyLine] [smallint] NULL,
[ATOCategory] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ocSchemeID] [smallint] NULL,
[ocMembershipNbr] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SMPhase] [dbo].[bPhase] NULL,
[udPaidAmt] [decimal] (12, 2) NULL,
[udYSN] [decimal] (12, 0) NULL,
[ud1099Type] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[udRCCD] [int] NULL,
[udSubHistYN] [char] (1) COLLATE Latin1_General_BIN NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPTL] ON [dbo].[bAPTL] ([APCo], [Mth], [APTrans], [APLine]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biAPTLJob] ON [dbo].[bAPTL] ([Job]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPTL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biAPTLPO ] ON [dbo].[bAPTL] ([PO]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biAPTLSL] ON [dbo].[bAPTL] ([SL]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_bAPTL_SLKeyID] ON [dbo].[bAPTL] ([SLKeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bAPTL] ADD
CONSTRAINT [CK_bAPTL_BECM] CHECK (([BECM]='E' OR [BECM]='C' OR [BECM]='M' OR [BECM] IS NULL))
ALTER TABLE [dbo].[bAPTL] ADD
CONSTRAINT [CK_bAPTL_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
ALTER TABLE [dbo].[bAPTL] ADD
CONSTRAINT [CK_bAPTL_MiscYN] CHECK (([MiscYN]='Y' OR [MiscYN]='N'))
ALTER TABLE [dbo].[bAPTL] ADD
CONSTRAINT [CK_bAPTL_POPayTypeYN] CHECK (([POPayTypeYN]='Y' OR [POPayTypeYN]='N'))
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
 CREATE trigger [dbo].[btAPTLd] on [dbo].[bAPTL] for DELETE as
/*-----------------------------------------------------------------
    * Created By:	EN 11/1/98
    * Modified By: EN 11/1/98
    *				MV 10/18/02 - 18878 quoted identifier cleanup.
    *				GF 08/12/2003 - issue #22112 - performance
	*				MV 02/05/09 - #123778 - clear bPORD Invoice Info
	*				MV 11/25/09 - #136212 - tightened PORD where clause
	*				GF 12/03/2010 - issue #141957 record association
	*				MV 08/04/11 TK-07233 AP project to use POItemLine
	*				GF 04/25/2013 TFS-48153 remove MSTD values using APTL KeyId and MSTD Matl/Haul KeyId's
	*
    *
    *  This trigger restricts deletion if detail exists in APTD.
    *  Adds entry to HQ Master Audit if APCO.AuditPay = 'Y' and
    *  APPH.PurgeYN = 'N'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @apco bCompany,
   		@mth bMonth, @aptrans bTrans, @duedate bDate
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   if exists(select 1 from bAPTD a with (nolock), deleted d where a.APCo=d.APCo and a.Mth=d.Mth
   	and a.APTrans=d.APTrans and a.APLine=d.APLine)
   	begin
   	select @errmsg='Details exist for this line'
   	goto error
   	end

	--clear bPORD fields of Invoice Info
	IF EXISTS (
				SELECT 1
				FROM dbo.bPORD r
				JOIN deleted d ON r.POCo=d.APCo AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine AND
					(
						r.Receiver# IS NOT NULL AND r.Receiver#=d.Receiver#
					)
				WHERE r.POCo=d.APCo AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine AND
					r.APMth=d.Mth AND r.APTrans=d.APTrans AND r.APLine=d.APLine
			  )
	BEGIN
		UPDATE dbo.bPORD SET APMth= null, APTrans=null, APLine=null
		FROM dbo.bPORD r
		JOIN deleted d ON r.POCo=d.APCo AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine AND r.Receiver#=d.Receiver#
		WHERE r.POCo=d.APCo AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine 
			AND APMth=d.Mth AND r.APTrans=d.APTrans AND r.APLine=d.APLine
	END


---- check for related records and delete
IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'vPMRelateRecord')
	BEGIN
	---- record side
	DELETE FROM dbo.vPMRelateRecord
	FROM deleted d WHERE RecTableName = 'APTL' AND d.KeyID= RECID
	---- link side
	DELETE FROM dbo.vPMRelateRecord
	FROM deleted d WHERE LinkTableName = 'APTL' AND d.KeyID= LINKID
	END


----TFS-48153 update MSTD and clear out hauler payment columns if found
IF EXISTS(SELECT 1
				FROM dbo.bMSTD MSTD WITH (NOLOCK)
				JOIN deleted d ON MSTD.HaulAPTLKeyID = d.KeyID)
	BEGIN
   	---- update MSTD to clear out AP values
	UPDATE dbo.bMSTD
			SET APCo = NULL, APMth = NULL, APRef = NULL, HaulAPTLKeyID = NULL
	from dbo.bMSTD MSTD
	INNER JOIN deleted d ON d.KeyID = MSTD.HaulAPTLKeyID
	LEFT JOIN dbo.bAPTH APTH ON APTH.APCo = d.APCo AND APTH.Mth = d.Mth	AND APTH.APTrans = d.APTrans
	WHERE APTH.Purge = 'N'
	END

----TFS-48153 update MSTD and clear out material payment columns if found
IF EXISTS(SELECT 1
				FROM dbo.bMSTD MSTD WITH (NOLOCK)
				JOIN deleted d ON MSTD.MatlAPTLKeyID = d.KeyID)
	BEGIN
   	---- update MSTD to clear out AP values
	UPDATE dbo.bMSTD
			SET MatlAPCo = NULL, MatlAPMth = NULL, MatlAPRef = NULL, MatlAPTLKeyID = NULL
	from dbo.bMSTD MSTD
	INNER JOIN deleted d ON d.KeyID = MSTD.MatlAPTLKeyID
	LEFT JOIN dbo.bAPTH APTH ON APTH.APCo = d.APCo AND APTH.Mth = d.Mth	AND APTH.APTrans = d.APTrans
	WHERE APTH.Purge = 'N'
	END


   -- Audit AP Transaction Line deletions
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPTL',' Mth: ' + convert(varchar(8),d.Mth,1)
   		 + ' APTrans: ' + convert(varchar(6),d.APTrans)
   		 + ' APLine: ' + convert(varchar(5),d.APLine),
             d.APCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN bAPCO c with (nolock) ON d.APCo = c.APCo
   	JOIN bAPTH h ON d.APCo = h.APCo and d.Mth = h.Mth and d.APTrans = h.APTrans
   	where c.AuditPay = 'Y' and h.Purge = 'N'
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Transaction Line!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 




GO
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Trigger dbo.btAPTLi    Script Date: 8/28/99 9:36:58 AM ******/
   CREATE  trigger [dbo].[btAPTLi] on [dbo].[bAPTL] for INSERT as
   


/*-----------------------------------------------------------------
    *  Created: EN 10/29/98
    *  Modified: GG 07/02/99
    *            GR 01/18/00  --corrected validation on cost type/ cost code combination
    *			  SR 07/09/02 - issue 17738 pass @phasegroup to bspJCVPHASE
    *			  MV 10/18/02 - 18878 quoted identifier cleanup.
    *			  GF 08/12/2003 - issue #22112 - performance
    *           MV 06/30/08 - #128288 - Taxtype 3 - VAT
	*			MV 02/09/09 - #123778 - update bPORD with Invoice Info
    *			MV 05/11/09 - #123778 - fix bPORD update joins
    *			GP 6/6/2010 - #135813 changed bSL to varchar(30)
    *			GF 11/02/2010 - issue #141957 record association
    *			AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
    *			MH 03/26/11 - TK-02798 Update APSM with APTL.KeyID
    *			GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
    *			MV 08/04/11 - TK-07233 AP project to use POItemLine
    *
    *
    * Reject if not in bAPTH.
    * Validates various combinations of fields depending on line type.
    * Validates GLCo, GLAcct, Supplier (if not null), PayType and tax info.
    * If flagged for auditing transactions, inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   DECLARE @errmsg varchar(255),
    @validcnt int,
    @nullcnt int,
    @numrows int
   DECLARE @apco bCompany,
			@linetype tinyint,
			@jcco bCompany,
			@job bJob,
			@phasegroup bGroup,
			@phase bPhase,
			@jcctype bJCCType,
			@inco bCompany,
			@loc bLoc,
			@matlgroup bGroup,
			@material bMatl,
			@emco bCompany,
			@equip bEquip,
			@emgroup bGroup,
			@costcode bCostCode,
			@emctype bEMCType,
			@wo bWO,
			@woitem bItem,
			@po varchar(30),
			@poitem bItem,
			@POItemLine int,
			@itemtype tinyint,
			@sl varchar(30),
			@slitem bItem,
			@pp bPhase,
			@descr varchar(30),
			@dept varchar(10),
			@projminpct real,
			--#142350 - renaming @PhaseGroup
			@PhaseGroupOut tinyint,
			@vcontract bContract,
			@vitem bContractItem,
			@JCJPexists char(1),
			@rcode int,
			@stringct varchar(5),
			@override bYN,
			@phsgroup tinyint,
			@pphase bPhase,
			@billflag char(1),
			@um bUM,
			@itemunitflag bYN,
			@phaseunitflag bYN,
			@JCCHexists char(1),
			@costtypeout bJCCType,
			@receiver# varchar(20),
			@mth bMonth,
			@aptrans int,
			@apline int,
			---#141957
			@KeyID bigint
   
   
   
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   
   -- check Transaction Header
   SELECT @validcnt = count(*) FROM bAPTH h (nolock)
   JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Transaction Header does not exist'
   	GOTO error
   	END
   
   -- validate GL Company
   SELECT @validcnt = count(*) FROM bGLCO c (nolock) JOIN inserted i ON c.GLCo = i.GLCo
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid GL Company'
   	GOTO error
   	END
   
   -- validate GL Account
   SELECT @validcnt = count(*) FROM bGLAC v (nolock)
   JOIN inserted i ON v.GLCo = i.GLCo and v.GLAcct = i.GLAcct
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid GL Account'
   	GOTO error
   	END
   
   -- validate supplier
   select @nullcnt = count(*) from inserted where Supplier is null
   SELECT @validcnt = count(*) FROM inserted i JOIN bAPVM v (nolock) ON v.VendorGroup=i.VendorGroup and v.Vendor=i.Supplier
   if @nullcnt + @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid Supplier'
   	GOTO error
   	END
   
   -- validate PayType
   SELECT @validcnt = count(*) FROM bAPPT p (nolock)
   JOIN inserted i ON p.APCo = i.APCo and p.PayType = i.PayType
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid payment type'
   	GOTO error
   	END
   
   -- validate tax information
   select @nullcnt = count(*) from inserted where TaxGroup is null or TaxCode is null
   SELECT @validcnt = count(*) FROM bHQTX t (nolock)
   JOIN inserted i ON i.TaxGroup = t.TaxGroup and i.TaxCode = t.TaxCode
   IF @nullcnt + @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid tax group/tax code'
   	GOTO error
   	END
   
   SELECT @validcnt = count(*) FROM inserted 
   WHERE TaxGroup is not null and TaxCode is not null and TaxType <> 1 and TaxType <> 2 and TaxType <> 3
   IF @validcnt <> 0
   	BEGIN
   	SELECT @errmsg = 'Invalid tax type'
   	GOTO error
   	END
   
   -- validate for various line types
   if @numrows = 1
   	select @apco = APCo, @linetype = LineType, @jcco = JCCo, @job = Job,
   	  @phasegroup = PhaseGroup, @phase = Phase, @jcctype = JCCType, @inco = INCo,
   	  @loc = Loc, @matlgroup = MatlGroup, @material = Material, @emco = EMCo,
   	  @equip = Equip, @emgroup = EMGroup, @costcode = CostCode, @emctype = EMCType,
   	  @wo = WO, @woitem = WOItem, @po = PO, @poitem = POItem, @POItemLine = POItemLine, 
   	  @itemtype = ItemType,@sl = SL, @slitem = SLItem, @receiver# = Receiver#,
   	  @mth=Mth, @aptrans=APTrans,@apline = APLine,
 	  ----#141957
 	  @KeyID = KeyID
	  from inserted
   else
   	begin
   	-- use a cursor to process each inserted row
   	declare bAPTL_insert cursor FAST_FORWARD
   	for select APCo, LineType, JCCo, Job, PhaseGroup, Phase, JCCType, INCo, Loc, MatlGroup, 
   		Material, EMCo, Equip, EMGroup, CostCode, EMCType, WO, WOItem, PO, POItem, POItemLine,
   		ItemType,SL, SLItem, Receiver#, Mth, APTrans,APLine,
		----#141957
		KeyID
   	from inserted
   	-- open cursor
   	open bAPTL_insert
   	fetch next from bAPTL_insert 
   		into @apco, @linetype, @jcco, @job, @phasegroup, @phase, @jcctype, @inco, @loc, @matlgroup, 
   		@material, @emco, @equip, @emgroup, @costcode, @emctype, @wo, @woitem, @po, @poitem,@POItemLine,
   		@itemtype,@sl, @slitem, @receiver#, @mth, @aptrans, @apline,
		----#141957
		@KeyID
   	 if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
   if @linetype in (1,7) or (@linetype = 6 and @itemtype = 1)
   	BEGIN
   	-- validate JC Company
   	SELECT @validcnt = count(*) FROM bJCCO (nolock) where JCCo = @jcco
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid JC Company'
   		GOTO error
   		END
   
   	-- validate Job
   	SELECT @validcnt = count(*) FROM bJCJM (nolock) where JCCo = @jcco and Job = @job
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid job'
   		GOTO error
   		END
   
   	-- validate standard phase
       -- note bspJCVPHASE also validates bJCCO and bJCJM
   	exec @rcode=bspJCVPHASE @jcco, @job, @phase, @phasegroup, 'N', @pp output, @descr output,
   	 		@PhaseGroupOut output, @vcontract output, @vitem output, @dept output,
   	 		@projminpct output, @JCJPexists output, @errmsg output
   	if @rcode<>0 goto error
   
   	-- validate Cost Type
    	select @override='N', @stringct = convert(varchar(5),@jcctype)
    	exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @stringct, @override,
    			@phsgroup output, @pphase output, @descr output, @billflag output,
    			@um output, @itemunitflag output, @phaseunitflag output, @JCCHexists output,
        		@costtypeout output, @errmsg output
    	if @rcode <> 0 goto error
   	END
   
   if @linetype = 2 or (@linetype = 6 and @itemtype = 2)
   	BEGIN
   	-- validate IN Company
   	SELECT @validcnt = count(*) FROM bINCO (nolock) where INCo = @inco
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid IN Company'
   		GOTO error
   		END
   
   	-- validate Location
   	SELECT @validcnt = count(*) FROM bINLM (nolock) where INCo = @inco and Loc = @loc
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid Location'
   		GOTO error
   		END
   
   	-- validate Material
   	SELECT @validcnt = count(*) FROM bHQMT (nolock) where MatlGroup = @matlgroup and Material = @material
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid Material'
   		GOTO error
   		END
       -- add check for stocked Material at Location
   	END
   
   if @linetype in (4,5) or (@linetype = 6 and @itemtype in (4,5))
   	BEGIN
   	-- validate EM Company
   	SELECT @validcnt = count(*) FROM bEMCO (nolock) where EMCo = @emco
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid EM Company'
   		GOTO error
   		END
   
   	-- validate Equipment
   	SELECT @validcnt = count(*) FROM bEMEM (nolock) where EMCo = @emco and Equipment = @equip
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid equipment'
   		GOTO error
   		END
   
   	-- validate Cost Code
   	SELECT @validcnt = count(*) FROM bEMCC (nolock) where EMGroup = @emgroup and CostCode = @costcode
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid Cost Code'
   		GOTO error
   		END
   
   	-- validate EM Cost Type 
   	SELECT @validcnt = count(*) FROM bEMCT (nolock) where EMGroup = @emgroup and CostType = @emctype
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid EM Cost Type'
   		GOTO error
   		END
   
       SELECT @validcnt = count(*) FROM bEMCH (nolock)
   	where EMCo = @emco and EMGroup = @emgroup and  Equipment = @equip and CostType = @emctype and CostCode = @costcode
       IF @validcnt = 0
           BEGIN
           SELECT @validcnt = count(*) FROM bEMCX (nolock) where EMGroup = @emgroup and CostType = @emctype and CostCode = @costcode
   	    IF @validcnt = 0
   			BEGIN
   			SELECT @errmsg = 'Invalid cost type/cost code combination'
   			GOTO error
   			END
           END
   	END
   
   if @linetype = 5 or (@linetype = 6 and @itemtype = 5)
   	BEGIN
   	-- validate Work Order
   	SELECT @validcnt = count(*) FROM bEMWH (nolock) where EMCo = @emco and WorkOrder = @wo
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid work order'
   		GOTO error
   		END
   
   	-- validate Work Order Item
   	SELECT @validcnt = count(*) FROM bEMWI (nolock) where EMCo = @emco and WorkOrder = @wo and WOItem = @woitem
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid work order item'
   		GOTO error
   		END
   	END
   
   if @linetype = 6
   	BEGIN
   	-- validate PO
   	SELECT @validcnt = count(*) FROM bPOHD (nolock) where POCo = @apco and PO = @po
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid PO'
   		GOTO error
   		END
   
   	-- validate PO Item 
   	SELECT @validcnt = count(*) FROM bPOIT (nolock) where POCo = @apco and PO = @po and POItem = @poitem
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid PO item'
   		GOTO error
   		END
   		
   	-- validate PO Item Line
   	SELECT @validcnt = COUNT(*)
   	FROM dbo.vPOItemLine (NOLOCK)
   	WHERE POCo = @apco AND PO = @po AND POItem = @poitem AND @POItemLine = POItemLine
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid PO Item Line'
   		GOTO error
   		END
   
   	-- validate Item Type TK-07233
   	SELECT @validcnt = COUNT(*)
   	FROM dbo.vPOItemLine
   	WHERE POCo = @apco AND PO = @po AND POItem = @poitem AND @POItemLine = POItemLine AND ItemType = @itemtype
   	----SELECT @validcnt = count(*) FROM bPOIT (nolock) where POCo = @apco and PO = @po and POItem = @poitem and ItemType = @itemtype
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid PO Item Type'
   		GOTO error
   		END

	--Update bPORD with AP Invoice info
	IF @receiver# IS NOT NULL
		BEGIN
		UPDATE dbo.bPORD SET APMth=i.Mth, APTrans=i.APTrans, APLine=i.APLine
		FROM dbo.bPORD r  
		JOIN inserted i ON r.POCo=i.APCo AND r.PO=i.PO AND r.POItem=i.POItem 
			AND r.POItemLine=i.POItemLine AND r.Receiver#=@receiver#
		WHERE i.APCo=@apco AND i.Mth=@mth AND i.APTrans=@aptrans AND i.APLine=@apline
		END

   	END

   
   if @linetype = 7
   	BEGIN
   	-- validate SL
   	SELECT @validcnt = count(*) FROM bSLHD (nolock) where SLCo = @apco and SL = @sl
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid Subcontract'
   		GOTO error
   		END
   	-- validate SL Item
   	SELECT @validcnt = count(*) FROM bSLIT (nolock) where SLCo = @apco and SL = @sl and SLItem = @slitem
   	IF @validcnt = 0
   		BEGIN
   		SELECT @errmsg = 'Invalid Subcontract item'
   		GOTO error
   		END
   	END


---- #141957 insert relationships into PM relationship table
---- PO line type
IF @linetype = 6
	BEGIN
	IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'vPMRelateRecord')
			AND EXISTS(SELECT TOP 1 1 from sysobjects where id = object_id(N'[dbo].[vspPMAssocAPInvoice]')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
		BEGIN
		EXEC dbo.vspPMAssocAPInvoice @KeyID, 'I', @linetype
		END
	END

---- SL line type
IF @linetype = 7
	BEGIN
	IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'vPMRelateRecord')
			AND EXISTS(SELECT TOP 1 1 from sysobjects where id = object_id(N'[dbo].[vspPMAssocAPInvoice]')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
		BEGIN
		EXEC dbo.vspPMAssocAPInvoice @KeyID, 'I', @linetype
		END
	END

--SM Line Type 
IF (@linetype = 8 or (@linetype = 6 and @itemtype = 6))  --TK-02798
BEGIN
	UPDATE vAPSM SET APKeyID = @KeyID WHERE APCo = @apco and Mth = @mth and APTrans = @aptrans and APLine = @apline
END

if @numrows > 1
	begin
	fetch next from bAPTL_insert into @apco, @linetype, @jcco, @job, @phasegroup, @phase, @jcctype,
			@inco, @loc, @matlgroup, @material, @emco, @equip, @emgroup, @costcode, @emctype,
			@wo, @woitem, @po, @poitem, @itemtype, @sl, @slitem, @receiver#,
			----#141957
			@KeyID
	 if @@fetch_status = 0
		goto insert_check
	 else
		begin
		close bAPTL_insert
		deallocate bAPTL_insert
		end
	end
   
   
---- Audit inserts
INSERT INTO bHQMA
	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bAPTL',' Mth: ' + convert(varchar(8), i.Mth,1)
		+ ' APTrans: ' + convert(varchar(6), i.APTrans)
		+ ' APLine: ' + convert(varchar(3),i.APLine), i.APCo, 'A',
		NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM inserted i
join bAPCO c (nolock) on c.APCo = i.APCo
where i.APCo = c.APCo and c.AuditTrans = 'Y'


return


error:
	SELECT @errmsg = @errmsg +  ' - cannot insert AP Transaction Line!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
  
 





GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
/****** Object:  Trigger dbo.btAPTLu    Script Date: 8/28/99 9:38:19 AM ******/
CREATE  trigger [dbo].[btAPTLu] on [dbo].[bAPTL] for UPDATE as
/*-----------------------------------------------------------------
    * Created By:	10/30/98 EN
    * Modified By: 12/31/98 EN
    *				8/16/99 GR - removed the check on equipment/costcode/costtype combination
    *				07/09/02 SR - 17738 pass @phasegroup to bspJCVPHASE
    *				10/18/02 - 18878 quoted identifier cleanup.
    *				GF 08/12/2003 - issue #22112 - performance
    *               MV 06/30/08 - #128288 - Taxtype 3 - VAT
    *				MV 02/12/09 - #123778 - clear invoice info in PORD if PO/PO Item changes
	*				MV 05/11/09 - #123778 - fix update to PORD begin/end
	*				MV 09/16/09 - #135081 - fix update to PORD again
	*				MV 11/25/09 - #136212 - don't update PORD unless po or item has changed
	*				GP 6/6/2010 - #135813 changed bSL to varchar(30)
	*				GF 11/02/2010 - issue #141957 record association
	*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
	*				MV 08/04/11 - TK-07233 AP project to use POItemLine
	*				MV 01/24/12 - TK-11873 audit On-Cost fields.
	*				GF 03/29/2013 TFS-45348 if only column that changed is SLKeyID, skip validation and audit. Creating balance forward claims
	*
    *
    *
    *	This trigger rejects update in bAPTL (Trans Line)
    *	if any of the following error conditions exist:
    *
    *		Cannot change Co
    *		Cannot change Mth
    *		Cannot change APTrans
    *		Cannot change APLine
    *
    *	Validate same as in insert trigger.
    *	Insert bHQMA entries for changed values if AuditTrans='Y' in bAPCO.
    */----------------------------------------------------------------
	DECLARE @errmsg varchar(255),
			@numrows int,
			@validcnt int,
			@nullcnt int
	DECLARE @apco bCompany,
			@linetype tinyint,
			@jcco bCompany,
			@job bJob,
			@phasegroup bGroup,
			@phase bPhase,
			@jcctype bJCCType,
			@inco bCompany,
			@loc bLoc,
			@matlgroup bGroup,
			@material bMatl,
			@emco bCompany,
			@equip bEquip,
			@emgroup bGroup,
			@costcode bCostCode,
			@emctype bEMCType,
			@wo bWO,
			@woitem bItem,
			@po varchar(30),
			@poitem bItem,
			@POItemLine int,
			@itemtype tinyint,
			@sl varchar(30),
			@slitem bItem,
			@pp bPhase,
			@descr varchar(30),
			@dept varchar(10),
			@projminpct real,
			-- #142350 - renaming @PhaseGroup
			@PhaseGroupOut tinyint,
			@vcontract bContract,
			@vitem bContractItem,
			@JCJPexists char(1),
			@rcode int,
			@stringct varchar(5),
			@override bYN,
			@phsgroup tinyint,
			@pphase bPhase,
			@billflag char(1),
			@um bUM,
			@itemunitflag bYN,
			@phaseunitflag bYN,
			@JCCHexists char(1),
			@costtypeout bJCCType,
			@oldpo varchar(30),
			@oldpoitem int,
			@OldPOItemLine int,
				----#141957
			@KeyID bigint,
			@oldlinetype tinyint
		   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   

---- TFS-45348 if the only column that changed was SLKeyID, then skip validation and auditing
IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bAPTL', 'SLKeyID') = 1
	BEGIN 
	RETURN
	END   

   -- verify primary key not changed
   if update(APCo) or update(Mth) or update(APTrans) or update(APLine)
    	begin
    	select @errmsg = 'Cannot change Primary Key'
    	goto error
    	end
   
   -- check Transaction Header
   SELECT @validcnt = count(*) FROM bAPTH h with (nolock)
   JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans
   IF @validcnt <> @numrows
    	BEGIN
    	SELECT @errmsg = 'Transaction Header does not exist'
    	GOTO error
    	END
   
   -- validate GL Company
   if update(GLCo)
       begin
        SELECT @validcnt = count(*) FROM bGLCO c with (nolock) JOIN inserted i ON c.GLCo = i.GLCo
        IF @validcnt <> @numrows
        	BEGIN
        	SELECT @errmsg = 'Invalid GL Company'
        	GOTO error
        	END
       end
   
   if update(GLAcct) or update(GLCo)
   	begin
   	-- validate GL Account
       SELECT @validcnt = count(*) FROM bGLAC v with (nolock)
		JOIN inserted i ON v.GLCo = i.GLCo and v.GLAcct = i.GLAcct
   	IF @validcnt <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Account'
   		GOTO error
   		END
   	end
   
   -- validate supplier
   if update(Supplier) or update(VendorGroup)
       begin
       select @nullcnt = count(*) from inserted where Supplier is null
       SELECT @validcnt = count(*) FROM inserted i
       JOIN bAPVM v with (nolock) ON v.VendorGroup=i.VendorGroup and v.Vendor=i.Supplier
       if @nullcnt + @validcnt <> @numrows
        	BEGIN
        	SELECT @errmsg = 'Invalid Supplier'
        	GOTO error
        	END
       end
   
   -- validate PayType
   if update(PayType)
       begin
       SELECT @validcnt = count(*) FROM bAPPT p with (nolock)
       JOIN inserted i ON p.APCo = i.APCo and p.PayType = i.PayType
       IF @validcnt <> @numrows
        	BEGIN
        	SELECT @errmsg = 'Invalid payment type'
        	GOTO error
        	END
       end
   
   -- validate tax information
   if update(TaxCode) or update(TaxGroup) or update(TaxType)
       begin
       select @nullcnt = count(*) from inserted where TaxGroup is null or TaxCode is null
       SELECT @validcnt = count(*) FROM bHQTX t with (nolock)
       JOIN inserted i ON i.TaxGroup = t.TaxGroup and i.TaxCode = t.TaxCode
       IF @nullcnt + @validcnt <> @numrows
        	BEGIN
        	SELECT @errmsg = 'Invalid tax group/tax code'
   		GOTO error
   		END
   
   	SELECT @validcnt = count(*) FROM inserted 
   	WHERE TaxGroup is not null and TaxCode is not null and TaxType <> 1 and TaxType <> 2 and TaxType <> 3
       IF @validcnt <> 0
        	BEGIN
        	SELECT @errmsg = 'Invalid tax type'
        	GOTO error
        	END
       end
   
-- validate for various line types
if @numrows = 1
	BEGIN
	select @apco = i.APCo, @linetype = i.LineType, @jcco = i.JCCo, @job = i.Job,
			@phasegroup = i.PhaseGroup, @phase = i.Phase, @jcctype = i.JCCType, @inco = i.INCo,
			@loc = i.Loc, @matlgroup = i.MatlGroup, @material = i.Material, @emco = i.EMCo,
			@equip = i.Equip, @emgroup = i.EMGroup, @costcode = i.CostCode, @emctype = i.EMCType,
			@wo = i.WO, @woitem = i.WOItem, @po = i.PO, @poitem = i.POItem, @POItemLine = i.POItemLine,
			@itemtype = i.ItemType,@sl = i.SL, @slitem = i.SLItem,
			----#141957
			@KeyID = i.KeyID, @oldlinetype = d.LineType
	from INSERTED i JOIN deleted d ON d.KeyID = i.KeyID
	END
else
	BEGIN
   	-- use a cursor to process each inserted row
    declare bAPTL_insert cursor LOCAL FAST_FORWARD
   	for select i.APCo, i.LineType, i.JCCo, i.Job, i.PhaseGroup, i.Phase, i.JCCType, i.INCo, i.Loc, i.MatlGroup, 
   		i.Material, i.EMCo, i.Equip, i.EMGroup, i.CostCode, i.EMCType, i.WO, i.WOItem, i.PO, i.POItem, i.POItemLine,
   		i.ItemType, i.SL, i.SLItem,
   		----#141957
   		i.KeyID, d.LineType
   	from INSERTED i JOIN deleted d ON d.KeyID = i.KeyID
   
   	open bAPTL_insert
   
   	fetch next from bAPTL_insert into @apco, @linetype, @jcco, @job, @phasegroup, @phase, @jcctype,
   		@inco, @loc, @matlgroup, @material, @emco, @equip, @emgroup, @costcode, @emctype, @wo, @woitem, 
   		@po, @poitem, @POItemLine, @itemtype, @sl, @slitem,
   		----#141957
   		@KeyID, @oldlinetype
   
   	if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
    	end
   
   
   insert_check:
   if @linetype = 1
    	BEGIN
   	-- validate JC Company
       if update(JCCo)
           begin
        	SELECT @validcnt = count(*) FROM bJCCO with (nolock) where JCCo = @jcco
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid JC Company'
        		GOTO error
        		END
           end
   
       if update(Job) or update(JCCo)
           begin
        	-- validate Job
        	SELECT @validcnt = count(*) FROM bJCJM with (nolock) where JCCo = @jcco and Job = @job
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid job'
        		GOTO error
        		END
           end
   
   	-- validate standard phase
   	-- note bspJCVPHASE also validates bJCCO and bJCJM
       if update(Job) or update(JCCo) or update(Phase)
           begin
        	exec @rcode=bspJCVPHASE @jcco, @job, @phase, @phasegroup, 'N', @pp output, @descr output,
   					@PhaseGroupOut output, @vcontract output, @vitem output, @dept output,
   					@projminpct output, @JCJPexists output, @errmsg output
        	if @rcode<>0 goto error
           end
   
       if update(Job) or update(JCCo) or update(Phase) or update(JCCType)
           begin
        	-- validate Cost Type
         	select @override='N', @stringct = convert(varchar(5),@jcctype)
         	exec @rcode = bspJCVCOSTTYPE @jcco, @job,@phasegroup, @phase, @stringct, @override,
   					@phsgroup output, @pphase output, @descr output, @billflag output, @um output,
   					@itemunitflag output, @phaseunitflag output, @JCCHexists output, 
   					@costtypeout output, @errmsg output
         	if @rcode <> 0 goto error
           end
    	END
   
   if @linetype = 2
    	BEGIN
    	-- validate IN Company
       if update(INCo)
           begin
        	SELECT @validcnt = count(*) FROM bINCO with (nolock) where INCo = @inco
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid IN Company'
        		GOTO error
        		END
           end
   
       if update(Loc) or update(INCo)
           begin
        	-- validate Location
        	SELECT @validcnt = count(*) FROM bINLM with (nolock) where INCo = @inco and Loc = @loc
   		IF @validcnt = 0
   	     	BEGIN
   	     	SELECT @errmsg = 'Invalid location'
   	     	GOTO error
   	     	END
           end
   
       if update(Material) or update(Loc) or update(INCo)
           begin
        	-- validate Material
        	SELECT @validcnt = count(*) FROM bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid material'
        		GOTO error
        		END
           end
    	END
   
   if @linetype = 4
    	BEGIN
    	-- validate EM Company
       if update(EMCo)
           begin
        	SELECT @validcnt = count(*) FROM bEMCO with (nolock) where EMCo = @emco
        	IF @validcnt = 0
       		BEGIN
        		SELECT @errmsg = 'Invalid EM Company'
        		GOTO error
        		END
           end
   
        if update(Equip) or update(EMCo)
           begin
       	-- validate Equipment
        	SELECT @validcnt = count(*) FROM bEMEM with (nolock) where EMCo = @emco and Equipment = @equip
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid equipment'
        		GOTO error
        		END
           end
   
        if update(CostCode) or  update(Equip) or update(EMCo)
           begin
        	-- validate Cost Code
        	SELECT @validcnt = count(*) FROM bEMCC with (nolock) where EMGroup = @emgroup and CostCode = @costcode
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid cost code'
        		GOTO error
        		END
           end
   
        if update(EMCType) or update(CostCode) or update(Equip) or update(EMCo)
           begin
        	-- validate EM Cost Type
        	SELECT @validcnt = count(*) FROM bEMCT with (nolock) where EMGroup = @emgroup and CostType = @emctype
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid EM cost type'
        		GOTO error
        		END
           end
   
         if update(EMCType) or update(CostCode) or update(Equip) or update(EMCo)
           begin
        	SELECT @validcnt = count(*) FROM bEMCX with (nolock) where EMGroup = @emgroup 
   		and CostType = @emctype and CostCode = @costcode
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid cost type/cost code combination'
        		GOTO error
        		END
           end
    	END
   
   if @linetype = 5
    	BEGIN
    	-- validate EM Company
       if update(EMCo)
           begin
        	SELECT @validcnt = count(*) FROM bEMCO with (nolock) where EMCo = @emco
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid EM Company'
        		GOTO error
        		END
           end
   
       if update(EMCo) or update(Equip)
           begin
        	-- validate Equipment
        	SELECT @validcnt = count(*) FROM bEMEM with (nolock) where EMCo = @emco and Equipment = @equip
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid equipment'
        		GOTO error
        		END
           end
   
       if update(EMGroup) or update(CostCode) or update(Equip)
           begin
        	-- validate Cost Code
        	SELECT @validcnt = count(*) FROM bEMCC with (nolock) where EMGroup = @emgroup and CostCode = @costcode
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid cost code'
        		GOTO error
        		END
           end
   
    	-- validate EM Cost Type
       if update(EMGroup) or update(EMCType) or update(EMCo)
           begin
        	SELECT @validcnt = count(*) FROM bEMCT with (nolock) where EMGroup = @emgroup and CostType = @emctype
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid EM cost type'
        		GOTO error
        		END
           end
   
       if update(EMGroup) or update(EMCType) or update(EMCo) or update(CostCode)
           begin
 
        	SELECT @validcnt = count(*) FROM bEMCX with (nolock) where EMGroup = @emgroup and CostType = @emctype
        		and CostCode = @costcode
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid cost type/cost code combination'
        		GOTO error
        		END
           end
   
    	-- validate Work Order
       if update(EMCo) or update(WO)
           begin
        	SELECT @validcnt = count(*) FROM bEMWH with (nolock) where EMCo = @emco and WorkOrder = @wo
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid work order'
        		GOTO error
        		END
           end
   
    	-- validate Work Order Item
       if update(EMCo) or update(WO) or update(WOItem)
           begin
        	SELECT @validcnt = count(*) FROM bEMWI with (nolock) where EMCo = @emco and WorkOrder = @wo and WOItem = @woitem
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid work order item'
        		GOTO error
        		END
           end
    	END
   
	IF @linetype = 6
    BEGIN
       IF UPDATE(PO)
       BEGIN
        	-- validate PO
        	SELECT @validcnt = count(*) FROM bPOHD with (nolock) where POCo = @apco and PO = @po
        	IF @validcnt = 0
        	BEGIN
        		SELECT @errmsg = 'Invalid PO'
        		GOTO error
        	END
       END
   
       IF UPDATE(POItem) OR UPDATE(PO)
       BEGIN
        	-- validate PO Item
        	SELECT @validcnt = count(*) FROM bPOIT with (nolock) where POCo = @apco and PO = @po and POItem = @poitem
        	IF @validcnt = 0
        	BEGIN
        		SELECT @errmsg = 'Invalid PO item'
        		GOTO error
        	END
       END
       	
		IF UPDATE(POItemLine) OR UPDATE(POItem) OR UPDATE(PO)
		BEGIN
			-- validate PO Item Line
        	SELECT @validcnt = COUNT(*)
        	FROM dbo.vPOItemLine (NOLOCK)
        	WHERE POCo = @apco AND PO = @po AND POItem = @poitem AND POItemLine = @POItemLine
        	IF @validcnt = 0
        	BEGIN
        		SELECT @errmsg = 'Invalid PO item Line'
        		GOTO error
        	END
        	
			-- if the PO,POItem or POItemLine changes and there is a bPORD record linked to the old PO,POItem and POItemLine
			-- break the invoice link with bPORD.
			SELECT @oldpo= PO, @oldpoitem = POItem, @OldPOItemLine = POItemLine
			FROM deleted
			IF @oldpo <> @po OR @oldpoitem <> @poitem OR @OldPOItemLine <> @POItemLine 
			BEGIN
			IF EXISTS	(	
							SELECT 1 
							FROM dbo.bPORD r 
							JOIN deleted d ON r.POCo=d.APCo AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine AND
								(
									r.Receiver# IS NOT NULL AND r.Receiver#=d.Receiver#
								)
							WHERE r.POCo=d.APCo AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine
								AND r.APMth=d.Mth AND r.APTrans=d.APTrans AND r.APLine=d.APLine
						)
				BEGIN
				UPDATE dbo.bPORD SET APMth= null, APTrans=null, APLine=null
				FROM dbo.bPORD r 
				JOIN deleted d ON r.POCo=d.APCo AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine AND r.Receiver#=d.Receiver#
				WHERE r.POCo=d.APCo AND r.PO=d.PO AND r.POItem=d.POItem AND r.POItemLine=d.POItemLine 
					AND APMth=d.Mth and r.APTrans=d.APTrans and r.APLine=d.APLine 
				END
			END
		END
   
    	-- validate Item Type
       IF UPDATE(POItem) OR update(PO) OR UPDATE(POItemLine)
       BEGIN
        	SELECT @validcnt = count(*) 
        	FROM dbo.vPOItemLine (NOLOCK)
        	WHERE POCo = @apco AND PO = @po AND POItem = @poitem AND POItemLine=@POItemLine	AND ItemType = @itemtype
        	IF @validcnt = 0
        	BEGIN
        		SELECT @errmsg = 'Invalid item type'
        		GOTO error
        	END
    	END
	END -- End PO validation
	
   if @linetype = 7
    	BEGIN
    	-- validate SL
       if update(SL)
           begin
        	SELECT @validcnt = count(*) FROM bSLHD with (nolock) where SLCo = @apco and SL = @sl
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid SL'
        		GOTO error
        		END
           end
   
    	-- validate SL Item
       if update(SL) or update(SLItem)
           begin
        	SELECT @validcnt = count(*) FROM bSLIT with (nolock) where SLCo = @apco and SL = @sl and SLItem = @slitem
        	IF @validcnt = 0
        		BEGIN
        		SELECT @errmsg = 'Invalid SL item'
        		GOTO error
        		END
           end
    	END

---- #141957 insert relationships into relationship table
---- PO line type
---- possible that line type was changed or PO in this case we need to delete old relationship first
IF @oldlinetype = 6
	BEGIN
	IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'vPMRelateRecord')
			AND EXISTS(SELECT TOP 1 1 from sysobjects where id = object_id(N'[dbo].[vspPMAssocAPInvoice]')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
		BEGIN
		EXEC dbo.vspPMAssocAPInvoice @KeyID, 'D', @oldlinetype
		END
	END

IF @linetype = 6
	BEGIN
	IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'vPMRelateRecord')
			AND EXISTS(SELECT TOP 1 1 from sysobjects where id = object_id(N'[dbo].[vspPMAssocAPInvoice]')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
		BEGIN
		EXEC dbo.vspPMAssocAPInvoice @KeyID, 'I', @linetype
		END
	END

---- #141957 insert relationships into PM relationship table
---- SL line type
---- possible that line type was changed or SL in this case we need to delete old relationship first
IF @oldlinetype = 7
	BEGIN
	IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'vPMRelateRecord')
			AND EXISTS(SELECT TOP 1 1 from sysobjects where id = object_id(N'[dbo].[vspPMAssocAPInvoice]')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
		BEGIN
		EXEC dbo.vspPMAssocAPInvoice @KeyID, 'D', @oldlinetype
		END
	END

IF @linetype = 7
	BEGIN
	IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'vPMRelateRecord')
			AND EXISTS(SELECT TOP 1 1 from sysobjects where id = object_id(N'[dbo].[vspPMAssocAPInvoice]')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
		BEGIN
		EXEC dbo.vspPMAssocAPInvoice @KeyID, 'I', @linetype
		END
	END


if @numrows > 1
	begin
   	fetch next from bAPTL_insert into @apco, @linetype, @jcco, @job, @phasegroup, @phase, @jcctype,
   		@inco, @loc, @matlgroup, @material, @emco, @equip, @emgroup, @costcode, @emctype, @wo, @woitem, 
   		@po, @poitem, @POItemLine, @itemtype, @sl, @slitem,
   		----#141957
   		@KeyID, @oldlinetype

	if @@fetch_status = 0
		goto insert_check
	else
		begin
		close bAPTL_insert
		deallocate bAPTL_insert
		end
	end
   
   
-- Check bAPCO to see if auditing transaction. If not done.
if not exists(select * from inserted i join bAPCO c with (nolock) on i.APCo=c.APCo where c.AuditTrans = 'Y')
return
   
   
   -- Insert records into HQMA for changes made to audited fields
   if update(LineType)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'LineType', convert(varchar(3),d.LineType), convert(varchar(3),i.LineType), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.LineType <> i.LineType and a.AuditTrans = 'Y'
   
   if update(PO)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'PO', d.PO, i.PO, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.PO <> i.PO and a.AuditTrans = 'Y'
   
   if update(POItem)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'POItem', convert(varchar(5),d.POItem), convert
   	(varchar(5),i.POItem), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.POItem <> i.POItem and a.AuditTrans = 'Y'
    	
    IF UPDATE(POItemLine)
     INSERT INTO dbo.bHQMA SELECT 'bAPTL', ' Mth: ' + CONVERT(CHAR(8), i.Mth,1)
    		 + ' APTrans: ' + CONVERT (VARCHAR(6), i.APTrans)
    		 + ' APLine: ' + CONVERT (VARCHAR(5),i.APLine), i.APCo, 'C',
    		'POItemLine', CONVERT (VARCHAR(5),d.POItemLine), 
    		CONVERT (VARCHAR(5),i.POItemLine),
    		GETDATE(),
    		SUSER_SNAME()
     FROM inserted i
     JOIN deleted d ON d.APCo = i.APCo AND d.Mth = i.Mth AND d.APTrans = i.APTrans AND d.APLine = i.APLine
     JOIN dbo.bAPCO a (NOLOCK) ON a.APCo = i.APCo
     WHERE d.POItemLine <> i.POItemLine AND a.AuditTrans = 'Y'
   
   if update(ItemType)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'ItemType', convert(varchar(5),d.ItemType), convert(varchar(5),i.ItemType), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.ItemType <> i.ItemType and a.AuditTrans = 'Y'
   
   if update(SL)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'SL', d.SL, i.SL, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.SL <> i.SL and a.AuditTrans = 'Y'
   
   if update(SLItem)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'SLItem', convert(varchar(5),d.SLItem), convert(varchar(5),i.SLItem), getdate(), SUSER_SNAME()
    	from inserted i
    join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.SLItem <> i.SLItem and a.AuditTrans = 'Y'
   
   if update(JCCo)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'JCCo', convert(varchar(3),d.JCCo), convert(varchar(3),i.JCCo), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.JCCo <> i.JCCo and a.AuditTrans = 'Y'
   
   if update(Job)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)		
    + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Job', convert(varchar(9),d.Job), convert(varchar(9),i.Job), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Job <> i.Job and a.AuditTrans = 'Y'
   
   if update(PhaseGroup)
    insert into  bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'PhaseGroup', convert(varchar(3),d.PhaseGroup), convert(varchar(3),i.PhaseGroup), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
     join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.PhaseGroup <> i.PhaseGroup and a.AuditTrans = 'Y'
   
   if update(Phase)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Phase', convert(varchar(13),d.Phase), convert(varchar(13),i.Phase), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Phase <> i.Phase and a.AuditTrans = 'Y'
   
   if update(JCCType)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'JCCType', convert(varchar(3),d.JCCType), convert(varchar(3),i.JCCType), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.JCCType <> i.JCCType and a.AuditTrans = 'Y'
   
   if update(EMCo)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'EMCo', convert(varchar(3),d.EMCo), convert(varchar(3),i.EMCo), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.EMCo <> i.EMCo and a.AuditTrans = 'Y'
   
   if update(WO)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'WO', d.WO, i.WO, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.WO <> i.WO and a.AuditTrans = 'Y'
   
   if update(WOItem)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'WOItem', convert(varchar(5),d.WOItem), convert(varchar(5),i.WOItem), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.WOItem <> i.WOItem and a.AuditTrans = 'Y'
   
   if update(Equip)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Equip', d.Equip, i.Equip, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Equip <> i.Equip and a.AuditTrans = 'Y'
   
   if update(EMGroup)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'EMGroup', convert(varchar(3),d.EMGroup), convert(varchar(3),i.EMGroup), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.EMGroup <> i.EMGroup and a.AuditTrans = 'Y'
   
   if update(CostCode)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'CostCode', d.CostCode, i.CostCode, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.CostCode <> i.CostCode and a.AuditTrans = 'Y'
   
   if update(EMCType)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'EMCType', convert(varchar(3),d.EMCType), convert(varchar(3),i.EMCType), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.EMCType <> i.EMCType and a.AuditTrans = 'Y'
   
   if update(INCo)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'INCo', convert(varchar(3),d.INCo), convert(varchar(3),i.INCo), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.INCo <> i.INCo and a.AuditTrans = 'Y'
   
   if update(Loc)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Loc', convert(varchar(10),d.Loc), convert(varchar(10),i.Loc), getdate(), SUSER_SNAME()
    	from inserted i
   	join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Loc <> i.Loc and a.AuditTrans = 'Y'
   
   if update(MatlGroup)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'MatlGroup', convert(varchar(3),d.MatlGroup), convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.MatlGroup <> i.MatlGroup and a.AuditTrans = 'Y'
   
   if update(Material)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Material', d.Material, i.Material, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Material <> i.Material and a.AuditTrans = 'Y'
   
   if update(GLCo)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'GLCo', convert(varchar(3),d.GLCo), convert(varchar(3),i.GLCo), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.GLCo <> i.GLCo and a.AuditTrans = 'Y'
   
   if update(GLAcct)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'GLAcct', convert(varchar(10),d.GLAcct), convert(varchar(10),i.GLAcct), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.GLAcct <> i.GLAcct and a.AuditTrans = 'Y'
   
   if update(Description)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Description <> i.Description and a.AuditTrans = 'Y'
   
   if update(UM)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.UM <> i.UM and a.AuditTrans = 'Y'
   
   if update(Units)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Units', convert(varchar(15),d.Units), convert(varchar(15),i.Units), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Units <> i.Units and a.AuditTrans = 'Y'
   
   if update(UnitCost)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	' UnitCost' , convert(varchar(20),d.UnitCost), convert(varchar(20),i.UnitCost), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.UnitCost <> i.UnitCost and a.AuditTrans = 'Y'
   
   if update(ECM)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'ECM', d.ECM, i.ECM, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.ECM <> i.ECM and a.AuditTrans = 'Y'
   
   if update(VendorGroup)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'VendorGroup', convert(varchar(3),d.VendorGroup), convert(varchar(3),i.VendorGroup), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.VendorGroup <> i.VendorGroup and a.AuditTrans = 'Y'
   
   if update(Supplier)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Supplier', convert(varchar(6),d.Supplier), convert(varchar(6),i.Supplier), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Supplier <> i.Supplier and a.AuditTrans = 'Y'
   
   if update(PayType)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'PayType', convert(varchar(3),d.PayType), convert(varchar(3),i.PayType), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.PayType <> i.PayType and a.AuditTrans = 'Y'
   
   if update(GrossAmt)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'GrossAmt', convert(varchar(16),d.GrossAmt), convert(varchar(16),i.GrossAmt), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.GrossAmt <> i.GrossAmt and a.AuditTrans = 'Y'
   
   if update(MiscAmt)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'MiscAmt', convert(varchar(16),d.MiscAmt), convert(varchar(16),i.MiscAmt), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.MiscAmt <> i.MiscAmt and a.AuditTrans = 'Y'
   
   if update(MiscYN)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'MiscYN', d.MiscYN, i.MiscYN, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.MiscYN <> i.MiscYN and a.AuditTrans = 'Y'
   
   if update(TaxGroup)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'TaxGroup', convert(varchar(3),d.TaxGroup), convert(varchar(3),i.TaxGroup), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.TaxGroup <> i.TaxGroup and a.AuditTrans = 'Y'
   
   if update(TaxCode)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.TaxCode <> i.TaxCode and a.AuditTrans = 'Y'
   
   if update(TaxType)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'TaxType', convert(char(1),d.TaxType), convert(char(1),i.TaxType), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.TaxType <> i.TaxType and a.AuditTrans = 'Y'
   
   if update(TaxBasis)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'TaxBasis', convert(varchar(16),d.TaxBasis), convert(varchar(16),i.TaxBasis), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.TaxBasis <> i.TaxBasis and a.AuditTrans = 'Y'
   
   if update(TaxAmt)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'TaxAmt', convert(varchar(16),d.TaxAmt), convert(varchar(16),i.TaxAmt), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.TaxAmt <> i.TaxAmt and a.AuditTrans = 'Y'
   
   if update(Retainage)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Retainage', convert(varchar(16),d.Retainage), convert(varchar(16),i.Retainage), getdate(), SUSER_SNAME()
    	from inserted i
   	join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Retainage <> i.Retainage and a.AuditTrans = 'Y'
   
   if update(Discount)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'Discount', convert(varchar(16),d.Discount), convert(varchar(16),i.Discount), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join  bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.Discount <> i.Discount and a.AuditTrans = 'Y'
   
   if update(BurUnitCost)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'BurUnitCost', convert(varchar(20),d.BurUnitCost), convert(varchar(20),i.BurUnitCost), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.BurUnitCost <> i.BurUnitCost and a.AuditTrans = 'Y'
   
   if update(BECM)
    insert into bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'BECM', d.BECM, i.BECM, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.APCo = i.APCo and d.Mth = i.Mth
   	and d.APTrans = i.APTrans and d.APLine = i.APLine
       join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.BECM <> i.BECM and a.AuditTrans = 'Y'
   
   IF UPDATE(SubjToOnCostYN)
   INSERT INTO dbo.bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'SubjToOnCostYN', d.SubjToOnCostYN, i.SubjToOnCostYN, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
   WHERE d.SubjToOnCostYN <> i.SubjToOnCostYN 
   
   IF UPDATE(OnCostStatus)
   INSERT INTO dbo.bHQMA SELECT 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'OnCostStatus', convert(varchar(4),d.OnCostStatus), convert(varchar(4),i.OnCostStatus), getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans and d.APLine = i.APLine
   WHERE d.OnCostStatus <> i.OnCostStatus
    	
   IF UPDATE(ocApplyMth)
   INSERT INTO dbo.bHQMA SELECT 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'ocApplyMth', convert(varchar(8),d.ocApplyMth), convert(varchar(8),i.ocApplyMth), getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
   WHERE d.ocApplyMth <> i.ocApplyMth
   
   IF UPDATE(ocApplyTrans)
   INSERT INTO dbo.bHQMA SELECT 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'ocApplyTrans', convert(varchar(20),d.ocApplyTrans), convert(varchar(20),i.ocApplyTrans), getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans and d.APLine = i.APLine
   WHERE d.ocApplyTrans <> i.ocApplyTrans
   
   IF UPDATE(ocApplyLine)
   INSERT INTO dbo.bHQMA SELECT 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'ocApplyLine', convert(varchar(10),d.ocApplyLine), convert(varchar(10),i.ocApplyLine), getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans and d.APLine = i.APLine
   WHERE d.ocApplyLine <> i.ocApplyLine

	IF UPDATE(ATOCategory)
   INSERT INTO dbo.bHQMA select 'bAPTL', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans)
    		 + ' APLine: ' + convert(varchar(5),i.APLine), i.APCo, 'C',
    	'ATOCategory', d.ATOCategory, i.ATOCategory, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        	and d.APLine = i.APLine
   WHERE d.ATOCategory <> i.ATOCategory 
   
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Transaction Line!'
   	RAISERROR(@errmsg, 11, -1);
      	rollback transaction
   
   
  
 






GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPTL].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPTL].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTL].[MiscYN]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPTL].[BurUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPTL].[BECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTL].[POPayTypeYN]'
GO
