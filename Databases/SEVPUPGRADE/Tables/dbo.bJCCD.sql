CREATE TABLE [dbo].[bJCCD]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[CostTrans] [dbo].[bTrans] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[JCTransType] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[BatchId] [dbo].[bBatchID] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLTransAcct] [dbo].[bGLAcct] NULL,
[GLOffsetAcct] [dbo].[bGLAcct] NULL,
[ReversalStatus] [tinyint] NOT NULL,
[UM] [dbo].[bUM] NULL,
[ActualUnitCost] [dbo].[bUnitCost] NOT NULL,
[PerECM] [dbo].[bECM] NULL,
[ActualHours] [dbo].[bHrs] NOT NULL,
[ActualUnits] [dbo].[bUnits] NOT NULL,
[ActualCost] [dbo].[bDollar] NOT NULL,
[ProgressCmplt] [dbo].[bPct] NOT NULL,
[EstHours] [dbo].[bHrs] NOT NULL,
[EstUnits] [dbo].[bUnits] NOT NULL,
[EstCost] [dbo].[bDollar] NOT NULL,
[ProjHours] [dbo].[bHrs] NOT NULL,
[ProjUnits] [dbo].[bUnits] NOT NULL,
[ProjCost] [dbo].[bDollar] NOT NULL,
[ForecastHours] [dbo].[bHrs] NOT NULL,
[ForecastUnits] [dbo].[bUnits] NOT NULL,
[ForecastCost] [dbo].[bDollar] NOT NULL,
[PostedUM] [dbo].[bUM] NULL,
[PostedUnits] [dbo].[bUnits] NOT NULL,
[PostedUnitCost] [dbo].[bUnitCost] NOT NULL,
[PostedECM] [dbo].[bECM] NULL,
[PostTotCmUnits] [dbo].[bUnits] NOT NULL,
[PostRemCmUnits] [dbo].[bUnits] NOT NULL,
[TotalCmtdUnits] [dbo].[bUnits] NOT NULL,
[TotalCmtdCost] [dbo].[bDollar] NOT NULL,
[RemainCmtdUnits] [dbo].[bUnits] NOT NULL,
[RemainCmtdCost] [dbo].[bDollar] NOT NULL,
[DeleteFlag] [dbo].[bYN] NOT NULL,
[AllocCode] [smallint] NULL,
[ACO] [dbo].[bACO] NULL,
[ACOItem] [dbo].[bACOItem] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[EarnFactor] [dbo].[bRate] NULL,
[EarnType] [dbo].[bEarnType] NULL,
[Shift] [tinyint] NULL,
[LiabilityType] [dbo].[bLiabilityType] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[APCo] [dbo].[bCompany] NULL,
[APTrans] [dbo].[bTrans] NULL,
[APLine] [smallint] NULL,
[APRef] [dbo].[bAPReference] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[MO] [dbo].[bMO] NULL,
[MOItem] [dbo].[bItem] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[INStdUnitCost] [dbo].[bUnitCost] NOT NULL,
[INStdECM] [dbo].[bECM] NULL,
[INStdUM] [dbo].[bUM] NULL,
[MSTrans] [dbo].[bTrans] NULL,
[MSTicket] [dbo].[bTic] NULL,
[JBBillStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[JBBillMonth] [dbo].[bMonth] NULL,
[JBBillNumber] [int] NULL,
[EMCo] [dbo].[bCompany] NULL,
[EMEquip] [dbo].[bEquip] NULL,
[EMRevCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[EMGroup] [dbo].[bGroup] NULL,
[EMTrans] [dbo].[bTrans] NULL,
[TaxType] [tinyint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[SrcJCCo] [dbo].[bCompany] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[TotalCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCD_TotalCmtdTax] DEFAULT ((0.00)),
[RemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCD_RemCmtdTax] DEFAULT ((0.00)),
[OffsetGLCo] [dbo].[bCompany] NULL,
[POItemLine] [int] NULL,
[SMWorkCompletedID] [bigint] NULL,
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[SMScope] [int] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJCCDd    Script Date: 8/28/99 9:37:41 AM ******/
   CREATE TRIGGER [dbo].[btJCCDd] ON [dbo].[bJCCD] FOR DELETE AS
   

/**************************************************************
* Created By:
* Modified By:	GF 05/14/2001	- issue #13259 - deleting cost header with 'OE' detail only.
*				DANF 02/07/2002	- ISSUE #16198 Added ClosePurgeFlag to JCJM to speed up the delete trigger on JCCD.
*				GF 03/29/2005	- issue #27492 - possible @UM is null, wrap in isnull
*				CHS 05/15/2009	- issue #133437
*				GF 03/21/2011 - issue #143617
*
*	This trigger rejects delete of bJCCD (JC Cost Detail)
*	 if the following error condition exists:
*		none
*
*              Updates corresponding fields in JCCP.
*
*		(Future checks AP, PM, PR, MS, EM, PO, ???)
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int,
   		@JCCo bCompany, @Job bJob, @Phase bPhase, @PhaseGroup tinyint,@CostType bJCCType,
   		@Mth bMonth, @ActualHours bHrs, @ActualUnits bUnits, @ActualCost bDollar,
   		@OrigEstHours bHrs, @OrigEstUnits bUnits, @OrigEstCost bDollar,
   		@CurrEstHours bHrs, @CurrEstUnits bUnits, @CurrEstCost bDollar,
   		@ProjHours bHrs, @ProjUnits bUnits, @ProjCost bDollar,
   		@ForecastHours bHrs, @ForecastUnits bUnits, @ForecastCost bDollar,
   		@TotalCmtdUnits bUnits, @TotalCmtdCost bDollar,
   		@RemainCmtdUnits bUnits, @RemainCmtdCost bDollar,
   		@JCTransType varchar(2)	,@UM bUM, @JCCHUM bUM, @CostTrans bTrans
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- If purging job no need to update JCCP
   select @validcnt = count(*) from bJCJM j 
                join deleted d
                on d.JCCo=j.JCCo and d.Job=j.Job
                where j.ClosePurgeFlag='Y'
   
   if @numrows = @validcnt  return
   
   SELECT @JCCo=MIN(JCCo) from deleted
   
   WHILE @JCCo IS NOT NULL
   BEGIN
   SELECT @Mth=MIN(Mth) from deleted where @JCCo=JCCo
   WHILE @Mth IS NOT NULL
   BEGIN
   SELECT @CostTrans=MIN(CostTrans) from deleted where @JCCo=JCCo and @Mth=Mth
   WHILE @CostTrans IS NOT NULL
   BEGIN
   	select  @Job=Job, @Phase=Phase, @PhaseGroup=PhaseGroup,@CostType=CostType,
   		@ActualHours=ActualHours, @ActualUnits=ActualUnits, @ActualCost=ActualCost,
   		@OrigEstHours=EstHours, @OrigEstUnits=EstUnits, @OrigEstCost=EstCost,
   		@CurrEstHours=EstHours, @CurrEstUnits=EstUnits, @CurrEstCost=EstCost,
   		@ProjHours=ProjHours, @ProjUnits=ProjUnits, @ProjCost=ProjCost,
   		@ForecastHours=ForecastHours, @ForecastUnits=ForecastUnits, @ForecastCost=ForecastCost,
   		@TotalCmtdUnits=TotalCmtdUnits, @TotalCmtdCost=TotalCmtdCost,
   		@RemainCmtdUnits=RemainCmtdUnits, @RemainCmtdCost=RemainCmtdCost,
   		@JCTransType=JCTransType, @UM=UM
   	 from deleted
   	 where JCCo=@JCCo and Mth=@Mth and CostTrans=@CostTrans
   
   -- -- -- if this is not an orig entry then dont subtract from originals
   if @JCTransType<>'OE'
   	begin
   	select @OrigEstHours=0, @OrigEstUnits=0, @OrigEstCost=0
   	end
   
   -- -- --select @JCTransType, @CostTrans, @UM, 'after trans type check'
   
   -- -- -- if the unit of measure is not the same as JCCH then dont delete units
   select @JCCHUM=j.UM from bJCCH j
          where j.JCCo=@JCCo and j.Job=@Job and j.PhaseGroup=@PhaseGroup
          and j.Phase=@Phase and j.CostType=@CostType
   
   -- -- -- #27492 wrap in isnull
   if @JCCHUM <> isnull(@UM,'') AND @JCTransType <> 'OE'
   	begin
   	select @ActualUnits=0, @OrigEstUnits=0, @CurrEstUnits=0, @ProjUnits=0,
   	       @ForecastUnits=0, @TotalCmtdUnits=0, @RemainCmtdUnits=0
   	end
   
   -- -- -- select @JCCHUM, @UM, @OrigEstUnits, 'after UM check'
   
   
   /***********************/
   
   /* update bJCCP record */
   /* **** actual ***/
   update bJCCP
   set ActualHours = ActualHours - @ActualHours,
   	ActualUnits = ActualUnits - @ActualUnits,
   	ActualCost = ActualCost - @ActualCost,
   	OrigEstHours = OrigEstHours - @OrigEstHours,
   	OrigEstUnits = OrigEstUnits - @OrigEstUnits,
   	OrigEstCost = OrigEstCost - @OrigEstCost,
   	CurrEstHours = CurrEstHours - @CurrEstHours,
   	CurrEstUnits = CurrEstUnits - @CurrEstUnits,
   
   	CurrEstCost = CurrEstCost - @CurrEstCost,
    	ProjHours = ProjHours - @ProjHours,
    	ProjUnits = ProjUnits - @ProjUnits,
   	ProjCost = ProjCost - @ProjCost,
   	ForecastHours = ForecastHours - @ForecastHours,
    	ForecastUnits = ForecastUnits - @ForecastUnits,
   	ForecastCost = ForecastCost -  @ForecastCost,
   	TotalCmtdUnits = TotalCmtdUnits - @TotalCmtdUnits,
   	TotalCmtdCost = TotalCmtdCost - @TotalCmtdCost,
   	RemainCmtdUnits = RemainCmtdUnits - @RemainCmtdUnits,
   	RemainCmtdCost = RemainCmtdCost - @RemainCmtdCost
   Where JCCo=@JCCo and Job=@Job and Phase=@Phase and PhaseGroup=@PhaseGroup
   and CostType=@CostType and Mth=@Mth
   
   
   /******* Notice *****/
   /* Total Cmtd units is updated by PO/SL/AP - DO NOT update these fields in this trigger*/
   /* get next transaction */
   SELECT @CostTrans=MIN(CostTrans) from deleted where @JCCo=JCCo and @Mth=Mth and CostTrans>@CostTrans
   END
   SELECT @Mth=MIN(Mth) from deleted where @JCCo=JCCo and Mth>@Mth
   END
   SELECT @JCCo=MIN(JCCo) from deleted where JCCo>@JCCo
   END
   
   
   
-- issue #133437
-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		  select AttachmentID, suser_name(), 'Y' 
			  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
			  where d.UniqueAttchID is not null


---- Auditing issue #143617
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCCD','JCCo: ' + convert(varchar(3),deleted.JCCo) + ' Job: ' + deleted.Job + ' Phase: ' + deleted.Phase +
			' Mth: ' + CONVERT(VARCHAR(20),deleted.Mth) + ' Cost Trans: ' + CONVERT(VARCHAR(20),deleted.CostTrans),
		deleted.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted JOIN bJCJM ON bJCJM.JCCo=deleted.JCCo AND bJCJM.Job=deleted.Job
WHERE bJCJM.ClosePurgeFlag <> 'Y'



return

error:
   	select @errmsg = @errmsg + ' - cannot delete JC Cost Detail entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*****************************************/
CREATE  trigger [dbo].[btJCCDi] on [dbo].[bJCCD] for insert as
/**************************************************************
     * Created: JRE 12/10/96
     * Last Modified: GG 07/25/98	-- added PR Entry source
     *				DANF 03/16/00  -- Added reversal status of 4 for canceled reversal.
     *				DANF 06/01/00 -- Added Source for JC Mat Use
     *				DANF 09/27/00 -- Corrected GL Offset account validation
     *				GG 10/28/00 - Added source 'MS Tickets'
     *				GG 04/10/01 - change GL Account validation to use bspGLACfPostable
     *				GF 04/30/2001 - added JCTransSource and Source for IN Material Orders
     *				danf 03/29/02 - Added JC transcation type of 'IC' for Intercompany trancations.
     *				DANF 09/06/02 - 17738 Added Phase Group to bspJCADDCOSTTYPE
     *				TV 06/09/02 - Added roll up type to Source 13038
     *				TV 06/09/03 - Skip cost type/ Phase validation if Source is Roll Up 13038
     *				GF 08/01/2003 - issue #21933 - speed improvements
     *				TV 05/25/04 24667 need to change this to look at the Posted UM 
     *				GF 03/29/2005 - #27492 put back way it was. JCCP is update when actual um (@um) equals JCCH.UM
     *				GF 07/01/2005 - #29035 if source is 'JC Projctn' skip phase validation to avoid inactive phase error
	*				GF 01/08/2008 - issue #126441 more performance changes, update JCCP only when we have values.
	*				GF 08/31/2009 - issue #135151 set override flag to 'O' when validating phase for source 'PM Intface'
     *				GF 08/26/2011 TK-07440 PO Item Line 
     *				TL 02/04/2012 TK-12244 modify for SM
     *
     *
     *
     *  This trigger rejects insert in bJCCD (JC Cost Detail)
     *  if the following error condition exists:
     *
     *      invalid Phase or CostType
     *      invalid GLTransAcct
     *      invalid GLOffsetAcct
     *              TransType not in 'OE' or '- currently only insert are allowed
     *      Still needs check for valid BatchId, inuseBatchId, reversal status, ECM,
     *      postedum, ACO, ACOItem
     *      Updates corresponding fields in JCCP.
     *      note
     *      (Future checks AP, PM, PR, MS, EM, PO, ???)
     *  This trigger does not use a cursor, rather it iterates througt the inserted
     *      table using @KeyCo, @KeyMonth & @Trans
     *
     **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int,
     		@OrigEstcost bDollar, @OrigEstUnits bUnits, @OrigEstHours bHrs,
     		@override char(1), @rcode int, @updateflag tinyint,
     		-- JCCD
     		@JCCo bCompany, @Mth bMonth, @CostTrans bTrans, @Job bJob, @PhaseGroup tinyint, 
    		@Phase bPhase, @CostType bJCCType, @jctranstype varchar(2), @source bSource, 
    		@reversalstatus tinyint, @PostedUM bUM, @um bUM, @ActualUnitcost bUnitCost, 
    		@PerECM bECM, @ActualHours bHrs, @ActualUnits bUnits, @Actualcost bDollar, 
    		@EstHours bHrs, @EstUnits bUnits, @Estcost bDollar, @ProjHours bHrs, @ProjUnits bUnits, 
    		@Projcost bDollar, @ForecastHours bHrs, @ForecastUnits bUnits, @Forecastcost bDollar, 
    		@totalcmtdUnits bUnits, @totalcmtdcost bDollar, @remaincmtdUnits bUnits, @remaincmtdcost bDollar,
     		@aco bACO, @acoitem bACOItem
       
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
       
    set @override='N'
    
    
    if @numrows = 1
    	select @JCCo = JCCo, @Mth = Mth, @CostTrans = CostTrans, @Job = Job, @PhaseGroup = PhaseGroup, 
    		@Phase = Phase, @CostType = CostType, @jctranstype = JCTransType, @source = Source,
    		@reversalstatus = ReversalStatus, @PostedUM = PostedUM,  @um = UM, @ActualUnitcost = ActualUnitCost,
    		@PerECM = PerECM,  @ActualHours = ActualHours, @ActualUnits = ActualUnits, @Actualcost = ActualCost, 
    		@EstHours = EstHours,  @EstUnits = EstUnits,  @Estcost = EstCost, @ProjHours = ProjHours, 
    		@ProjUnits = ProjUnits, @Projcost = ProjCost, @ForecastHours = ForecastHours, @ForecastUnits = ForecastUnits, 
    		@Forecastcost = ForecastCost, @totalcmtdUnits = TotalCmtdUnits, @totalcmtdcost = TotalCmtdCost, 
    		@remaincmtdUnits = RemainCmtdUnits, @remaincmtdcost = RemainCmtdCost, @aco = ACO, @acoitem = ACOItem
        from inserted
    else
        begin
    	-- use a cursor to process each inserted row
    	declare bJCCD_insert cursor FAST_FORWARD
    	for select JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, JCTransType, Source, 
    		ReversalStatus, PostedUM,  UM, ActualUnitCost, PerECM, ActualHours, ActualUnits, ActualCost, 
    		EstHours,  EstUnits,  EstCost, ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, 
    		ForecastCost, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, ACO, ACOItem
    	from inserted
    
    	open bJCCD_insert
    
        fetch next from bJCCD_insert into @JCCo, @Mth, @CostTrans, @Job, @PhaseGroup, @Phase, @CostType, 
    		@jctranstype, @source, @reversalstatus, @PostedUM,  @um, @ActualUnitcost, @PerECM, @ActualHours, 
    		@ActualUnits, @Actualcost, @EstHours, @EstUnits, @Estcost, @ProjHours, @ProjUnits, @Projcost, 
    		@ForecastHours, @ForecastUnits, @Forecastcost, @totalcmtdUnits, @totalcmtdcost, @remaincmtdUnits, 
    		@remaincmtdcost, @aco, @acoitem
    
        if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
        end
    
    insert_check:
    
    -- Validate JC Trans Type
    if @jctranstype not in ('JC','OE','PF','PE','MU','CA','PR','CO','MS','AP','MO','MS','JB',
    						'EM','PO','SL','AR','IN','MI','CV','IC','RU')
    	begin
    	select @errmsg = 'Invalid Trans Type.'
    	GoTo error
    	End
       
    -- validate Source
    if @source not in ('AP Entry', 'JC OrigEst','JC CostAdj','JC Projctn', 'JC Progres', 'JC MatUse',
     					'JC ChngOrd', 'PO Entry', 'PO Close','PO Change', 'PO Receipt', 'SL Change', 'SL Close', 
    					'SL Entry', 'PM Intface', 'PR Entry', 'AR Receipt', 'EMRev', 'MS Tickets', 'IN MatlOrd',
    					----TK-07440
    					'JC Plugged', 'Roll Up', 'PO Dist','SM WorkOrd')
    	begin
    	select @errmsg = 'Invalid Source.'
    	GoTo error
    	End
       
    -- reversal status
    if @reversalstatus not in (0,1,2,3,4)
    	begin
    	select @errmsg = 'Reversal Status '+ convert(varchar(2),isnull(@reversalstatus,' ')) + ' is invalid'
    	GoTo error
    	End
    
    -- PerECM
    if @ActualUnitcost<>0 and @PerECM not in ('E','C','M')
    	begin
    	select @errmsg = 'PerECM '+ isnull(@PerECM,' ') + ' is invalid'
    	GoTo error
    	End
       
    -- validate HQUM
    IF @um is not null
    	begin
    	if not exists(select top 1 1 from bHQUM with (nolock) where UM=@um)
    		begin
    		select @errmsg = 'Unit of Measure ' + @um + ' is invalid'
    		GoTo error
    		End
    	end
       
    IF @PostedUM is not null 
    	begin
    	if not exists(select top 1 1 from bHQUM with (nolock) where UM=@PostedUM)
    		begin
    		select @errmsg = 'Posted Unit of Measure ' + @PostedUM + ' is invalid'
    		GoTo error
    		End
    	end
    
    -- Validate JCOD
    if @aco is not null or @acoitem is not null
    	begin
    	if not exists(select top 1 1 from bJCOD with (nolock) where JCCo=@JCCo and Job=@Job and ACO=@aco 
    				and ACOItem=@acoitem and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType)
    		begin
    		select @errmsg = 'ACO Item is invalid'
    		goto error
    		end
    	end
    
    -- if insert is a roll up source, No validation is needed 
    if @jctranstype <> 'RU'   -- @source <> 'Roll Up'
    	begin
    	---- validate standard phase - if it doesnt exist in JCJP try to add it
   		if @source <> 'JC Projctn'
   			begin
   			---- #135151
   			if @source = 'PM Intface' select @override='O'
   	 		exec @rcode = bspJCADDPHASE @JCCo, @Job, @PhaseGroup, @Phase, @override, null, @errmsg output
   	 		if @rcode <> 0
   	 			begin
   	 			GoTo error
   	 			End
   			end
   
   		---- if source is PM or JC Projctn, the @override must be P
   		if @source = 'PM Intface' or @source = 'JC Projctn' select @override='P'
	   
    	---- validate Cost Type - if JCCH doesnt exist try to add it
    	exec @rcode = bspJCADDCOSTTYPE @jcco=@JCCo, @job=@Job, @phasegroup=@PhaseGroup, @phase=@Phase, 
    									   @costtype=@CostType, @override=@override, @msg=@errmsg output
    	if @rcode <> 0
    		begin
    		GoTo error
    		End
    	end 
    
    
    
    -------- update bJCCP - make sure this always the last section of code after all validations ----------
    
    -- parse out Original amounts only 'OE' are Original Estimates
    if @jctranstype='OE'
    	select @OrigEstHours=@EstHours, @OrigEstUnits=@EstUnits, @OrigEstcost=@Estcost
    Else
    	select @OrigEstHours=0, @OrigEstUnits=0, @OrigEstcost=0
    
    -- parse out Units only if UM = bJCCH.UM
    -- TV 05/25/04 24667 need to change this to look at the Posted UM
    -- -- -- GF 03/29/05 27492 put back way it was. JCCP is update when actual um (@um) equals JCCH.UM 
    if isnull(@um,'') <> (select UM from bJCCH with (nolock) where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup
     				and Phase=@Phase and CostType=@CostType)
    	begin
    	select @ActualUnits=0, @OrigEstUnits=0, @EstUnits=0, @ProjUnits=0,
    		   @ForecastUnits=0, @totalcmtdUnits=0, @remaincmtdUnits=0
    	End
    
    
---- check if JCCP record exists, if not insert JCCP record
if exists(select 1 from bJCCP with (nolock) where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup
    				and Phase=@Phase and CostType=@CostType and Mth=@Mth)
		goto JCCP_update
else
	begin
	insert into bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth)
	select @JCCo, @Job, @PhaseGroup, @Phase, @CostType, @Mth
	end



JCCP_update:
---- update JCCP record - only when needed values exist
if isnull(@ActualHours,0) <> 0 or isnull(@ActualUnits,0) <> 0 or isnull(@Actualcost,0) <> 0 or
		isnull(@OrigEstHours,0) <> 0 or isnull(@OrigEstUnits,0) <> 0 or isnull(@OrigEstcost,0) <> 0 or
		isnull(@EstHours,0) <> 0 or isnull(@EstUnits,0) <> 0 or isnull(@Estcost,0) <> 0 or
		isnull(@ProjHours,0) <> 0 or isnull(@ProjUnits,0) <> 0 or isnull(@Projcost,0) <> 0 or
		isnull(@ForecastHours,0) <> 0 or isnull(@ForecastUnits,0) <> 0 or isnull(@Forecastcost,0) <> 0 or
		isnull(@totalcmtdUnits,0) <> 0 or isnull(@totalcmtdcost,0) <> 0 or
		isnull(@remaincmtdUnits,0) <> 0 or isnull(@remaincmtdcost,0) <> 0
	begin
	---- update JCCP
	update bJCCP
    	set ActualHours = ActualHours + @ActualHours,
    		ActualUnits = ActualUnits + @ActualUnits,
    		ActualCost = ActualCost + @Actualcost,
    		OrigEstHours = OrigEstHours + @OrigEstHours,
    		OrigEstUnits = OrigEstUnits + @OrigEstUnits,
    		OrigEstCost = OrigEstCost + @OrigEstcost,
    		CurrEstHours = CurrEstHours + @EstHours,
    		CurrEstUnits = CurrEstUnits + @EstUnits,
    		CurrEstCost = CurrEstCost + @Estcost,
    		ProjHours = ProjHours + @ProjHours,
    		ProjUnits = ProjUnits + @ProjUnits,
    		ProjCost = ProjCost + @Projcost,
    		ForecastHours = ForecastHours + @ForecastHours,
    		ForecastUnits = ForecastUnits + @ForecastUnits,
    		ForecastCost = ForecastCost + @Forecastcost,
    		TotalCmtdUnits = TotalCmtdUnits + @totalcmtdUnits,
    		TotalCmtdCost = TotalCmtdCost + @totalcmtdcost,
    		RemainCmtdUnits = RemainCmtdUnits + @remaincmtdUnits,
    		RemainCmtdCost = RemainCmtdCost + @remaincmtdcost
    where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType and Mth=@Mth
	end
    ------------ Notice ----------
    -- TotalCmtdUnits is updated by PO/SL/AP - DO NOT update these fields in this trigger



if @numrows > 1
	begin
	fetch next from bJCCD_insert into @JCCo, @Mth, @CostTrans, @Job, @PhaseGroup, @Phase, @CostType, 
    		@jctranstype, @source, @reversalstatus, @PostedUM,  @um, @ActualUnitcost, @PerECM, @ActualHours, 
    		@ActualUnits, @Actualcost, @EstHours, @EstUnits, @Estcost, @ProjHours, @ProjUnits, @Projcost, 
    		@ForecastHours, @ForecastUnits, @Forecastcost, @totalcmtdUnits, @totalcmtdcost, @remaincmtdUnits, 
    		@remaincmtdcost, @aco, @acoitem

	if @@fetch_status = 0
		goto insert_check
	else
		begin
		close bJCCD_insert
		deallocate bJCCD_insert
		end
	end



Return


error:
	select @errmsg = @errmsg + ' - cannot insert Cost Detail Trans # ' + convert(varchar(12),isnull(@CostTrans,0)) + ' Phase ' + isnull(@Phase,'') + ' Cost Type ' + convert(varchar(3),isnull(@CostType,0))
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
    
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.btJCCDu    Script Date: 8/28/99 9:38:23 AM ******/
CREATE   trigger [dbo].[btJCCDu] on [dbo].[bJCCD] for update as
/**************************************************************
    * This trigger rejects update in bJCCD (JC Cost Detail)
    * if the following error condition exists:
    * Created By:	JRE 12/10/96
    * Modified By: DanF 06/01/00 Added source for JC MatUse
    *              DanF 06/12/00 Added additional Sources for update source check
    *              DanF 09/27/00 Correct GL Offset Account Validation.
    *				GG 10/28/00 - Added source 'MS Tickets'
    *				GG 04/10/01 - change GL Account validation to use bspGLACfPostable
    *           	GF 04/30/2001 - added JCTransSource and Source for IN Material Orders
    *           	kb 9/4/1 - issue #13963
    *           	kb 10/16/1 - issue #14922
    *           	kb 2/27/2 - issue #16432
    *           	danf 03/29/02 - Added JCTransType of 'IC' for InterCompany Transactions.
    *			  	GF 06/03/2002 - See issue #17480 changing JCCH.UM
    *			  	kb 7/22/2 - issue #18038 - only update billstatus is it is different then what it was before
    *           	DANF 09/06/02 - 17738 Added Phase Group to bspJCADDCOSTTYPE
    *			  	GF 01/30/2003 - issue #19737 - too restrictive on when to update/insert JCCP records. Remmed out.
    *				GF 12/03/2003 - issue #23130 - performance improvements
    *				GF 03/29/2005 - issue #27492 - possible Actual UM is null (JCCD.UM), wrapped in isnull.
    *				GF 01/08/2008 - issue #126441 more performance changes, update JCCP only when we have values.
    *   			JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
    *				GF 05/25/2010 - issue #137811 - added offset glco for material use 'JC MatUse' transactions.
    *				GF 08/26/2011 TK-07440 PO Item Line
    *				TL 02/04/2012 TK-12244 modify for SM
    *
    *      invalid Phase or CostType
    *      invalid GLTransAcct
    *      invalid GLOffsetAcct
    *              TransType not in 'OE' or '- currently only insert are allowed
    *      Still needs check for valid BatchId, inuseBatchId, reversal status, ECM,
    *      postedum, ACO, ACOItem
    *      Updates corresponding fields in JCCP.
    *      note
    *      (Future checks AP, PM, PR, MS, EM, PO, ???)
    *  This trigger does not use a cursor, rather it iterates througt the inserted
    *      table using @JCCo, @Mth & @CostTrans
    *
    **************************************************************/
declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @numrows int, @rcode int,
   		@OrigEstcost bDollar, @OrigEstUnits bUnits, @OrigEstHours bHrs, @override char(1), 
   		@updateflag tinyint, @subtype char(1), @jcco bCompany, @mth bMonth, @costtrans bTrans, 
   		@Job bJob, @PhaseGroup tinyint, @Phase bPhase, @CostType bJCCType, @jctranstype varchar(2),
   		@source bSource, @glco bCompany, @gltransacct bGLAcct, @gloffsetacct bGLAcct, 
   		@reversalstatus tinyint, @PostedUM bUM, @um bUM, @ActualUnitcost bUnitCost, @PerECM bECM, 
   		@ActualHours bHrs, @ActualUnits bUnits, @Actualcost bDollar, @EstHours bHrs, @EstUnits bUnits, 
   		@Estcost bDollar, @ProjHours bHrs,  @ProjUnits bUnits, @Projcost bDollar, @ForecastHours bHrs, 
   		@ForecastUnits bUnits, @Forecastcost bDollar, @totalcmtdUnits bUnits, @totalcmtdcost bDollar, 
   		@remaincmtdUnits bUnits, @remaincmtdcost bDollar, @aco bACO, @acoitem bACOItem, 
   		@billstatus tinyint, @billnum int, @billmth bMonth, @OffsetGLCo bCompany

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

	--If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bJCCD', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END    

set @override='N'

-- see if any fields have changed that is not allowed
if update(JCCo) or Update(Mth) or Update(CostTrans)
   	begin
   	select @validcnt = count(*) from inserted i
   	JOIN deleted d ON d.JCCo = i.JCCo and d.Mth=i.Mth and d.CostTrans=i.CostTrans
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Primary key fields may not be changed'
   		GoTo error
   		End
   	End

-- if we are pulling a transaction into batch and updating InUseBatchId
-- with a batch id then skip trigger validation.
if Update(InUseBatchId) 
	begin
	select @validcnt = count(*) from inserted i where InUseBatchId is not null
   	select @validcnt2 = count(*) from deleted d where InUseBatchId is null
   	if @validcnt = @validcnt2 and @validcnt = @numrows goto Trigger_Skip
	End


if @numrows = 1
	begin
   	select @jcco = JCCo, @mth = Mth, @costtrans = CostTrans, @Job = Job, @PhaseGroup = PhaseGroup, @Phase = Phase, 
   		@CostType = CostType, @jctranstype = JCTransType, @source = Source, @glco = GLCo, @gltransacct = GLTransAcct,
   		@gloffsetacct = GLOffsetAcct, @reversalstatus = ReversalStatus, @PostedUM = PostedUM, @um = UM, 
   		@ActualUnitcost = ActualUnitCost, @PerECM = PerECM, @ActualHours = ActualHours, @ActualUnits = ActualUnits, 
   		@Actualcost = ActualCost, @EstHours = EstHours,  @EstUnits = EstUnits, @Estcost = EstCost,
   		@ProjHours = ProjHours, @ProjUnits = ProjUnits, @Projcost = ProjCost, @ForecastHours = ForecastHours, 
   		@ForecastUnits = ForecastUnits, @Forecastcost = ForecastCost, @totalcmtdUnits = TotalCmtdUnits, 
   		@totalcmtdcost = TotalCmtdCost, @remaincmtdUnits = RemainCmtdUnits, @remaincmtdcost = RemainCmtdCost, 
   		@aco = ACO, @acoitem = ACOItem, @billnum = JBBillNumber, @billmth = JBBillMonth, @billstatus = JBBillStatus,
   		----#137811
   		@OffsetGLCo = OffsetGLCo
	from inserted
	end
else
	begin
	---- use a cursor to process each updated row
	declare bJCCD_update cursor LOCAL FAST_FORWARD
   	for select JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, JCTransType, Source, GLCo, 
   		GLTransAcct, GLOffsetAcct, ReversalStatus, PostedUM, UM, ActualUnitCost, PerECM, 
   		ActualHours, ActualUnits, ActualCost, EstHours, EstUnits, EstCost,ProjHours, ProjUnits, ProjCost,
   		ForecastHours, ForecastUnits, ForecastCost, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, 
   		RemainCmtdCost, ACO, ACOItem, JBBillNumber, JBBillMonth, JBBillStatus,
		----#137811
   		OffsetGLCo
   	from inserted

	open bJCCD_update

	fetch next from bJCCD_update into @jcco, @mth, @costtrans, @Job, @PhaseGroup, @Phase, @CostType,
   		@jctranstype, @source, @glco, @gltransacct, @gloffsetacct, @reversalstatus, @PostedUM, @um, 
   		@ActualUnitcost, @PerECM,  @ActualHours, @ActualUnits, @Actualcost, @EstHours, @EstUnits, 
   		@Estcost, @ProjHours, @ProjUnits, @Projcost, @ForecastHours, @ForecastUnits, @Forecastcost, 
   		@totalcmtdUnits, @totalcmtdcost, @remaincmtdUnits, @remaincmtdcost, @aco, @acoitem, @billnum, @billmth, @billstatus,
		----#137811
   		@OffsetGLCo
   		
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end



update_check:
---- Validate JC Trans Type
if update(JCTransType)
   	begin
   	if @jctranstype not in ('JC','OE','PF','PE','MU','CA','PR','CO','MS','AP','MO','MS','JB','EM','PO','SL','IN','MI','CV','IC')
   		begin
   		select @errmsg = 'TransType ' + isnull(@jctranstype,'') + ' is invalid.'
   		GoTo error
   		end
   	end

---- validate Source
if update(Source)
   	Begin
   	if @source not in ('AP Entry', 'JC OrigEst','JC CostAdj','JC Projctn', 'JC Progres','JC MatUse',
   				'JC ChngOrd', 'PO Entry', 'PO Close','PO Change', 'PO Receipt', 'SL Change', 'SL Close',
   				'SL Entry', 'PM Intface', 'PR Entry', 'AR Receipt', 'EMRev', 'MS Tickets', 'IN MatlOrd',
   				----TK-07440
   				'JC Plugged', 'PO Dist','SM WorkOrd')
   		begin
   		select @errmsg = 'Source ' + isnull(@source,'') + ' is invalid.'
   		GoTo error
   		End
   	End

---- reversal status
if update(ReversalStatus)
   	begin
   	if @reversalstatus not in (0,1,2,3)
   		begin
   		select @errmsg = 'Reversal Status '+ convert(varchar(2),isnull(@reversalstatus,'')) + ' is invalid'
   		GoTo error
   		End
   	end

-- PerECM
if update(ActualUnitCost) or update(PerECM)
   	begin
   	if @ActualUnitcost <> 0 and @PerECM not in ('E','C','M')
   		begin
   		select @errmsg = 'PerECM '+ isnull(@PerECM,'') + ' is invalid'
   		GoTo error
   		End
   	end

-- check GL TransAcct
if @gltransacct is not null and update(GLTransAcct)
   	begin
   	exec @rcode = dbo.bspGLACfPostable @glco, @gltransacct, 'J', @errmsg output
   	if @rcode <> 0 goto error
   	End

if @gloffsetacct is not null and update(GLOffsetAcct)
   	begin
   	set @subtype = 'J'
	----#137811
   	if @source = 'JC MatUse' and  @jctranstype = 'IN'
   		begin
   		set @subtype = 'I'
		exec @rcode = dbo.bspGLACfPostable @OffsetGLCo, @gloffsetacct, @subtype, @errmsg output
		if @rcode <> 0 goto error
		end
	else
		begin
		exec @rcode = dbo.bspGLACfPostable @glco, @gloffsetacct, @subtype, @errmsg output
		if @rcode <> 0 goto error
		end
	end
	----#137811

-- validate HQUM
if update(UM) or update(PostedUM)
   	begin
   	if @um is not null and not exists (select top 1 1 from bHQUM where UM=@um)
   		begin
   		select @errmsg = 'Unit of Measure ' + isnull(@um,'') + ' is invalid'
   		GoTo error
   		End
   
   	if @PostedUM is not null and not exists (select top 1 1 from bHQUM where UM=@PostedUM)
   		begin
   		select @errmsg = 'Posted Unit of Measure ' + isnull(@PostedUM,'') + ' is invalid'
   		GoTo error
   		End
   	end

-- Validate JCOD
if update(ACO)
   	begin
   	if @aco is not null or @acoitem is not null
   		begin
   		select @validcnt = count(*) from bJCOD with (nolock)
   		where JCCo=@jcco and Job=@Job and ACO=@aco and ACOItem=@acoitem
   		and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   		if @validcnt <> 1
   			begin
   			select @errmsg = 'ACO Item is invalid'
   			goto error
   			end
   		end
   	end

-- validate standard phase - if it doesnt exist in JCJP try to add it
if update(Job) or update(Phase)
   	begin
   	exec @rcode = dbo.bspJCADDPHASE @jcco, @Job, @PhaseGroup, @Phase, @override, null, @errmsg output
   	if @rcode<>0 goto error
   	-- if source is PM, the @override must be P
   	if @source = 'PM Intface' select @override = 'P'
   	end

-- validate cost type - if JCCH does not exist try to add it
if update(Job) or update(Phase) or update(CostType)
   	begin
   	exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@jcco, @job=@Job, @phasegroup=@PhaseGroup, @phase=@Phase,
   						@costtype=@CostType, @override= @override, @msg=@errmsg output
   	if @rcode<>0 goto error
   	end


set @updateflag = 0 -- reset flag for inserted records

nextupdate:
---- update bJCCP - make sure this always the last section of code after all validations
---- read deleted records on the second pass
if @updateflag = 1 
   	begin
   	select @Job = Job, @PhaseGroup = PhaseGroup, @Phase = Phase, @CostType = CostType,
   		   @jctranstype=JCTransType,  @um=UM, @ActualHours = -ActualHours, @ActualUnits = -ActualUnits,
   		   @Actualcost = -ActualCost, @EstHours = -EstHours,  @EstUnits = -EstUnits,  @Estcost = -EstCost,
   		   @ProjHours = -ProjHours, @ProjUnits = -ProjUnits, @Projcost = -ProjCost,
   		   @ForecastHours = -ForecastHours, @ForecastUnits = -ForecastUnits, @Forecastcost = -ForecastCost,
   		   @totalcmtdUnits = -TotalCmtdUnits, @totalcmtdcost = -TotalCmtdCost,
   		   @remaincmtdUnits = -RemainCmtdUnits, @remaincmtdcost = -RemainCmtdCost
   	from deleted where JCCo = @jcco and Mth = @mth and CostTrans = @costtrans
   	end

---- parse out Original amounts only 'OE' are Original Estimates
if @jctranstype='OE'
   	begin
   	select @OrigEstHours=@EstHours, @OrigEstUnits=@EstUnits, @OrigEstcost=@Estcost
   	end
else
   	begin
   	select @OrigEstHours=0, @OrigEstUnits=0, @OrigEstcost=0
   	end

---- parse out Units only if UM = bJCCH.UM and update flag = 0
if @updateflag = 0
   	begin
   	---- #27492
   	if isnull(@um,'') <> (select UM from bJCCH where JCCo=@jcco and Job=@Job and PhaseGroup=@PhaseGroup
   							and Phase=@Phase and CostType=@CostType)
   		begin
   		select @ActualUnits=0, @OrigEstUnits=0, @EstUnits=0, @ProjUnits=0, 
   			   @ForecastUnits=0, @totalcmtdUnits=0, @remaincmtdUnits=0
   		end
   	end
else
   	begin
   	---- #27492
   	---- when update flag = 1 then only parse out units for committed
   	if isnull(@um,'') <> (select UM from bJCCH where JCCo=@jcco and Job=@Job and PhaseGroup=@PhaseGroup
   							and Phase=@Phase and CostType=@CostType)
   		begin
   		select @totalcmtdUnits=0, @remaincmtdUnits=0
   		end
   	end

---- insert JCCP record if it doesnt exist
if not exists(select top 1 1 from bJCCP where JCCo=@jcco and Job=@Job and PhaseGroup=@PhaseGroup
   						and Phase=@Phase and CostType=@CostType and Mth=@mth)
   	begin
   	insert into bJCCP(JCCo, Job, PhaseGroup, Phase, CostType, Mth)
   	select @jcco, @Job, @PhaseGroup, @Phase, @CostType, @mth
   	end

---- update JCCP record - only when needed values exist
if isnull(@ActualHours,0) <> 0 or isnull(@ActualUnits,0) <> 0 or isnull(@Actualcost,0) <> 0 or
		isnull(@OrigEstHours,0) <> 0 or isnull(@OrigEstUnits,0) <> 0 or isnull(@OrigEstcost,0) <> 0 or
		isnull(@EstHours,0) <> 0 or isnull(@EstUnits,0) <> 0 or isnull(@Estcost,0) <> 0 or
		isnull(@ProjHours,0) <> 0 or isnull(@ProjUnits,0) <> 0 or isnull(@Projcost,0) <> 0 or
		isnull(@ForecastHours,0) <> 0 or isnull(@ForecastUnits,0) <> 0 or isnull(@Forecastcost,0) <> 0 or
		isnull(@totalcmtdUnits,0) <> 0 or isnull(@totalcmtdcost,0) <> 0 or
		isnull(@remaincmtdUnits,0) <> 0 or isnull(@remaincmtdcost,0) <> 0
	begin
	Update bJCCP set ActualHours = ActualHours + @ActualHours,
   				ActualUnits = ActualUnits + @ActualUnits,
   				ActualCost = ActualCost + @Actualcost,
   				OrigEstHours = OrigEstHours + @OrigEstHours,
   				OrigEstUnits = OrigEstUnits + @OrigEstUnits,
   				OrigEstCost = OrigEstCost + @OrigEstcost,
   				CurrEstHours = CurrEstHours + @EstHours,
   				CurrEstUnits = CurrEstUnits + @EstUnits,
   				CurrEstCost = CurrEstCost + @Estcost,
   				ProjHours = ProjHours + @ProjHours,
   				ProjUnits = ProjUnits + @ProjUnits,
   				ProjCost = ProjCost + @Projcost,
   				ForecastHours = ForecastHours + @ForecastHours,
   				ForecastUnits = ForecastUnits + @ForecastUnits,
   				ForecastCost = ForecastCost + @Forecastcost,
   				TotalCmtdUnits = TotalCmtdUnits + @totalcmtdUnits,
   				TotalCmtdCost = TotalCmtdCost + @totalcmtdcost,
   				RemainCmtdUnits = RemainCmtdUnits + @remaincmtdUnits,
   				RemainCmtdCost = RemainCmtdCost + @remaincmtdcost
	where JCCo=@jcco and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType and Mth=@mth
	end

---- ******* Notice *****
---- TotalCmtdUnits is updated by PO/SL/AP - DO NOT update these fields in this trigger
---- if updateflag=0 then we have just update JCCP with the new values
--- now we need to subtract the old values from JCCP
if @updateflag = 0
   	begin
   	set @updateflag = 1
   	GoTo nextupdate
   	End

-- update bJBIJ when JBBillStatus changed
if update(JBBillStatus)
   	begin
   	update bJBIJ set BillStatus = @billstatus 
   	from bJBIJ where JBCo = @jcco and JCMonth = @mth and JCTrans = @costtrans
   	and BillStatus <> @billstatus and BillNumber = @billnum and BillMonth = @billmth
   	end



if @numrows > 1
	begin
   	fetch next from bJCCD_update into @jcco, @mth, @costtrans, @Job, @PhaseGroup, @Phase, @CostType,
   		@jctranstype, @source, @glco, @gltransacct, @gloffsetacct, @reversalstatus, @PostedUM, @um, 
   		@ActualUnitcost, @PerECM,  @ActualHours, @ActualUnits, @Actualcost, @EstHours, @EstUnits, 
   		@Estcost, @ProjHours, @ProjUnits, @Projcost, @ForecastHours, @ForecastUnits, @Forecastcost, 
   		@totalcmtdUnits, @totalcmtdcost, @remaincmtdUnits, @remaincmtdcost, @aco, @acoitem, @billnum, 
   		@billmth, @billstatus,
   		----#137811
   		@OffsetGLCo
   		
    	if @@fetch_status = 0 goto update_check

    	close bJCCD_update
    	deallocate bJCCD_update
    	end




Trigger_Skip:
	Return


error:
   	select @errmsg = @errmsg + ' - cannot update Cost Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biJCCDTrans] ON [dbo].[bJCCD] ([CostTrans], [Mth], [JCCo]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCCD] ON [dbo].[bJCCD] ([JCCo], [Job], [Phase], [CostType], [Mth], [CostTrans]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCCD] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bJCCD_MthJCCoTransSource] ON [dbo].[bJCCD] ([Mth], [JCCo], [CostTrans], [Source]) INCLUDE ([UniqueAttchID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biJCCDUniqueAttchID] ON [dbo].[bJCCD] ([UniqueAttchID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ReversalStatus]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ActualUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJCCD].[PerECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ActualHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ActualUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ActualCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ProgressCmplt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[EstHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[EstUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[EstCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ProjHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ProjUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ProjCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ForecastHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ForecastUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[ForecastCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[PostedUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[PostedUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJCCD].[PostedECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[PostTotCmUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[PostRemCmUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[TotalCmtdUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[TotalCmtdCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[RemainCmtdUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[RemainCmtdCost]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCD].[DeleteFlag]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bJCCD].[DeleteFlag]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[INStdUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJCCD].[INStdECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[TaxBasis]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCD].[TaxAmt]'
GO
