CREATE TABLE [dbo].[bEMBF]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NULL,
[EMTrans] [dbo].[bTrans] NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EMTransType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[ComponentTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[Asset] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCostType] [dbo].[bEMCType] NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLTransAcct] [dbo].[bGLAcct] NULL,
[GLOffsetAcct] [dbo].[bGLAcct] NULL,
[ReversalStatus] [tinyint] NULL,
[OrigMth] [dbo].[bMonth] NULL,
[OrigEMTrans] [dbo].[bTrans] NULL,
[PRCo] [dbo].[bCompany] NULL,
[PREmployee] [dbo].[bEmployee] NULL,
[APCo] [dbo].[bCompany] NULL,
[APTrans] [dbo].[bTrans] NULL,
[APLine] [dbo].[bItem] NULL,
[VendorGrp] [dbo].[bGroup] NULL,
[APVendor] [dbo].[bVendor] NULL,
[APRef] [dbo].[bAPReference] NULL,
[WorkOrder] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[INCo] [dbo].[bCompany] NULL,
[INLocation] [dbo].[bLoc] NULL,
[Material] [dbo].[bMatl] NULL,
[INStkUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bEMBF_INStkUnitCost] DEFAULT ((0)),
[INStkECM] [dbo].[bECM] NULL,
[INStkUM] [dbo].[bUM] NULL,
[SerialNo] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NULL,
[Dollars] [dbo].[bDollar] NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bEMBF_UnitPrice] DEFAULT ((0)),
[Hours] [dbo].[bHrs] NULL,
[PerECM] [dbo].[bECM] NULL,
[TotalCost] [dbo].[bDollar] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGrp] [dbo].[bGroup] NULL,
[JCPhase] [dbo].[bPhase] NULL,
[JCCostType] [dbo].[bJCCType] NULL,
[RevRate] [dbo].[bDollar] NULL CONSTRAINT [DF_bEMBF_RevRate] DEFAULT ((0)),
[RevWorkUnits] [dbo].[bUnits] NULL,
[RevTimeUnits] [dbo].[bUnits] NULL,
[RevDollars] [dbo].[bDollar] NULL,
[OffsetGLCo] [dbo].[bCompany] NULL,
[RevUsedOnEquipCo] [dbo].[bCompany] NULL,
[RevUsedOnEquipGroup] [dbo].[bGroup] NULL,
[RevUsedOnEquip] [dbo].[bEquip] NULL,
[MeterTrans] [dbo].[bTrans] NULL,
[MeterReadDate] [dbo].[bDate] NULL,
[ReplacedHourReading] [dbo].[bHrs] NULL,
[PreviousHourMeter] [dbo].[bHrs] NULL,
[CurrentHourMeter] [dbo].[bHrs] NULL,
[PreviousTotalHourMeter] [dbo].[bHrs] NULL,
[CurrentTotalHourMeter] [dbo].[bHrs] NULL,
[ReplacedOdoReading] [dbo].[bHrs] NULL,
[PreviousOdometer] [dbo].[bHrs] NULL,
[CurrentOdometer] [dbo].[bHrs] NULL,
[PreviousTotalOdometer] [dbo].[bHrs] NULL,
[CurrentTotalOdometer] [dbo].[bHrs] NULL,
[MeterMiles] [dbo].[bHrs] NULL,
[MeterHrs] [dbo].[bHrs] NULL,
[PartsStatusCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TaxType] [tinyint] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxBasis] [dbo].[bDollar] NULL,
[TaxRate] [dbo].[bRate] NULL,
[TaxAmount] [dbo].[bDollar] NULL,
[TimeUM] [dbo].[bUM] NULL,
[AllocCode] [tinyint] NULL,
[OldSource] [char] (10) COLLATE Latin1_General_BIN NULL,
[OldEquipment] [dbo].[bEquip] NULL,
[OldRevCode] [dbo].[bRevCode] NULL,
[OldEMTrans] [dbo].[bTrans] NULL,
[OldBatchTransType] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldEMTransType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldComponentTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldComponent] [dbo].[bEquip] NULL,
[OldAsset] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldEMGroup] [dbo].[bGroup] NULL,
[OldCostCode] [dbo].[bCostCode] NULL,
[OldEMCostType] [dbo].[bEMCType] NULL,
[OldActualDate] [dbo].[bDate] NULL,
[OldDescription] [dbo].[bItemDesc] NULL,
[OldGLCo] [dbo].[bCompany] NULL,
[OldGLTransAcct] [dbo].[bGLAcct] NULL,
[OldGLOffsetAcct] [dbo].[bGLAcct] NULL,
[OldReversalStatus] [tinyint] NULL,
[OldOrigMth] [dbo].[bMonth] NULL,
[OldOrigEMTrans] [dbo].[bTrans] NULL,
[OldPRCo] [dbo].[bCompany] NULL,
[OldPREmployee] [dbo].[bEmployee] NULL,
[OldAPCo] [dbo].[bCompany] NULL,
[OldAPTrans] [dbo].[bTrans] NULL,
[OldAPLine] [dbo].[bItem] NULL,
[OldVendorGrp] [dbo].[bGroup] NULL,
[OldAPVendor] [dbo].[bVendor] NULL,
[OldAPRef] [dbo].[bAPReference] NULL,
[OldWorkOrder] [dbo].[bWO] NULL,
[OldWOItem] [dbo].[bItem] NULL,
[OldMatlGroup] [dbo].[bGroup] NULL,
[OldINCo] [dbo].[bCompany] NULL,
[OldINLocation] [dbo].[bLoc] NULL,
[OldMaterial] [dbo].[bMatl] NULL,
[OldINStkUnitCost] [dbo].[bUnitCost] NULL,
[OldINStkECM] [dbo].[bECM] NULL,
[OldINStkUM] [dbo].[bUM] NULL,
[OldSerialNo] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldUM] [dbo].[bUM] NULL,
[OldUnits] [dbo].[bUnits] NULL,
[OldDollars] [dbo].[bDollar] NULL,
[OldUnitPrice] [dbo].[bUnitCost] NULL,
[OldHours] [dbo].[bHrs] NULL,
[OldPerECM] [dbo].[bECM] NULL,
[OldTotalCost] [dbo].[bDollar] NULL,
[OldRevTransType] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGrp] [dbo].[bGroup] NULL,
[OldJCPhase] [dbo].[bPhase] NULL,
[OldJCCostType] [dbo].[bJCCType] NULL,
[OldRevRate] [dbo].[bDollar] NULL,
[OldRevWorkUnits] [dbo].[bUnits] NULL,
[OldRevTimeUnits] [dbo].[bUnits] NULL,
[OldRevDollars] [dbo].[bDollar] NULL,
[OldOffsetGLCo] [dbo].[bCompany] NULL,
[OldRevUsedOnEquipCo] [dbo].[bCompany] NULL,
[OldRevUsedOnEquipGroup] [dbo].[bGroup] NULL,
[OldRevUsedOnEquip] [dbo].[bEquip] NULL,
[OldMeterTrans] [dbo].[bTrans] NULL,
[OldMeterReadDate] [dbo].[bDate] NULL,
[OldReplacedHourReading] [dbo].[bHrs] NULL,
[OldPreviousHourMeter] [dbo].[bHrs] NULL,
[OldCurrentHourMeter] [dbo].[bHrs] NULL,
[OldPreviousTotalHourMeter] [dbo].[bHrs] NULL,
[OldCurrentTotalHourMeter] [dbo].[bHrs] NULL,
[OldReplacedOdoReading] [dbo].[bHrs] NULL,
[OldPreviousOdometer] [dbo].[bHrs] NULL,
[OldCurrentOdometer] [dbo].[bHrs] NULL,
[OldPreviousTotalOdometer] [dbo].[bHrs] NULL,
[OldCurrentTotalOdometer] [dbo].[bHrs] NULL,
[OldMeterMiles] [dbo].[bHrs] NULL,
[OldMeterHrs] [dbo].[bHrs] NULL,
[OldPartsStatusCode] [dbo].[bTaxCode] NULL,
[OldTaxType] [tinyint] NULL,
[OldTaxCode] [dbo].[bTaxCode] NULL,
[OldTaxGroup] [dbo].[bGroup] NULL,
[OldTaxBasis] [dbo].[bDollar] NULL,
[OldTaxRate] [dbo].[bRate] NULL,
[OldTaxAmount] [dbo].[bDollar] NULL,
[OldTimeUM] [dbo].[bUM] NULL,
[OldAllocCode] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AutoUsage] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMBF_AutoUsage] DEFAULT ('N'),
[PRCrew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldPRCrew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[WOPartSeq] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/****** Object:  Trigger dbo.btEMBFd    Script Date: 8/28/99 9:37:14 AM ******/
CREATE            trigger [dbo].[btEMBFd] on [dbo].[bEMBF] for DELETE as
/*-----------------------------------------------------------------
*	CREATED BY: JM   5/6/99
*	MODIFIED By: JM 2/22/00 Deleted 'EMFuel' as Source.
*                JM 10/23/00 - Added EMMeter source update of bEMMR detail table;
*                also added EMTime source in list for update of bEMCD detail table.
*                TV 03/21/02 Delete HQAT attachment
*                TV 10/30/03 issue 22785 - Speed up delete statment for HQAT.
*                TV 11/21/03 23080 Additional clean up for speed (combined updates)
*                TV 12/16/03 23032 The rowcount was wrong
*				  TV 02/11/04 - 23061 added isnulls
*				TV 07/06/04  25026 - EM Batch Posting Speed problem
*				TV 07/09/04 - 25066 Clear Batch takes 1/2 hour to process.
*				TV 08/03/04 25305 Clear Batch takes 1/2 hour to process.
*				GP 05/26/09 - 133434 removed HQAT code, added new insert
*				JonathanP 06/18/09 - 133434 Fixed attachment code.
*				TRL 02/09/10 Issue 132064 Allow Retro Meter Readings
*				GF 01/22/2013 TK-20889 delete EMBC records when batch sequence is delete for EMRev
*				GF 03/11/2013 TFS-43067 removed code to delete EMBC, EMGL records
*				GF 03/14/2013 TFS-43533 issue #140392 return error message from stored proc
*
*
*	This trigger updates EM Transaction Detail table by bEMBF.Source
*	 to remove InUseBatchId when deletion(s) are made from bEMBF.
*
*	Rejects deletion if the following
*	error condition exists:
*
*/----------------------------------------------------------------
declare @errmsg varchar(255),@rowcount int, @nullcnt int,@source bSource,
/*132064*/
@co bCompany,@mth bMonth,@batchid bBatchID,@batchseq int, @embfsource varchar(10),	 @batchtranstype char(1), @emtrans bTrans, 
@equip bEquip,  @actualdate bDate,@currhourmeter bHrs, @currodometer bHrs,@errtext varchar(255),@rcode int 

set nocount on

--TV 12/16/03 23032 The rowcount was wrong
select @rowcount = count(*) from deleted
if @rowcount = 0 return

-- Get Source for deleted record. 
select @source = Source from deleted

select @rcode = 0

if @source = 'EMRev' --TV 08/03/04 25305 Clear Batch takes 1/2 hour to process.
begin
	update bEMRD
	set InUseBatchID = null
	from bEMRD r, deleted d
	where r.EMCo = d.Co and r.Mth = d.Mth and r.Trans = d.EMTrans

	update bEMRD
	set InUseBatchID = null
	from bEMRD r, deleted d
	where r.EMCo = d.Co and r.Mth = d.OrigMth and r.Trans = d.OrigEMTrans

END

-- TV 07/09/04 - 25066 Clear Batch takes 1/2 hour to process.
if @source = 'EMAlloc' or @source = 'EMAdj' or @source = 'EMDepr'
or @source = 'EMParts' or @source = 'EMTime' or @source = 'EMFuel' 
begin
	update bEMCD
	set InUseBatchID = null
	from bEMCD c, deleted d
	where c.EMCo = d.Co and c.Mth = d.Mth and c.EMTrans = d.EMTrans 

	update bEMCD
	set InUseBatchID = null
	from bEMCD c, deleted d
	where c.EMCo = d.Co and c.Mth = d.OrigMth and c.EMTrans = d.OrigEMTrans
end

--TV 08/03/04 25305 Clear Batch takes 1/2 hour to process.
if @source = 'EMMeter' 
begin
	/*132064 START*/
	--Get current Meter Readings
	select @co =Co,@mth =Mth,@batchid =BatchId,@batchseq=BatchSeq, @batchtranstype =BatchTransType, @emtrans=EMTrans, 
	@equip=Equipment,  @actualdate =MeterReadDate,@currhourmeter=CurrentHourMeter, @currodometer =CurrentOdometer
	from deleted 
	
	/*1. New Meter Readings Update existing Odometer/Hourmeter for Meter Reading Batch	
	Update on new Meter Readings, If Retro, update occurs in batch post process or (EMMR Trigger)*/
	/*2.  Update on the next "Change" Meter Readings, if next meter readings is in batch to be changed also
	If correction, update the following meter reading in EMMR which will occur in batch post process or (EMMR Trigger)*/
	/*3.  Update on the next Meter Readings in EMMR/EMBF,  
	EMBF if next meter reading is in current batch or next meter reading is being changed
	EMMR if next meter reading isn't in current batch as new or changed record, update will occur in batch post process or (EMMR Trigger)*/
	exec @rcode = dbo.vspEMBFUpdateNextBatchSeq @co, @mth, @batchid,@batchseq, @batchtranstype, @emtrans,
	'Y'/*DeleteTriggerYN*/,@equip, @actualdate, @currhourmeter, @currodometer,@errmsg output
	----TFS-43533
	IF @rcode <> 0 GOTO error  
  --  	if @rcode <> 0
  --  	begin
  --   	select @errmsg = @errtext, @rcode = 1
  --   	goto error
		--end 
	
	update bEMMR
	set InUseBatchID = null
	from bEMMR m, deleted d
	where m.EMCo = d.Co and m.Mth = d.Mth and m.EMTrans = d.EMTrans

	update bEMMR
	set InUseBatchID = null
	from bEMMR m, deleted d
	where m.EMCo = d.Co and m.Mth = d.OrigMth and m.EMTrans = d.OrigEMTrans
end 

-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
select AttachmentID, suser_name(), 'Y' 
from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
where h.UniqueAttchID not in(select t.UniqueAttchID from bEMRD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID) and
h.UniqueAttchID not in(select t.UniqueAttchID from bEMCD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID) and
h.UniqueAttchID not in(select t.UniqueAttchID from bEMMR t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID) and
d.UniqueAttchID is not null  	


return
error:
select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Detail Batch entry!'
RAISERROR(@errmsg, 11, -1);
rollback transaction








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
/****** Object:  Trigger dbo.btEMBFi    Script Date: 3/26/2002 9:47:33 AM ******/
CREATE                                trigger [dbo].[btEMBFi] on [dbo].[bEMBF] for INSERT as
/*-----------------------------------------------------------------
*	CREATED BY: JM   5/2/99
*	MODIFIED By:    JM 5/6/99 - Added section to run against bEMRD for Revenue sources.
*        JM 9/15/99 - Added section to run against bEMMR for Meter source.
*        bc 12/21/99 added the insert attachments section for Add type usage entries
*        JM 2/1/00 - added rejection when Source = 'EMFuel' and CostCode or EMCostType are null.
*        JM 2/22/00 - Changed read of TableName passed to bspHQBatchProcessVal
*        to include EMTransType for EMAdj source to segment Fuel transactions
*        and all others to EMBF.
*        bc 07/31/00 - added BatchTransType to the cursor
* 		JM 10-30-2002 Ref Issue 19145 -  Changed Source sent to bspHQBatchProcessVal 
*		to 'EMAdj' when inserting an EMAlloc or EMDepr transaction into an EMCostAdj batch.
*		JM 12-12-02 Ref Issue 19542 - Corrected insertion of record into EMBF for Attachment to include
*		Attachment's RevenueCode, JCCo and Job.
*        TV 1/24/02 19145 - Removed previous changes. Was acting as designed 
* 		TV 2/11/04  23746 - Changed the oder in the Fetch Next 
*		TV 02/11/04 - 23061 added isnulls
*		TV 05/04/04 - 24449 Comp type was 1 char not 10
*		TV 06/02/04 24550 -If revenue posted as $Amt and no units, the attachment gets $0.00 revenue
*		TV 09/20/04 25553 - JC Job/Job date/Date of last usage not being updated with imported EMBF data.
*		TV 11/16/04 24034 - Attachments needs to pass in PRCrew.
*		TV 2/17/05  27062 - Deadlock when two people posting usage
*		TV 03/03/05 changed from Scrolling to Local FF.
*		GF 01/25/2008 - issue #126860 remove reference to 'EMBZGrid'
*		DAN SO 02/27/2009 - ISSUE: #131478 allow new Cost Adj records to batches created by different processes
*		GP 12/24/2009 - Issue 137218 added @emtranstype to fetch next of 2nd cursor call (multiple rows)
*		TRL 02/09/10 Issue 132064 Allow Retro Meter Readings, updated trigger and inserted procedure call update next meter readings
*		GF 08/08/2012 TK-16871 add HQCC records for source and GL
*		GF 03/14/2013 TFS-43533 issue #140392 return error message from stored proc
*
*
*This trigger rejects insertion in bEMBF (EM Batch) if any of the
* following error conditions exist:
*
* 	Invalid Batch ID#
*		Batch associated with another source or table
*		Batch in use by someone else
*		Batch status not 'open'
*		EMRef to a EMCD trans that doesn't exist
*		EMCD trans already in use by a batch
*		EMCD trans created from a source other than EM Source = 'EMFuel' and CostCode or EMCostType are null
*
*	Updates InUseBatchId in bEMCD or bEMRD for existing transactions.
*	Updates InUseBatchId of reversal trans if adding reversal
*
* 	Adds entry to HQ Close Control as needed.
*----------------------------------------------------------------*/
declare @batchid bBatchID,@batchseq int,	@checktable varchar(30), @co bCompany, @comparesource varchar(10),
@detailsource varchar(10), @embfsource varchar(10),	@emtrans bTrans, @equip bEquip, @errmsg varchar(255),
@errtext varchar(60), @glco bCompany, @inusebatchid bBatchID, @inuseby bVPUserName,	@mth bMonth,
@numrows int, @origemtrans bTrans, @origmth bMonth,	@rcode tinyint,	@reversalstatus tinyint,
@status tinyint, @tablename char(20), @transsource bSource,

@attachment bEquip, @catgy bCat,
@attachrate bDollar, @rate bDollar, @amt bDollar, @basis char(1), @time_um bUM, @work_um bUM,
@hourmeter bHrs, @odometer bHrs, @posttoattach bYN, @TempEMBFSource varchar(10),

/* declarations for inserting usage attachments */
@seq int, @emgroup bGroup, @batchtranstype char(1), @transtype char(1), @revcode bRevCode,
@costcode bCostCode, @emct bEMCType, @actualdate bDate,
@offsetacct bGLAcct, @prco bCompany, @employee bEmployee, @workorder bWO,
@woitem bItem, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase,
@jcct bJCCType, @revworkunits bUnits, @revtimeunits bUnits, @revdollars bDollar,
@usedonequipco bCompany, @usedonequipgroup bGroup, @offsetglco bCompany,
@usedonequip bEquip, @comptype varchar(10), @component bEquip,
@prehourmeter bHrs, @currhourmeter bHrs, @preodometer bHrs, @currodometer bHrs,
@attachrevcode bRevCode, @emtranstype varchar(10), @prcrew varchar(10)
     
select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

if @numrows = 1
	begin  
 		select @co = Co, @mth = Mth, @batchid = BatchId, @batchseq = BatchSeq, @embfsource = Source,
		@batchtranstype = BatchTransType, @emtrans = EMTrans, @equip = Equipment, @glco=GLCo,
		@reversalstatus=ReversalStatus, @origmth = OrigMth, @origemtrans=OrigEMTrans,
		@emtranstype = EMTransType
		----TK-16871
		,@jcco = JCCo
 		from inserted
 	end 
else
    	begin
		/* use a cursor to process each inserted row */
      	declare bEMBF_insert cursor local fast_forward for select Co, Mth, BatchId, BatchSeq,-- TV 03/03/05 changed from Scrolling to Local FF.
      	Source, BatchTransType, EMTrans, Equipment, GLCo, ReversalStatus, OrigMth, OrigEMTrans, EMTransType
      	----TK-16871
      	,JCCo
      	from inserted
      	open bEMBF_insert
		--TV 2/11/04  23746 - Changed the oder in the Fetch Next
    	fetch next from bEMBF_insert into @co, @mth, @batchid, @batchseq, @embfsource, @batchtranstype,
				@emtrans, @equip, @glco, @reversalstatus, @origmth, @origemtrans, @emtranstype
				----TK-16871
				,@jcco
      	if @@fetch_status <> 0
      	begin
      		select @errmsg = 'Cursor error'
      		goto error
      	end --@@fetch_status
      end --else

insert_check:

/* Validate HQ Batch. Special validation because the EMAdj Source can have multiple TableNames in HQBC. */
select @checktable = TableName  from bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0 or @checktable <> 'EMBF' ----not in ('EMBF') -- error
begin
	select @errmsg = 'Invalid HQBC.TableName! ' + isnull(@checktable,''), @rcode = 1
	goto error
end
     
/* JM 10-30-2002 Ref Issue 19145 */
-- ISSUE: #131478 --
if @embfsource <> 'EMAlloc' and @embfsource <> 'EMDepr' AND @embfsource <> 'EMAdj'
	begin
   		exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, @embfsource, @checktable, @errtext output, @status output
     	if @rcode <> 0
      	begin
   	     	select @errmsg = @errtext, @rcode = 1
   	     	goto error
   	     end --@rcode
   	end --@embfsource
else
	begin 
		select @status = Status from bHQBC with (nolock)where Co = @co and Mth = @mth and BatchId = @batchid
		if @status <> 0
		begin
  			select @errmsg = 'Must be an open batch'
  			goto error
  		end
  	end 
     
/* validate existing EM trans */
if @emtrans is not null
begin
	if @embfsource = 'EMRev' /* Revenue source uses bEMRD */
	begin
		select @detailsource = Source, @inusebatchid = InUseBatchID 
		from bEMRD with (nolock)
 		where EMCo = @co and Mth = @mth and Trans = @emtrans

 		select @numrows = @@rowcount
 	end --@embfsource

	if @embfsource = 'EMMeter'
	begin
		select @detailsource = Source, @inusebatchid = InUseBatchID from bEMMR 	with (nolock)
		where EMCo = @co and Mth = @mth and EMTrans = @emtrans

		select @numrows = @@rowcount
	end --@embfsource

	if @embfsource = 'EMAlloc' or @embfsource = 'EMAdj' or @embfsource = 'EMDepr' or @embfsource = 'EMParts' 
	or @embfsource = 'EMTime' or @embfsource = 'EMFuel' /* all others use bEMRD */
	begin
		select @detailsource = Source, @inusebatchid = InUseBatchID
		from bEMCD 	with (nolock)
		where EMCo = @co and Mth = @mth and EMTrans = @emtrans

		select @numrows = @@rowcount
	end --

	if @numrows = 0
	begin
		select @errmsg = 'EM Detail transaction not found'
		goto error
	end --@numrows

	if @inusebatchid is not null
	begin
		select @errmsg = 'EM Detail transaction in use by another Batch'
		goto error
	end --@inusebatchid

	/* If we are adding an Trans to EMCostAdj form that was created by another form (EMAlloc, EMDepr, EMParts, EMTime and EMFuel), 
	reset @embfsource to the EMCD source so that this routine doesn't change it to 'EMAdj' */
	if (@detailsource = 'EMAlloc' or @detailsource = 'EMDepr' or @detailsource = 'EMParts' 
	or @detailsource = 'EMTime' or @detailsource = 'EMFuel') and @embfsource = 'EMAdj'
	begin  
			select @embfsource = @detailsource
	end

	if @detailsource <> @embfsource 
	begin
		select @errmsg = 'EM transaction was created with another source ' + '(detailsource=' + @detailsource + ' vs embfsource=' + @embfsource + ') '
		goto error
	end

	/* update EM transaction as 'in use' */
	if @embfsource = 'EMRev' /* Revenue source uses bEMRD */
	begin
		update bEMRD
		set InUseBatchID = @batchid
		where EMCo = @co and Mth = @mth and Trans = @emtrans

		select @numrows = @@rowcount
	end --@embfsource

	if @embfsource = 'EMMeter'
	begin
		update bEMMR
		set InUseBatchID = @batchid
		where EMCo = @co and Mth = @mth and EMTrans = @emtrans
	end --@embfsource

	if @embfsource = 'EMAlloc' or @embfsource = 'EMAdj' or @embfsource = 'EMDepr' 
	or @embfsource = 'EMParts' or @embfsource = 'EMTime' or @embfsource = 'EMFuel'
 	begin
 		update bEMCD
 		set InUseBatchID = @batchid
 		where EMCo = @co and Mth = @mth and EMTrans = @emtrans

 		select @numrows = @@rowcount
 	end --

	if @numrows <> 1
	begin
		select @errmsg = 'Unable to update EM Detail as In Use'
		goto error
	end --@numrows
end --if @emtrans is not null

/* validate existing EM trans */
if @reversalstatus = 2
begin
 	if @embfsource = 'EMRev' /* Revenue source uses bEMRD */
 	begin
 		select @detailsource = Source, @inusebatchid = InUseBatchID
 		from bEMRD 	with (nolock)
 		where EMCo = @co and Mth = @origmth and Trans = @origemtrans

 		select @numrows = @@rowcount
 	end --@embfsource

	if @embfsource = 'EMMeter'
	begin
		select @detailsource = Source, @inusebatchid = InUseBatchID
		from bEMMR with (nolock)
		where EMCo = @co and Mth = @origmth and EMTrans = @origemtrans

		select @numrows = @@rowcount
	end --'@embfsource

	if @embfsource = 'EMAlloc' or @embfsource = 'EMAdj' or @embfsource = 'EMDepr' or @embfsource = 'EMParts' 
	or @embfsource = 'EMTime' or @embfsource = 'EMFuel'
	begin
		select @detailsource = Source, @inusebatchid = InUseBatchID
		from bEMCD	with (nolock)
		where EMCo = @co and Mth = @origmth and EMTrans = @origemtrans

		select @numrows = @@rowcount
	end --

	if @numrows = 0
	begin
		select @errmsg = 'Original Detail transaction ' + isnull(convert(varchar(10), @origmth),'')
					+ ':' + isnull(convert(varchar(5), @origemtrans),'') + ' for reversal not found'
		goto error
	end --@numrows

	if @inusebatchid is not null
	begin
		select @errmsg = 'Original Detail transaction for reversal is in use by another Batch'
		goto error
	end --@inusebatchid

	if @detailsource <> @embfsource
	begin
		select @errmsg = 'Original Detail transaction for reversal was created with another source'
		goto error
	end --@detailsource

	/* update EM transaction as 'in use' */
	if @embfsource = 'EMRev' /* Revenue source uses bEMRD */
	begin
		update bEMRD
		set InUseBatchID = @batchid
		where EMCo = @co and Mth = @origmth and Trans = @origemtrans

		select @numrows = @@rowcount
	end --@embfsource
	
	if @embfsource = 'EMMeter'
	begin
		update bEMMR
		set InUseBatchID = @batchid
		where EMCo = @co and Mth = @origmth and EMTrans = @origemtrans
	end --@embfsource

	if @embfsource = 'EMAlloc' or @embfsource = 'EMAdj' or @embfsource = 'EMDepr' 
	or @embfsource = 'EMParts' or @embfsource = 'EMTime' or @embfsource = 'EMFuel'
 	begin
 		update bEMCD
 		set InUseBatchID = @batchid
 		where EMCo = @co and Mth = @origmth and EMTrans = @origemtrans

 		select @numrows = @@rowcount
 	end --

	if @@rowcount <> 1
	begin
		select @errmsg = 'Unable to update original Detail transaction as In Use'
		goto error
	end --@@rowcount
end --if @reversalstatus = 2
   		  		
--update EMEM TV 09/20/04 25553 - JC Job/Job date/Date of last usage not being updated with imported EMBF data.
if @embfsource = 'EMRev' and @batchtranstype = 'A' and @emtranstype = 'J'
begin
	--clear first
	select @equip = '', @actualdate = '', @jcco = null, @job = '' 

	select @equip = Equipment, @actualdate = ActualDate, @jcco = JCCo, @job = Job  from inserted
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
	begin
		--update EMEM
		exec @rcode = bspEMEMJobLocDateUpdate @co, @equip, @jcco, @job, @actualdate,@actualdate, @errmsg output
	end	
end --@embfsource
   
/* if a usage record has attachments, add them here */
if @embfsource = 'EMRev' and @batchtranstype = 'A' and
 exists(select top 1 1 from bEMEM with (nolock) where EMCo = @co and AttachToEquip = @equip and Status = 'A')
begin
	select @seq = @batchseq, @emgroup = EMGroup, @transtype = EMTransType, @equip = Equipment, @revcode = RevCode, @costcode = CostCode,
	@emct = EMCostType, @actualdate = ActualDate, @offsetacct = GLOffsetAcct,
	@prco = PRCo, @employee = PREmployee, @workorder = WorkOrder, @woitem = WOItem,
	@jcco = JCCo, @job = Job, @phasegroup = PhaseGrp, @phase = JCPhase, @jcct = JCCostType,	
	@revworkunits = RevWorkUnits, @revtimeunits = RevTimeUnits, @comptype = ComponentTypeCode, @component = Component,
	@revdollars = RevDollars, @usedonequipco = RevUsedOnEquipCo, @usedonequipgroup = RevUsedOnEquipGroup,
	@offsetglco = OffsetGLCo, @usedonequip = RevUsedOnEquip,
	@prehourmeter = PreviousHourMeter, @currhourmeter = CurrentHourMeter, @preodometer = PreviousOdometer,
	@currodometer = CurrentOdometer, @prcrew = PRCrew
	from inserted
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

	select @seq = max(BatchSeq) from inserted i
	where i.Co = @co and i.Mth = @mth and i.BatchId = @batchid

	select @attachment = min(Equipment)from bEMEM with (nolock)
	where EMCo = @co and AttachToEquip = @equip and Status = 'A'

	while @attachment is not null
	begin
		select @catgy = Category, @hourmeter = HourReading, @odometer = OdoReading, @posttoattach = AttachPostRevenue
		from bEMEM with (nolock)
		where EMCo = @co and Equipment = @attachment

		if @posttoattach = 'Y'
		begin
			select @seq = @seq + 1

			exec @rcode = bspEMRevRateUMDflt @co, @emgroup, @transtype, @attachment, @catgy, @revcode, @jcco, @job,
			@rate=@rate output, @time_um=@time_um output, @work_um=@work_um output,
			@msg=@errmsg output

			if @rcode <> 0 goto error

			select @basis = Basis from bEMRC where EMGroup = @emgroup and RevCode = @revcode
			-- TV 06/02/04 24550 -If revenue posted as $Amt and no units, the attachment gets $0.00 revenue -- backed out
			select @amt = isnull(@rate,0) * case @basis when 'H' then isnull(@revtimeunits,0) else isnull(@revworkunits,0) end
			--TV 1/24/02 19145 - Removed previous changes. Was acting as designed 
			--select @attachrevcode = RevenueCode from bEMEM where EMCo = @co and Equipment = @attachment

			insert into bEMBF (Co, Mth, BatchId, BatchSeq, EMGroup, BatchTransType, EMTransType, Source, Equipment, RevCode, CostCode, EMCostType, ActualDate,
			GLCo, GLOffsetAcct, PRCo, PREmployee, WorkOrder, WOItem, JCCo, Job, PhaseGrp,
			JCPhase, JCCostType, RevRate, UM, RevWorkUnits, TimeUM, RevTimeUnits, ComponentTypeCode, Component,
			RevDollars, RevUsedOnEquipCo, RevUsedOnEquipGroup, OffsetGLCo, RevUsedOnEquip,
			PreviousHourMeter, CurrentHourMeter, PreviousOdometer, CurrentOdometer, PRCrew)
			values(@co, @mth, @batchid, @seq, @emgroup, @batchtranstype, @transtype, 'EMRev', @attachment, @revcode, @costcode, @emct,
			@actualdate, @glco, @offsetacct, @prco, @employee, @workorder, @woitem, @jcco, @job,
			@phasegroup, @phase, @jcct, @rate, @work_um, @revworkunits, @time_um, @revtimeunits, @comptype, @component,
			@amt, @usedonequipco, @usedonequipgroup, @offsetglco, @usedonequip,
			@hourmeter, 0, @odometer, 0, @prcrew)
		end --@posttoattach

		select @attachment = min(Equipment) from bEMEM with (nolock)
		where EMCo = @co and AttachToEquip = @equip and Status = 'A' and Equipment > @attachment
	end --while @attachment is not null
end --if @embfsource = 'EMRev' and @batchtranstype = 'A' and

/*132064 START*/
if @embfsource = 'EMMeter' 
begin 
	--Get current Meter Readings
	select @actualdate =MeterReadDate,@currhourmeter=CurrentHourMeter, @currodometer =CurrentOdometer from inserted
	
	/*1. New Meter Readings Update existing Odometer/Hourmeter for Meter Reading Batch	
	Update on new Meter Readings, If Retro, update occurs in batch post process or (EMMR Trigger)*/
	/*2.  Update on the next "Change" Meter Readings, if next meter readings is in batch to be changed also
	If correction, update the following meter reading in EMMR which will occur in batch post process or (EMMR Trigger)*/
	/*3.  Update on the next Meter Readings in EMMR/EMBF,  
	EMBF if next meter reading is in current batch or next meter reading is being changed
	EMMR if next meter reading isn't in current batch as new or changed record, update will occur in batch post process or (EMMR Trigger)*/
	exec @rcode = dbo.vspEMBFUpdateNextBatchSeq @co, @mth, @batchid,@batchseq, @batchtranstype, @emtrans,
	'N'/*DeleteTriggerYN*/,@equip, @actualdate, @currhourmeter, @currodometer,@errmsg OUTPUT
	----TFS-43533
	IF @rcode <> 0 GOTO error  
  --  	if @rcode <> 0
  --  	begin
  --   	select @errmsg = @errtext, @rcode = 1
  --   	goto error
		--end 
end 


---- add entry to HQ Close Control as needed
IF NOT EXISTS(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
	BEGIN
	INSERT bHQCC (Co, Mth, BatchId, GLCo)
	VALUES (@co, @mth, @batchid, @glco)
	END

---- TK-16871 get GL Company for JCCo 
IF @jcco IS NOT NULL
	BEGIN
	SELECT @glco = GLCo from bJCCO where JCCo = @jcco
	IF @@ROWCOUNT <> 0
		BEGIN
		---- add entry to HQ Close Control for Job Sale
		IF NOT EXISTS(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
			BEGIN
			INSERT bHQCC (Co, Mth, BatchId, GLCo)
			VALUES (@co, @mth, @batchid, @glco)
			END
		END
	END




if @numrows > 1
begin
	--TV 2/11/04  23746 - Changed the oder in the Fetch Next
	fetch next from bEMBF_insert into @co, @mth, @batchid, @batchseq,@embfsource, @batchtranstype,
		@emtrans, @equip, @glco, @reversalstatus, @origmth, @origemtrans, @emtranstype
		----TK-16871
		,@jcco

	if @@fetch_status = 0
		begin 
			goto insert_check
		end 
	else
		begin
			close bEMBF_insert
			deallocate bEMBF_insert
		end
end

return
	
error:
	if @numrows > 1
	begin
		close bEMBF_insert
		deallocate bEMBF_insert
	end --@numrows

	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Detail Batch entry!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

     
     

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btEMBFu  ******/
CREATE  trigger [dbo].[btEMBFu] on [dbo].[bEMBF] for update as
/*--------------------------------------------------------------
*  Update trigger for EMBF
*  Created By:  ae 03/29/00
*  Modified by: GF 05/21/2003 - issue #20849 - do not update EMDS for depreciation taken
*				TV 02/11/04 - 23061 added isnulls
*				TRL 02/09/10 Issue 132064 Allow Retro Mete Readings
*				GF 08/08/2012 TK-16871 intercompany HQCC
*				GF 03/14/2013 TFS-43533 issue #140392 return error message from stored proc
*
*--------------------------------------------------------------*/
declare @rcode int,@numrows int, @errmsg varchar(255), @errtext varchar(255), 
		@co bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @embfsource varchar(10),
		@batchtranstype char(1), @emtrans bTrans, @equip bEquip, @actualdate bDate,
		@currhourmeter bHrs, @currodometer bHrs
		----TK-16871
		,@jcco bCompany, @emglco bCompany, @glco bCompany, @opencursor INT

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

SET @rcode = 0
SET @opencursor = 0

----select @embfsource=Source 	from INSERTED

-- cursor only needed if more than a single row updated
if @numrows = 1
	BEGIN
	SELECT @co =Co, @mth =Mth, @batchid =BatchId, @batchseq=BatchSeq, @batchtranstype=BatchTransType,
			@emtrans=EMTrans, @equip=Equipment, @actualdate=MeterReadDate,
			@currhourmeter=CurrentHourMeter, @currodometer =CurrentOdometer,
			@embfsource=[Source]
			----TK-16871
			,@jcco=JCCo, @emglco=GLCo
	from inserted
	END       		
ELSE
	BEGIN
	-- use a cursor to process each updated row
	DECLARE bEMBF_update CURSOR LOCAL FAST_FORWARD FOR				
	SELECT Co, Mth, BatchId, BatchSeq, BatchTransType, EMTrans, Equipment, MeterReadDate,
			CurrentHourMeter, CurrentOdometer, [Source]
			----TK-16871
			,JCCo, GLCo
	FROM	inserted i 
  
	open bEMBF_update
	set @opencursor = 1
		   
	fetch next from bEMBF_update into @co, @mth, @batchid, @batchseq, @batchtranstype, @emtrans,
			@equip, @actualdate, @currhourmeter, @currodometer, @embfsource
			----TK-16871
			,@jcco, @emglco
	IF @@fetch_status <> 0
		BEGIN
		SET @errmsg = 'Cursor error'
		GOTO error
		END
	END

------------------------
-- INSERT CHECK START --
------------------------
insert_HQCC_check:

---- add entry to HQ Close Control for EM Company GLCo
IF NOT EXISTS(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @emglco)
	BEGIN
	INSERT bHQCC (Co, Mth, BatchId, GLCo)
	VALUES (@co, @mth, @batchid, @emglco)
	END
   
---- get GL Company for Job
IF @jcco IS NOT NULL
	BEGIN
	SELECT @glco = GLCo from bJCCO with (nolock) where JCCo = @jcco
	IF @@ROWCOUNT <> 0
		BEGIN
		---- add entry to HQ Close Control for Job
		IF NOT EXISTS(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
			BEGIN
			INSERT bHQCC (Co, Mth, BatchId, GLCo)
			VALUES (@co, @mth, @batchid, @glco)
			END
		END
	END


if @embfsource = 'EMMeter' 
	BEGIN
	/*1. New Meter Readings Update existing Odometer/Hourmeter for Meter Reading Batch	
	Update on new Meter Readings, If Retro, update occurs in batch post process or (EMMR Trigger)*/
	/*2.  Update on the next "Change" Meter Readings, if next meter readings is in batch to be changed also
	If correction, update the following meter reading in EMMR which will occur in batch post process or (EMMR Trigger)*/
	/*3.  Update on the next Meter Readings in EMMR/EMBF,  
	EMBF if next meter reading is in current batch or next meter reading is being changed
	EMMR if next meter reading isn't in current batch as new or changed record, update will occur in batch post process or (EMMR Trigger)*/
	exec @rcode = dbo.vspEMBFUpdateNextBatchSeq @co, @mth, @batchid,@batchseq, @batchtranstype, @emtrans,
				'N', @equip, @actualdate, @currhourmeter, @currodometer, @errmsg output
	----TFS-43533
	IF @rcode <> 0 GOTO error  
  --  	if @rcode <> 0
  --  	begin
  --   	select @errmsg = @errtext, @rcode = 1
  --   	goto error
		--end 
	END 


IF @numrows > 1
	BEGIN
	FETCH NEXT FROM bEMBF_update INTO @co, @mth, @batchid, @batchseq, @batchtranstype, @emtrans,
			@equip, @actualdate, @currhourmeter, @currodometer, @embfsource
			----TK-16871
			,@jcco, @emglco
									
	IF @@fetch_status = 0  GOTO insert_HQCC_check

	CLOSE bEMBF_update
	DEALLOCATE bEMBF_update
	SET @opencursor = 0
	END


RETURN


error:
	IF @opencursor = 1
		BEGIN
		CLOSE bEMBF_update
		DEALLOCATE bEMBF_update
		END
		
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMBF'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
   
  
 





GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [CK_bEMBF_AutoUsage] CHECK (([AutoUsage]='N' OR [AutoUsage]='Y'))
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [CK_bEMBF_INStkECM] CHECK (([INStkECM]='M' OR [INStkECM]='C' OR [INStkECM]='E' OR [INStkECM] IS NULL))
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [CK_bEMBF_OldINStkECM] CHECK (([OldINStkECM]='M' OR [OldINStkECM]='C' OR [OldINStkECM]='E' OR [OldINStkECM] IS NULL))
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [CK_bEMBF_OldPerECM] CHECK (([OldPerECM]='M' OR [OldPerECM]='C' OR [OldPerECM]='E' OR [OldPerECM] IS NULL))
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [CK_bEMBF_PerECM] CHECK (([PerECM]='M' OR [PerECM]='C' OR [PerECM]='E' OR [PerECM] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [biEMBF] ON [dbo].[bEMBF] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMBF] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMAH_AllocCode] FOREIGN KEY ([Co], [AllocCode]) REFERENCES [dbo].[bEMAH] ([EMCo], [AllocCode])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMEM_Component] FOREIGN KEY ([Co], [Component]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMEM_Equipment] FOREIGN KEY ([Co], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMWH_WorkOrder] FOREIGN KEY ([Co], [WorkOrder]) REFERENCES [dbo].[bEMWH] ([EMCo], [WorkOrder])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMWI_WOItem] FOREIGN KEY ([Co], [WorkOrder], [WOItem]) REFERENCES [dbo].[bEMWI] ([EMCo], [WorkOrder], [WOItem])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMTY_ComponentTypeCode] FOREIGN KEY ([EMGroup], [ComponentTypeCode]) REFERENCES [dbo].[bEMTY] ([EMGroup], [ComponentTypeCode])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMCT_EMCostType] FOREIGN KEY ([EMGroup], [EMCostType]) REFERENCES [dbo].[bEMCT] ([EMGroup], [CostType])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMPS_PartsStatusCode] FOREIGN KEY ([EMGroup], [PartsStatusCode]) REFERENCES [dbo].[bEMPS] ([EMGroup], [PartsStatusCode])
GO
ALTER TABLE [dbo].[bEMBF] WITH NOCHECK ADD CONSTRAINT [FK_bEMBF_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMAH_AllocCode]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMEM_Component]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMWH_WorkOrder]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMWI_WOItem]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMTY_ComponentTypeCode]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMCC_CostCode]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMCT_EMCostType]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMPS_PartsStatusCode]
GO
ALTER TABLE [dbo].[bEMBF] NOCHECK CONSTRAINT [FK_bEMBF_bEMRC_RevCode]
GO
