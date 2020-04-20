CREATE TABLE [dbo].[bJCCH]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[BillFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ItemUnitFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCH_ItemUnitFlag] DEFAULT ('N'),
[PhaseUnitFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCH_PhaseUnitFlag] DEFAULT ('N'),
[BuyOutYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCH_BuyOutYN] DEFAULT ('N'),
[LastProjDate] [smalldatetime] NULL,
[Plugged] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCH_Plugged] DEFAULT ('N'),
[ActiveYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCH_ActiveYN] DEFAULT ('Y'),
[OrigHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCCH_OrigHours] DEFAULT ((0)),
[OrigUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCH_OrigUnits] DEFAULT ((0)),
[OrigCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCH_OrigCost] DEFAULT ((0)),
[ProjNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[SourceStatus] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCCH_SourceStatus] DEFAULT ('J'),
[InterfaceDate] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[udDateCreated] [smalldatetime] NULL,
[udDateChanged] [smalldatetime] NULL,
[udSellRate] [dbo].[bDollar] NULL,
[udMarkup] [dbo].[bPct] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCCHd    Script Date: 8/28/99 9:37:41 AM ******/
CREATE trigger [dbo].[btJCCHd] on [dbo].[bJCCH] for DELETE as
/*-----------------------------------------------------------------
 *	This trigger deletes bJCCH  (JC Cost Header)
 *	following error condition exists:
 *
 *	JCCP, JCCD, JCOD, PMOL records exist
 *
 *	JRE 11/15/96
 *  MOD 11/19/98
 *  MOD 05/26/99 - changed counts to if exists & force index
 *  TV 08/20/01 - Different Validation for non-OE trans types
 *  TV 01/10/02 - Check actuals by Month
 *	GF 01/22/2002 - only care about PMSL and PMMF if not assigned, else allow delete.
 *  CMW 03/15/02 - issue # 16503 JCCP column name changes
 *	GF 06/24/2002 - don't use PhaseGroup in where clause.
 *	GF 08/08/2002 - issue #17355 - auto add contract item enhancement
 *	GF 10/14/2004 - issue #25679 - added isnull's to @errmsg when accumulating various errors. Ansi-Null problem.
 *	GF 04/20/2007 - issue #124414 ADDED HQMA auditing
 *	GF 05/29/2009 - issue #133735 changed auto-add item option to allow for other JCCH source status.
 *
 *
 *
 *----------------------------------------------------------------*/
declare @rcode int, @errmsg varchar(255), @numrows int, @validcnt int, @mth bMonth,
		@ActualHours bHrs, @ActualUnits bUnits, @ActualCost bDollar,
		@OrigEstHours bHrs,@OrigEstUnits bUnits, @OrigEstCost bDollar,
		@CurrEstHours bHrs, @CurrEstUnits bUnits, @CurrEstCost bDollar,
		@ProjHours bHrs, @ProjUnits bUnits, @ProjCost bDollar,
		@TotalCmtdUnits bUnits, @TotalCmtdCost bDollar, @RemainCmtdUnits bUnits,
   		@RemainCmtdCost bDollar, @RecvdNotInvcdUnits bUnits, @RecvdNotInvcdCost bDollar

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @rcode = 0

/***** validate Cost Detail ******/
if exists(select * from bJCCD j join deleted d on j.JCCo = d.JCCo and j.Job = d.Job
   			and j.Phase=d.Phase and j.CostType=d.CostType where j.JCTransType <> 'OE')
   	begin
	---- First see if actuals net to 0 by month
	declare bcActualTotal cursor LOCAL FAST_FORWARD for select Mth 
   	from bJCCP j join deleted d on d.JCCo=j.JCCo and d.Job=j.Job and d.Phase=j.Phase and d.CostType=j.CostType
   
   	open bcActualTotal
   
   	FetchNext:
   	fetch next from bcActualTotal into @mth
   	if @@fetch_status <> 0  goto EndActual
   
   	select @ActualHours = sum(j.ActualHours), @ActualUnits = sum(j.ActualUnits), @ActualCost = sum(j.ActualCost)
   	from bJCCP j join deleted d
   	on d.JCCo=j.JCCo and d.Job=j.Job /*and d.PhaseGroup=j.PhaseGroup*/ and d.Phase=j.Phase
   	and d.CostType=j.CostType and j.Mth = @mth
   
   	--Actuals
   	if @ActualHours <> 0 or @ActualUnits <> 0 or @ActualCost <> 0
   		begin
   		select @errmsg = 'Actual Hours/Units/Cost do not net zero.' + char(13), @rcode = 1
   		goto EndActual
   		end
   
   	goto FetchNext
   
   	EndActual:
   	close bcActualTotal
   	deallocate bcActualTotal
   
   
   	-- -- -- If the JC Trans type is not an Original Estimate then we want to verify that
   	-- -- -- there are not any outstanding Cost that do not net to 0
   	select @OrigEstHours = sum(j.OrigEstHours),
                        @OrigEstUnits = sum(j.OrigEstUnits),
                        @OrigEstCost =  sum(j.OrigEstCost),
                        @CurrEstHours = sum(j.CurrEstHours),
                        @CurrEstUnits =  sum(j.CurrEstUnits),
                        @CurrEstCost =  sum(j.CurrEstCost),
                        @ProjHours = sum(j.ProjHours),
                        @ProjUnits  = sum(j.ProjUnits),
                        @ProjCost = sum(j.ProjCost),
                        @TotalCmtdUnits = sum(j.TotalCmtdUnits),
                        @TotalCmtdCost = sum(j.TotalCmtdCost),
                        @RemainCmtdUnits = sum(j.RemainCmtdUnits),
                        @RemainCmtdCost = sum(j.RemainCmtdCost),
                        @RecvdNotInvcdUnits = sum(j.RecvdNotInvcdUnits),
                        @RecvdNotInvcdCost = sum(j.RecvdNotInvcdCost)
   	from bJCCP j join deleted d
   	on d.JCCo=j.JCCo and d.Job=j.Job /*and d.PhaseGroup=j.PhaseGroup*/ and d.Phase=j.Phase and d.CostType=j.CostType
   
   	--validate to see if Net 0
   	--Originals
   	if @OrigEstHours  <> 0 or @OrigEstUnits <> 0 or @OrigEstCost <> 0
   	select @errmsg = isnull(@errmsg,'') + ' Original Hours/Units/Cost do not net zero.' + char(13), @rcode = 1
   
   	--Current
   	if @CurrEstHours <> 0 or @CurrEstUnits <> 0 or @CurrEstCost <> 0
   	select @errmsg =  isnull(@errmsg,'') + ' Current Hours/Units/Cost do not net zero.' + char(13), @rcode = 1
   
   	--Projected
   	if @ProjHours <> 0 or @ProjUnits <> 0 or @ProjCost <> 0
   	select @errmsg =  isnull(@errmsg,'') + ' Projected Hours/Units/Cost do not net zero.' + char(13), @rcode = 1
   
   	--Commited
   	if @TotalCmtdUnits <> 0 or @TotalCmtdCost <> 0
   	select @errmsg =  isnull(@errmsg,'') + ' Total Committed Units/Cost do not net zero.' + char(13), @rcode = 1
   
   	--Reamining Commited
   	if @RemainCmtdUnits <> 0 or @RemainCmtdCost <>0
   	select @errmsg =  isnull(@errmsg,'') + ' Remaining Committed Units/Cost do not net zero.' + char(13), @rcode = 1
   
   	--Recived
   	if @RecvdNotInvcdUnits <> 0 or @RecvdNotInvcdCost <> 0
   	select @errmsg =  isnull(@errmsg,'') +  'Received Units/Cost do not net zero.' + char(13), @rcode = 1
 
   	END


/***** validate Change Order Detail *****/
If exists(SELECT * FROM bJCOD j JOIN deleted  d ON j.JCCo = d.JCCo and j.Job = d.Job
    			and j.Phase=d.Phase and j.CostType=d.CostType)
    	SELECT @errmsg = isnull(@errmsg,'') + 'Approved Change Order Detail exists.' + char(13), @rcode = 1
   
/***** validate PM Change Order Detail *****/
If exists(SELECT *  FROM bPMOL j JOIN deleted  d on j.PMCo = d.JCCo and j.Project = d.Job
    			and j.Phase=d.Phase and j.CostType=d.CostType)
    	select @errmsg = isnull(@errmsg,'') + 'PM Change Order Detail exists.' + char(13), @rcode = 1
   
/***** validate PM Subcontract Detail *****/
If exists(SELECT *  FROM bPMSL j JOIN deleted d on j.PMCo = d.JCCo and j.Project = d.Job
    			and j.Phase=d.Phase and j.CostType=d.CostType and j.SL is not null)
    	select @errmsg = isnull(@errmsg,'') + 'PM Subcontract Detail exists and has been assigned.' + char(13), @rcode = 1
   
/***** validate PM Material Detail *****/
If exists(SELECT * FROM bPMMF j JOIN deleted  d on j.PMCo = d.JCCo and j.Project = d.Job and j.Phase=d.Phase
   			and j.CostType=d.CostType and (j.PO is not null or j.MO is not null or j.Quote is not null))
    	select @errmsg = isnull(@errmsg,'') + 'PM Material Detail exists and has been assigned.' + char(13), @rcode = 1

if @rcode <> 0 goto error


/************************
 * delete original estimate records from bJCCD
 ************************/
delete bJCCD from bJCCD j join deleted d on d.JCCo=j.JCCo and d.Job=j.Job and d.Phase=j.Phase and d.CostType=j.CostType

/************************************************
 * delete bJCCP records - all amounts should be 0
 ************************************************/
delete bJCCP from bJCCP j join deleted d on d.JCCo=j.JCCo and d.Job=j.Job and d.Phase=j.Phase and d.CostType=j.CostType

---- validate Cost By Period
if exists(SELECT * FROM bJCCP j JOIN deleted d ON j.JCCo = d.JCCo and j.Job = d.Job and j.Phase=d.Phase and j.CostType=d.CostType)
	begin
	select @errmsg = 'Activity in Cost By Period exists', @rcode = 1
	goto error
	end

---- delete records from PMSL
delete bPMSL from bPMSL j join deleted d on d.JCCo=j.PMCo and d.Job=j.Project and d.Phase=j.Phase and d.CostType=j.CostType

---- delete records from PMMF
delete bPMMF from bPMMF j join deleted d on d.JCCo=j.PMCo and d.Job=j.Project and d.Phase=j.Phase and d.CostType=j.CostType

---- if JCJM.AutoAddItemYN flag is 'Y' and the JCCH.SourceStatus is 'Y' or 'N' (PM Only)
---- and contract item is assigned then update OrigContractAmt in bJCCI with JCCH.OrigCost
---- source status no longer applies #133735
Update bJCCI set OrigContractAmt = i.OrigContractAmt - d.OrigCost
from deleted d join bJCJP p on p.JCCo=d.JCCo and p.Job=d.Job and p.Phase=d.Phase
join bJCJM j on j.JCCo=d.JCCo and j.Job=d.Job
join bJCCM c on c.JCCo=j.JCCo and c.Contract=j.Contract
join bJCCI i on i.JCCo=c.JCCo and i.Contract=c.Contract and i.Item=p.Item
---- issue #133735
where /*d.SourceStatus in ('Y', 'N') and*/ p.Item is not null and j.ClosePurgeFlag = 'N' and j.AutoAddItemYN = 'Y'



---- Auditing
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCCH','JCCo: ' + convert(varchar(3),deleted.JCCo) + ' Job: ' + deleted.Job + ' Phase: ' + deleted.Phase + ' CostType: ' + convert(varchar(3),deleted.CostType),
		deleted.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted join bJCCO ON deleted.JCCo=bJCCO.JCCo
where bJCCO.AuditCostTypes = 'Y'



error:
	if @rcode <> 0
		begin
		select @errmsg = isnull(@errmsg,'') + ' - cannot delete JC Cost Header!'
		RAISERROR(@errmsg, 11, -1);
		rollback transaction
		END


   	return
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCCHi    Script Date: 8/28/99 9:38:23 AM ******/
CREATE  TRIGGER [dbo].[btJCCHi] ON [dbo].[bJCCH] FOR INSERT as
/*-----------------------------------------------------------------
 * Created By:	JRE 04/10/97
 * Modified By:	JRE 07/10/97
 *				LM 6/2/98 - Added change to check sourcestatus for special PM stuff.
 *				DANF 03/14/00 - edit description returned on closed job error.
 *				JRE 2/24/01 - changed PostedDate to system date when creating JCCD 'OE' record
 *				GF 08/08/2002 - issue #17355 - auto add contract item enhancement
 *				GF 08/07/2003 - issue #21933 - speed improvements
 *				GF 04/20/2007 - issue #124414 - added HQMA auditing
 *				GF 12/11/2007 - issue #25569 - use separate JCCO posting closed job flags.
 *				GF 04/21/2009 - issue #132326 original estimates moved by JCCI start month
 *				GF 05/29/2009 - issue #133735 changed auto-add item option to allow for other JCCH source status.
 *
 *
 *
 *	This trigger rejects insertion in bJCCH  (JC Cost Header) IF the
 *	following error condition exists:
 *
 *		Invalid Job/Phase
 *      Invalid CostType
 *		Invalid UM
 *
 *
  *----------------------------------------------------------------*/
declare @errmsg varchar(255), @numrows int, @validcnt int, @rcode int,
        @JCCo bCompany, @Job bJob, @Phase bPhase, @CostType bJCCType, @PhaseGroup tinyint,
        @Contract bContract, @Mth smalldatetime, @UM bUM, @EstHours bHrs, @EstUnits bUnits,
        @EstCost bDollar, @CostTrans bTrans, @SourceStatus char(1), @override char(1), 
   		@source bSource, @PostedDate bDate, @autoadditemyn bYN, @item bContractItem

select @numrows = @@rowcount
IF @numrows = 0 return
set nocount on

select @source='JC OrigEst', @PostedDate=convert(varchar(8),getdate(),1)

---- validate JCJM
SELECT @validcnt=count(*) from bJCJM j with (nolock)
JOIN inserted i ON i.JCCo=j.JCCo AND i.Job=j.Job
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Job'
	GOTO error
	END

---- validate not posting soft-closed job with JCCO flag
select @validcnt = count(*) from bJCJM j with (nolock)
join inserted i on i.JCCo=j.JCCo and i.Job=j.Job
join bJCCO c with (nolock) on c.JCCo=i.JCCo
where i.JCCo=j.JCCo and i.Job=j.Job and i.JCCo=c.JCCo and c.PostSoftClosedJobs='N' and j.JobStatus = 2
if @validcnt <> 0 
	begin
	select @errmsg = 'Cannot Post to a Soft-Closed Job'
	goto error
	end

---- validate not posting a hard-closed job with JCCO flag
SELECT @validcnt=count(*) from bJCJM j with (nolock)
join inserted i on i.JCCo=j.JCCo and i.Job=j.Job
join bJCCO c with (nolock) on c.JCCo=i.JCCo
where i.JCCo=j.JCCo AND i.Job=j.Job and i.JCCo=c.JCCo and c.PostClosedJobs='N' AND j.JobStatus = 3
IF @validcnt <> 0
	BEGIN
	SELECT @errmsg = 'Cannot Post to a Hard-Closed Job'
	GOTO error
	END

---- validate HQUM
SELECT @validcnt=count(*) from bHQUM h with (nolock) JOIN inserted i ON i.UM=h.UM
IF @validcnt<>@numrows
	BEGIN
	SELECT @errmsg = 'Invalid UM'
	GOTO error
	END

---- validate JCCT
SELECT @validcnt=count(*) from bJCCT j with (nolock) 
JOIN inserted i ON i.PhaseGroup=j.PhaseGroup and i.CostType=j.CostType
IF @validcnt<>@numrows
	BEGIN
	SELECT @errmsg = 'Invalid CostType'
	GOTO error
	END



---- create cursor if needed and add the phase is needed, then add the cost transaction record
if @numrows = 1
	begin
   	select @JCCo = JCCo, @Job = Job, @PhaseGroup = PhaseGroup, @Phase = Phase, @CostType = CostType,
   		   @UM = UM, @EstHours = isnull(OrigHours,0), @EstUnits = isnull(OrigUnits,0), 
   		   @EstCost = isnull(OrigCost,0), @SourceStatus = SourceStatus
	from inserted
	end
else
	begin
   	---- use a cursor to process each inserted row
   	declare bJCCH_insert cursor LOCAL FAST_FORWARD
   	for select JCCo, Job, PhaseGroup, Phase, CostType, UM, isnull(OrigHours,0), isnull(OrigUnits,0),
   		isnull(OrigCost,0), SourceStatus 
   	from inserted

	open bJCCH_insert

	fetch next from bJCCH_insert into @JCCo,@Job,@PhaseGroup,@Phase,@CostType,@UM,@EstHours,@EstUnits,@EstCost,@SourceStatus
	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end


insert_check:
---- set override flag based on Source Status flag
if @SourceStatus in ('Y','N')
	begin
   	select @override = 'Y'
	end
else
	begin
   	select @override = 'N'
	end

---- check AND add the phase if needed. When override = 'Y'
---- if the override = 'Y' and the phase header exists then skip.
----if exists(select top 1 1 from bJCJP with (nolock) where JCCo=@JCCo and Job=@Job and Phase=@Phase)
----	begin
----	if @override <> 'Y'
----		begin
----		exec @rcode=bspJCADDPHASE @JCCo, @Job, @PhaseGroup, @Phase, @override, NULL, @errmsg output
----		if @rcode <> 0
----   			BEGIN
----   			SELECT  @errmsg = @errmsg + ' - Could not add phase ' + isnull(@Phase,'')
----   			GOTO error
----   			END
----		end
----	end
----else
	begin
	exec @rcode=bspJCADDPHASE @JCCo, @Job, @PhaseGroup, @Phase, @override, NULL, @errmsg output
	if @rcode <> 0
   		BEGIN
   		SELECT  @errmsg = @errmsg + ' - Could not add phase ' + isnull(@Phase,'')
   		GOTO error
   		END
	end


---- get AutoAddItemYN flag from bJCJM
select @autoadditemyn=AutoAddItemYN, @Contract=Contract
from bJCJM with (nolock) where JCCo=@JCCo and Job=@Job
if @@rowcount = 0 select @autoadditemyn='N'

---- get Item from bJCJP
select @item=Item from bJCJP with (nolock) where JCCo=@JCCo and Job=@Job and Phase=@Phase
if @@rowcount = 0 select @item = null

---- if @autoadditemyn flag is 'Y' and the cost type was inserted from
---- PM and contract item is assigned then update OrigContractAmt in bJCCI
---- source status no longer applies #133735
if @autoadditemyn = 'Y' and @item is not null ----and @SourceStatus in ('Y','N') 
   	begin
   	Update bJCCI set OrigContractAmt = OrigContractAmt + @EstCost
   	where JCCo=@JCCo and Contract=@Contract and Item=@item
   	end


---- /************************
---- * insert bJCCD records OE
---- ************************/
---- Check whether the record is from JC or PM.
---- If SourceStatus is Y or N, the record is from PM and has not
---- been interfaced, so we do not want to update/add a record to JCCD,
---- if SourceStatus is J, then it is from JC so it is ok.
IF @SourceStatus in ('Y','N') goto Next_Record

IF @SourceStatus = 'I' select @source='PM Intface'

---- we no longer update, always insert a new record to keep track of OE changes
---- add the cost trans record
select @Contract=bJCCM.Contract
from bJCJM with (nolock)
JOIN bJCCM with (nolock) on bJCJM.JCCo=bJCCM.JCCo AND bJCJM.Contract=bJCCM.Contract
where bJCJM.JCCo=@JCCo AND bJCJM.Job=@Job
if @Contract is null
	BEGIN
	SELECT  @errmsg = 'Missing contract for job: ' + isnull(@Job,'')
	GOTO error
	END

---- get contract item start month
select @Mth=i.StartMonth
from bJCCI i with (nolock)
join bJCJM j with (nolock) on j.JCCo=i.JCCo and i.Contract=j.Contract
where i.JCCo=@JCCo and j.JCCo=@JCCo and j.Job=@Job and i.Item=@item
if @Mth is null
	BEGIN
	SELECT  @errmsg = 'Contract Item Start Month must be supplied for the Contract Item: ' + isnull(@item,'')
	GOTO error
	END


exec @CostTrans = dbo.bspHQTCNextTrans 'bJCCD', @JCCo, @Mth, @errmsg output
-- see IF next transaction number was good or not
if @CostTrans=0 GOTO error  -- error message comes FROM bspHQTCNextTrans

insert into bJCCD (JCCo, Mth,CostTrans,Job,PhaseGroup,Phase,CostType,PostedDate,ActualDate,
		JCTransType,Source,Description,PostedUM,UM,EstHours,EstUnits,EstCost)
select @JCCo, @Mth,@CostTrans,@Job,@PhaseGroup,@Phase,@CostType,@PostedDate,@Mth,
		'OE',@source,'Original Estimate',@UM,@UM,@EstHours,@EstUnits,@EstCost



Next_Record:

if @numrows > 1
   	begin
       fetch next from bJCCH_insert into @JCCo, @Job, @PhaseGroup, @Phase, @CostType, @UM, @EstHours, @EstUnits, 
   			@EstCost, @SourceStatus
   
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bJCCH_insert
   		deallocate bJCCH_insert
   		end
   	end



---- Audit inserts
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' CostType: ' + convert(varchar(3),i.CostType),
		i.JCCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
from inserted i join bJCCO c on i.JCCo=c.JCCo
where c.AuditCostTypes = 'Y'


return



error:
   	SELECT @errmsg = @errmsg + ' - cannot insert Cost Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/****** Object:  Trigger dbo.btJCCHu    Script Date: 8/28/99 9:38:23 AM ******/
CREATE   TRIGGER [dbo].[btJCCHu] ON [dbo].[bJCCH] FOR UPDATE as
/*-----------------------------------------------------------------
 *	This trigger rejects insertion in bJCCH  (JC Cost Header) IF the
 *	following error condition exists:
 *
 *  Invalid Job/Phase
 *  Invalid CostType
 *  Invalid UM
 *
 *  Created By:  JRE 04/10/97
 *  Modified By: JRE 07/10/97
 *               LM sometime in 98 - added checking for PM Interface don't want to update jccd until it gets interfaced.
 *               JRE 02/24/01 - always add old and new records for 'OE' in JCCD.
 *               GF 03/23/2001 - fixed for phase entered in JC and changed in PM.
 *               MV 05/09/01 - allow UM update if no units in detail.
 *               TV 08/28/01 - Allow UM update even if there is detail issue# 13632
 *               GF 09/17/01 - Issue #14533, fix to set @oldsourcestatus = 'J' if null
 *               TV 09/27/01 - Moved the UM change to a stored Procedurer
 *               GF 11/01/2001 - Changes to insert JCCD if original values change. Now checks JCCP also.
 *               GF 12/06/2001 - Need to compare oldum to new um when updating estimate units for original estimates.
 *				 GF 04/16/2002 - Need to sum units for new um, possible putting um back to a previously used UM.
 *				 GF 05/31/2002 - Multiple fixes for UM change. See issue #17480		 
 *				 GF 08/08/2002 - issue #17355 - auto add contract item enhancement
 *				 GF 05/20/2003 - issue #21303 - not summing JCCP correctly when checking for UM change
 *				 GF 07/27/2004 - issue #25207 - need to check for open JCCB, JCPP, and PR Crew timesheets 
 *								when UM changed. Also added auditing when UM changes.
 *				 GF 11/04/2004 - issue #25823 - changed error messages to include phase and cost type
 *				 DANF 01/04/2006 - Issue #30079 - Add Phase and Cost Type info to Audit
 *				GF 01/24/2006 - issue #119977 - update JCCD when zero estimate values from PM Interface,
 *								otherwise possible a cost type enter in PM without original estimates will not create a JCCD/JCCP record.
 *				GF 11/14/2006 - ISSUE #123055 when update JCCP, sum old original estimates without using month in where clause.
 *				GF 04/20/2007 - issue #124414 - added HQMA auditing
 *				GF 05/29/2009 - issue #133735 changed auto-add item option to allow for other JCCH source status.
 *
 *
 *
 *----------------------------------------------------------------*/
declare @errmsg varchar(255), @numrows int, @validcnt int, @rcode int,
   		@JCCo bCompany, @Job bJob, @Phase bPhase, @CostType bJCCType, @PhaseGroup tinyint,
   		@Contract bContract, @Mth smalldatetime, @UM bUM, @EstHours bHrs, @EstUnits bUnits,
   		@EstCost bDollar, @CostTrans bTrans, @SourceStatus char(1), @oldsourcestatus char(1),
   		@Source bSource, @JCTransType varchar(2), @PostedDate varchar(8), @oldum bUM,
   		@oldEstHours bHrs, @oldEstUnits bUnits, @oldEstCost bDollar, @autoadditemyn bYN,
   		@item bContractItem, @oldjcchcost bDollar, @sheetnum smallint, @key varchar(50)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @PostedDate=convert(varchar(8),getdate(),1), @Source = 'JC OrigEst', @JCTransType = 'OE'

---- validate KEY Changes
select @validcnt=count(*) from inserted i
join deleted d on i.JCCo=d.JCCo and i.Job=d.Job and i.PhaseGroup=d.PhaseGroup
and i.Phase=d.Phase and i.CostType=d.CostType
if @validcnt<>@numrows
	begin
	select @errmsg = 'The following fields may not be changed: JCCo, Job, Phase, Costtype'
	goto error
	end

---- validate HQUM
select @validcnt=count(*) from bHQUM h JOIN inserted i ON i.UM=h.UM
IF @validcnt<>@numrows
	begin
	select @errmsg = 'Invalid UM'
	goto error
	end


---- spin through each inserted record AND add the phase if possible and then add the
---- cost transaction record.
IF UPDATE(UM) or UPDATE(OrigHours) or UPDATE(OrigCost) or UPDATE(OrigUnits) or UPDATE(SourceStatus) or UPDATE(InterfaceDate)
	BEGIN
        -- @JCCo
    select @JCCo=min(JCCo) from inserted
        while @JCCo is not null
        begin
        -- @Job
        select @Job=min(Job) from inserted where JCCo=@JCCo
        while @Job is not null
        begin
        -- @PhaseGroup
        select @PhaseGroup=min(PhaseGroup) from inserted where JCCo=@JCCo and Job=@Job
        while @PhaseGroup is not null
        begin
        -- @Phase
        select @Phase=min(Phase) from inserted
        where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup
        while @Phase is not null
        begin
        -- @CostType
        select @CostType=min(CostType) from inserted
        where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
        while @CostType is not null
        begin
    
   		-- -- -- read inserted JCCH data
   		select @UM=UM, @EstHours=IsNull(OrigHours,0), @EstUnits=IsNull(OrigUnits,0),
   				@EstCost=IsNull(OrigCost,0), @SourceStatus=SourceStatus
   		from inserted where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
    
   		-- -- -- get deleted JCCH data
   		select @oldum=UM, @oldsourcestatus=isnull(SourceStatus,'J'), @oldjcchcost=isnull(OrigCost,0)
   		from deleted where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType

		-- get Item from bJCJP
		select @item=Item from bJCJP where JCCo=@JCCo and Job=@Job and Phase=@Phase
		if @@rowcount = 0 select @item = null

   		set @key = 'Phase: ' + isnull(@Phase,'') + ' CostType: ' + convert(varchar(3), isnull(@CostType,0))
    		-- -- -- if changing UM only allow if no Change order detail or CmtdCost in JCCP
   		-- -- -- issue #25207 check open JCPP batches, JCCB batches, and PRRH status open for existance
   		-- -- -- of job, phase, cost type with unit changes. Do not allow if found.
    		if @UM <> @oldum
    			begin
    			-- -- -- only restrict UM change where status in 'J' or 'I'
    			if @SourceStatus in ('J','I')
    				begin
    				-- -- -- do not allow changes to UM if Change Order detail exists in JCOD
    				select @validcnt=count(*) from bJCOD with (nolock)
    				where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
    				if @validcnt <> 0
    					begin
    					select @errmsg = 'Cannot change UM for ' + isnull(@key,'') + ', change order detail exists in JCOD!'
    					goto error
    					end
    	
    				-- -- -- do not allow changes to UM if change order detail exists in PMOL
    				select @validcnt=count(*) from bPMOL with (nolock)
    				where PMCo=@JCCo and Project=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType and SendYN='Y'
    				if @validcnt <> 0
    					begin
    					select @errmsg = 'Cannot change UM for ' + isnull(@key,'') + ', change order detail exists in PMOL!'
    					goto error
    					end
   
   				-- -- -- check for open JCCB (cost adjustments) batches: Source = 'JC CostAdj' and JCTransType = 'JC' and Units <> 0
   				select @validcnt = count(*) 
   				from bJCCB a with (nolock)
   				join bHQBC b with (nolock) on b.Co=a.Co and b.Mth=a.Mth and b.BatchId=a.BatchId
   				where a.Co=@JCCo and a.Job=@Job and a.PhaseGroup=@PhaseGroup and a.Phase=@Phase 
   				and a.CostType=@CostType and a.Source = 'JC CostAdj' and a.JCTransType = 'JC' and a.Units <> 0 and b.Status < 4
   				if @validcnt <> 0
   					begin
   					select @errmsg = 'Cannot change UM for ' + isnull(@key,'') + ', an open JC Cost Adjustment batch exists for the phase and cost type.'
   					goto error
   					end
   
   				-- -- -- check for open JCPP (progress) batches for job, phase, cost type
   				select @validcnt = count(*) 
   				from bJCPP a with (nolock)
   				join bHQBC b with (nolock) on b.Co=a.Co and b.Mth=a.Mth and b.BatchId=a.BatchId
   				where a.Co=@JCCo and a.Job=@Job and a.PhaseGroup=@PhaseGroup and a.Phase=@Phase 
   				and a.CostType=@CostType and b.Status < 4
   				if @validcnt <> 0
   					begin
   					select @errmsg = 'Cannot change UM for ' + isnull(@key,'') + ', an open JC Progress batch exists for the phase and cost type.'
   					goto error
   					end
   
   				-- -- -- check for PR Crew Timesheets where status is 0,1,2 and progress has been assigned
   				-- -- -- there are eight phase/cost type columns that need to be checked
   				if exists(select SheetNum from bPRRH with (nolock)
   						where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Status < 3
   						and Phase1=@Phase and Phase1CostType=@CostType and isnull(Phase1Units,0) <> 0
   						union
   						select SheetNum from bPRRH with (nolock)
   						where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Status < 3
   						and Phase2=@Phase and Phase2CostType=@CostType and isnull(Phase2Units,0) <> 0
   						union
   						select SheetNum from bPRRH with (nolock)
   						where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Status < 3
   						and Phase3=@Phase and Phase3CostType=@CostType and isnull(Phase3Units,0) <> 0
   						union
   						select SheetNum from bPRRH with (nolock)
   						where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Status < 3
   						and Phase4=@Phase and Phase4CostType=@CostType and isnull(Phase4Units,0) <> 0
   						union
   						select SheetNum from bPRRH with (nolock)
   						where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Status < 3
   						and Phase5=@Phase and Phase5CostType=@CostType and isnull(Phase5Units,0) <> 0
   						union
   						select SheetNum from bPRRH with (nolock)
   						where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Status < 3
   						and Phase6=@Phase and Phase6CostType=@CostType and isnull(Phase6Units,0) <> 0
   						union
   						select SheetNum from bPRRH with (nolock)
   						where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Status < 3
   						and Phase7=@Phase and Phase7CostType=@CostType and isnull(Phase7Units,0) <> 0
   						union
   						select SheetNum from bPRRH with (nolock)
   						where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Status < 3
   						and Phase8=@Phase and Phase8CostType=@CostType and isnull(Phase8Units,0) <> 0)
   						begin
   						select @errmsg = 'Cannot change UM for ' + isnull(@key,'') + ', a PR Crew Timesheet exists for the phase and cost type with progress assigned.'
   						goto error
   						end
    				end
   
    			-- do not allow changes if TotalCmtdCost <> 0 or RemainCmtdCost <> 0 for any month in JCCP
    			if exists(select 1 from bJCCP where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup 
    						and Phase=@Phase and CostType=@CostType and (TotalCmtdCost <> 0 or RemainCmtdCost <> 0))
    			--having sum(TotalCmtdCost) <> 0 or sum(RemainCmtdCost) <> 0
    			--if @validcnt <> 0
    				begin
    				select @errmsg = 'Cannot change UM for ' + isnull(@key,'') + ', committed dollars exist in JCCP!'
    				goto error
    				end
    			end
    
    		-- get sum of Original Estimate Units from JCCD for um
    		select @oldEstUnits=sum(EstUnits)
            from bJCCD where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
    		and CostType=@CostType and JCTransType='OE' and UM=@UM
    
            -- get sum of Original Estimate hours and cost from JCCD
            select @oldEstHours=sum(EstHours), @oldEstCost=sum(EstCost)
            from bJCCD where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
    		and CostType=@CostType and JCTransType='OE'
    
            select @EstHours=isnull(@EstHours,0), @EstUnits=isnull(@EstUnits,0),
    			   @EstCost=isnull(@EstCost,0), @oldEstHours=isnull(@oldEstHours,0),
    			   @oldEstUnits=isnull(@oldEstUnits,0), @oldEstCost=isnull(@oldEstCost,0)
    
    		if @EstCost <> @oldjcchcost
    			begin
    			-- get AutoAddItemYN flag from bJCJM
    			select @autoadditemyn=AutoAddItemYN, @Contract=Contract
    			from bJCJM where JCCo=@JCCo and Job=@Job
    			if @@rowcount = 0 select @autoadditemyn='N'
    	
    			-- if @autoadditemyn flag is 'Y' and the cost type was inserted from
    			-- PM and contract item is assigned then update OrigContractAmt in bJCCI
    			-- source status no longer applies #133735
    			if @autoadditemyn = 'Y' and @item is not null ----and @SourceStatus in ('Y','N')
    				begin
    				Update bJCCI set OrigContractAmt = OrigContractAmt + @EstCost - @oldjcchcost
    				where JCCo=@JCCo and Contract=@Contract and Item=@item
    				end
    			end
    
    
        	/************************
        	* UPDATE bJCCD records
        	* note: this is an UPDATE instead of an insert because we do not wish
        	* to keep history of changes to original estimates
        	************************/
        	-- Check whether the record is from JC or PM.  If SourceStatus is Y or N, the record is from PM and has not
        	-- been interfaced, so we do not want to update/add a record to JCCD, if SourceStatus is I or J
        	-- then we want to update JCCD
    
            -- if source status is 'N' and old source is not from JC (J) then goto next record
            if @SourceStatus = 'N' and @oldsourcestatus <> 'J' goto NEXTRECORD
    
            -- if source status is 'Y' and old source is not from JC (J) then goto next record
            if @SourceStatus = 'Y' and @oldsourcestatus <> 'J' goto NEXTRECORD
    
            -- set source status
        	if @SourceStatus = 'I' and @oldsourcestatus <> 'I'
                select @Source='PM Intface'
            else
                select @Source='JC OrigEst'
    
        	-- get the contract start month
			select @Contract=bJCCM.Contract
			from bJCJM with (nolock)
			JOIN bJCCM with (nolock) on bJCJM.JCCo=bJCCM.JCCo AND bJCJM.Contract=bJCCM.Contract
			where bJCJM.JCCo=@JCCo AND bJCJM.Job=@Job
			if @Contract is null
				BEGIN
				SELECT  @errmsg = 'Missing contract for job: ' + isnull(@Job,'')
				GOTO error
				END

			---- get contract item start month
			select @Mth=i.StartMonth
			from bJCCI i with (nolock)
			join bJCJM j with (nolock) on j.JCCo=i.JCCo and i.Contract=j.Contract
			where i.JCCo=@JCCo and j.JCCo=@JCCo and j.Job=@Job and i.Item=@item
			if @Mth is null
				BEGIN
				SELECT  @errmsg = 'Contract Item Start Month must be supplied for the Contract Item: ' + isnull(@item,'')
				GOTO error
				END
    
		---- issue #119972
		---- check for difference between Old and New - only insert new JCCD record if difference
		if @EstCost<>@oldEstCost or @EstHours<>@oldEstHours or @EstUnits<>@oldEstUnits or @oldum<>@UM or @SourceStatus = 'I'
			begin
    
    			-- if changing UM only allow if no Change order detail or CmtdCost in JCCP
    			if @UM <> @oldum
    				begin
    				-- update original estimate records, set EstUnits = 0 where UM <> New UM
    				update bJCCD set EstUnits = 0
    	        	from bJCCD where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
    				and CostType=@CostType and JCTransType='OE' and UM<>@UM
    	
    				-- update projection records, set ProjUnits = 0 and ForecastUnits = 0 where UM <> New UM
    				update bJCCD set ProjUnits = 0, ForecastUnits = 0
    	        	from bJCCD where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
    				and CostType=@CostType and JCTransType='PF' and UM<>@UM
    	
    				-- update posted units and posted UM set to actual units and um where posted UM is empty
    				update bJCCD set PostedUnits=ActualUnits, PostedUM=UM
    	        	from bJCCD where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
    				and CostType=@CostType and isnull(PostedUM,'') = '' and JCTransType not in ('PF','OE')
    	
    				-- update Actual units = 0, UM = new um for all transaction except 'OE' and 'PF'
    				update bJCCD set ActualUnits=0, UM=@UM
    	        	from bJCCD where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
    				and CostType=@CostType and UM<>@UM and JCTransType not in ('PF','OE')
    	
    				-- update actual units = posted units where posted um = new um
    				update bJCCD set ActualUnits=PostedUnits
    				from bJCCD where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
    				and CostType=@CostType and PostedUM=@UM and JCTransType not in ('PF','OE')

    				end
    
                -- add the cost trans record
                exec @CostTrans = bspHQTCNextTrans 'bJCCD', @JCCo, @Mth, @errmsg output
                -- see if next transaction number was good or not
                if @CostTrans=0 goto error
    
                -- insert JCCD record
                insert into bJCCD (JCCo, Mth,CostTrans,Job,PhaseGroup,Phase,CostType,PostedDate,
                        ActualDate,JCTransType,Source,Description,PostedUM,UM,EstHours,EstUnits,EstCost)
                select @JCCo,@Mth,@CostTrans,@Job,@PhaseGroup,@Phase,@CostType,@PostedDate,@Mth,
                        @JCTransType,@Source,'Original Estimate', @UM, @UM, @EstHours-@oldEstHours,
                        @EstUnits-@oldEstUnits, @EstCost-@oldEstCost
                if @@rowcount = 0
    				begin
    				select @errmsg = 'Error inserting JCCD transaction record'
    				goto error
    				end
    
                -- get old original estimates from bJCCP
                select @oldEstHours=0, @oldEstUnits=0, @oldEstCost=0
                select @oldEstHours = sum(OrigEstHours), 
					   @oldEstUnits = sum(OrigEstUnits),
					   @oldEstCost = sum(OrigEstCost)
                from bJCCP where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
                and CostType=@CostType ----and Mth=@Mth
                if @@rowcount = 0
                    begin
                    select @errmsg='Unable to update JCCP for ' + isnull(@key,'') + '!'
                    goto error
                    end
    
                if @oldEstHours<>@EstHours or @oldEstUnits<>@EstUnits or @oldEstCost<>@EstCost
                    begin
                    -- update JCCP set original's to equal JCCH
                    Update bJCCP set OrigEstHours=OrigEstHours - @oldEstHours + @EstHours,
                                     OrigEstUnits=OrigEstUnits - @oldEstUnits + @EstUnits,
                                     OrigEstCost=OrigEstCost - @oldEstCost + @EstCost,
                                     CurrEstHours=CurrEstHours - @oldEstHours + @EstHours,
                                     CurrEstUnits=CurrEstUnits - @oldEstUnits + @EstUnits,
                                     CurrEstCost=CurrEstCost - @oldEstCost + @EstCost
                    where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase
                    and CostType=@CostType and Mth=@Mth
                    if @@Error <> 0 goto error
                    end
                end


	NEXTRECORD:
	---- CostType
        select @CostType=min(CostType) from inserted
        where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType>@CostType
        if @@rowcount=0 select @CostType=null
        end
        -- @Phase
        select @Phase=min(Phase) from inserted
        where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase>@Phase
        if @@rowcount=0 select @Phase=null
        end
        -- @PhaseGroup
        select @PhaseGroup=min(PhaseGroup) from inserted
        where JCCo=@JCCo and Job=@Job and PhaseGroup>@PhaseGroup
        if @@rowcount=0 select @PhaseGroup=null
        end
        -- @Job
        select @Job=min(Job) from inserted where JCCo=@JCCo and Job>@Job
        if @@rowcount=0 select @Job=null
        end
        -- @JCCo
        select @JCCo=min(JCCo) from inserted where JCCo>@JCCo
        if @@rowcount=0 select @JCCo=null
        end
	END





---- audit UM changes
if update(UM)
   	begin
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where isnull(d.UM,'') <> isnull(i.UM,'') ---- always audit UM changes reguardless of audit flag
   	end
if update(BillFlag)
   	begin
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'BillFlag', d.BillFlag, i.BillFlag, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.BillFlag,'') <> isnull(i.BillFlag,'')
   	end
if update(ItemUnitFlag)
   	begin
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'ItemUnitFlag', d.ItemUnitFlag, i.ItemUnitFlag, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.ItemUnitFlag,'') <> isnull(i.ItemUnitFlag,'')
   	end
if update(PhaseUnitFlag)
   	begin
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'PhaseUnitFlag', d.PhaseUnitFlag, i.PhaseUnitFlag, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.PhaseUnitFlag,'') <> isnull(i.PhaseUnitFlag,'')
   	end
if update(BuyOutYN)
   	begin
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'BuyOutYN', d.BuyOutYN, i.BuyOutYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.BuyOutYN,'') <> isnull(i.BuyOutYN,'')
   	end
if update(ActiveYN)
   	begin
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'ActiveYN', d.ActiveYN, i.ActiveYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.ActiveYN,'') <> isnull(i.ActiveYN,'')
   	end
if update(Plugged)
   	begin
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'Plugged', d.Plugged, i.Plugged, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.Plugged,'') <> isnull(i.Plugged,'')
   	end
if update(SourceStatus)
   	begin
   	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'SourceStatus', d.SourceStatus, i.SourceStatus, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.SourceStatus,'') <> isnull(i.SourceStatus,'')
   	end
if update(LastProjDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'LastProjDate',  convert(varchar(30),d.LastProjDate), convert(varchar(30),i.LastProjDate), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.LastProjDate,'') <> isnull(i.LastProjDate,'')
	end
if update(InterfaceDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'InterfaceDate',  convert(varchar(30),d.InterfaceDate), convert(varchar(30),i.InterfaceDate), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.InterfaceDate,'') <> isnull(i.InterfaceDate,'')
	end
if update(OrigHours)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'OrigHours',  convert(varchar(20),d.OrigHours), convert(varchar(20),i.OrigHours), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.OrigHours,'') <> isnull(i.OrigHours,'')
	end
if update(OrigUnits)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'OrigUnits',  convert(varchar(20),d.OrigUnits), convert(varchar(20),i.OrigUnits), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.OrigUnits,'') <> isnull(i.OrigUnits,'')
	end
if update(OrigCost)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCCH','JCCo: ' + convert(varchar(3), i.JCCo) + ' Job: ' + i.Job + ' Phase: ' + i.Phase + ' Cost Type: ' + convert(varchar(3),i.CostType),
			i.JCCo, 'C', 'OrigCost',  convert(varchar(20),d.OrigCost), convert(varchar(20),i.OrigCost), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Phase=i.Phase and d.CostType=i.CostType
	join bJCCO c on i.JCCo=c.JCCo
	where c.AuditCostTypes = 'Y' and isnull(d.OrigCost,'') <> isnull(i.OrigCost,'')
	end



return



error:
	SELECT @errmsg = @errmsg + ' - cannot update JCCH!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 8/29/13
-- Description:	Updates udDateCreated field with current date
-- =============================================
CREATE TRIGGER [dbo].[mcktrCTInsert] 
   ON  [dbo].[bJCCH] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for trigger here
	UPDATE t
		SET t.udDateCreated = CURRENT_TIMESTAMP
		FROM dbo.bJCCH AS t
		INNER JOIN inserted AS i
		ON t.KeyID = i.KeyID;
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:        Eric Shafer
-- Create date: 8/29/13
-- Description:   Trigger to update the udDateChanged value with the current date.
-- =============================================
CREATE TRIGGER [dbo].[mcktrCTUpdate]
   ON  [dbo].[bJCCH] 
   AFTER UPDATE
AS 
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;

    -- Insert statements for trigger here
IF ( (SELECT trigger_nestlevel() ) < 2 ) AND (NOT UPDATE(udDateChanged)) AND (NOT UPDATE (udDateCreated))
BEGIN
                        UPDATE t
                              SET t.udDateChanged = CURRENT_TIMESTAMP
                              FROM dbo.bJCCH AS t
                              INNER JOIN inserted AS i
                              ON t.KeyID = i.KeyID;
END
END

GO
ALTER TABLE [dbo].[bJCCH] WITH NOCHECK ADD CONSTRAINT [CK_bJCCH_ActiveYN] CHECK (([ActiveYN]='Y' OR [ActiveYN]='N'))
GO
ALTER TABLE [dbo].[bJCCH] WITH NOCHECK ADD CONSTRAINT [CK_bJCCH_BuyOutYN] CHECK (([BuyOutYN]='Y' OR [BuyOutYN]='N'))
GO
ALTER TABLE [dbo].[bJCCH] WITH NOCHECK ADD CONSTRAINT [CK_bJCCH_ItemUnitFlag] CHECK (([ItemUnitFlag]='Y' OR [ItemUnitFlag]='N'))
GO
ALTER TABLE [dbo].[bJCCH] WITH NOCHECK ADD CONSTRAINT [CK_bJCCH_PhaseUnitFlag] CHECK (([PhaseUnitFlag]='Y' OR [PhaseUnitFlag]='N'))
GO
ALTER TABLE [dbo].[bJCCH] WITH NOCHECK ADD CONSTRAINT [CK_bJCCH_Plugged] CHECK (([Plugged]='Y' OR [Plugged]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJCCH] ON [dbo].[bJCCH] ([JCCo], [Job], [PhaseGroup], [Phase], [CostType]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCCH] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_dta_index_bJCCH_52_2023678257__K3_K1_K2_K4_K5_K6] ON [dbo].[bJCCH] ([PhaseGroup], [JCCo], [Job], [Phase], [CostType], [UM]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE STATISTICS [_dta_stat_2023678257_5_1_2_3] ON [dbo].[bJCCH] ([CostType], [JCCo], [Job], [PhaseGroup])
GO
CREATE STATISTICS [_dta_stat_2023678257_4_1_2] ON [dbo].[bJCCH] ([Phase], [JCCo], [Job])
GO
CREATE STATISTICS [_dta_stat_2023678257_6_1_2_3_4_5] ON [dbo].[bJCCH] ([UM], [JCCo], [Job], [PhaseGroup], [Phase], [CostType])
GO
