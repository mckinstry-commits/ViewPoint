SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[bspEMBFPost_Usage]
/***********************************************************
* CREATED BY:    bc 02/09/99
* MODIFIED By :  bc 09/19/00 - added file attachment code to batchtranstype A and C
*                MV 6/1/01 - Issue 12769 BatchUserMemoUpdate
*                TV/RM 02/22/02 Attachment Fix
*                CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*		        GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*                bc 06/05/02 - #17569 - Duplicate key row inserting bEMCD
*                bc 05/07/03 - #21232 
*                TV 12/04/03 18616 --reindex Attachments 
*				 TV 02/11/04 - 23061 added isnulls
*				 TV 08/03/04 25252 - needs to update BatchID
*				 TV 11/23/04 - #24034 - update PRCrew from bEMBF to bEMRD 
*				 TV 12/09/04 26302 - update EMJC With the EMTrans so it goes to JCCD 
*				 GP 06/30/08 - Issue 124677, added the insert of bEMBF.Description to bEMRD.Memo
*								 because of the added "Description" field on EMUsePosting.
*				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*				GP 05/26/09 - Issue 133434, removed HQAT code
*				TRL 02/04/2010 Issue 137916  change @description to 60 characters  
*				GF 01/18/2013 TK-20805 when posting usage needs to be done in date order so that meters are update correctly
*
*
*
* USAGE:	posts revenue to EMRD
*		updates GL
*		updates JCCD on job type lines.
*		updates EMRB when posting at the revenue breakdown level.
*		EMAR, EMEM and EMCD are updated in the EMRD triggers
*
* INPUT PARAMETERS:
*   @co             EM Co#
*   @mth            Batch Month
*   @batchid        Batch Id
*   @dateposted     Posting date
*
* OUTPUT PARAMETERS
*   @errmsg         error message if something went wrong
*
* RETURN VALUE:
*   0               success
*   1               fail
*****************************************************/
   	(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
as
set nocount on
       
declare @rcode int, @opencursor tinyint, @openEMBFcursor tinyint, @status tinyint, @errorstart varchar(20),
		@msg varchar(60), @source varchar(10), @catgy bCat, @meter_trans bTrans, @costtrans bTrans, @cnt int, @updatehours bYN,
		@keyfield varchar(128), @updatekeyfield varchar(128), @Notes varchar(256)
       

declare @seq int, @batchtranstype char(1), @emtranstype varchar(10), @emtrans bTrans, @emgroup bGroup, @equip bEquip,
		@revcode bRevCode, @costcode bCostCode, @emct bEMCType, @actualdate bDate, @description bItemDesc /*137916*/, @glco bCompany,
		@transacct bGLAcct, @offsetglco bCompany, @offsetacct bGLAcct, @prco bCompany, @employee bEmployee, @workorder bWO,
		@woitem bItem, @workum bUM, @timeum bUM, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase,
		@jcct bJCCType, @revrate bDollar, @revworkunits bUnits, @revtimeunits bUnits, @revdollars bDollar,
		@usedonequipco bCompany, @usedonequipgroup bGroup, @usedonequip bEquip, @comptype varchar(10), @component bEquip,
		@prehourmeter bHrs, @currhourmeter bHrs, @preodometer bHrs, @currodometer bHrs, @guid UniqueIdentifier,
		@prcrew varchar(10)
       
        select @rcode = 0, @opencursor = 0, @openEMBFcursor = 0
       
        /* check for Posting Date */
        if @dateposted is null
            begin
            select @errmsg = 'Missing posting date!', @rcode = 1
            goto bspexit
            end
       
        /* validate HQ Batch */
        exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'EMRev', 'EMBF', @errmsg output, @status output
        if @rcode <> 0 goto bspexit
        if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
            begin
            select @errmsg = 'Invalid Batch status -  must be Valid - OK to post or Posting in progress!', @rcode = 1
            goto bspexit
            end
       
        /* set HQ Batch status to 4 (posting in progress) */
        update bHQBC
            set Status = 4, DatePosted = @dateposted
         	where Co = @co and Mth = @mth and BatchId = @batchid
        if @@rowcount = 0
            begin
            select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
            goto bspexit
            end
       
/* declare cursor on EM Header Batch */
----TK-20805 changed cursor select for a group by clause by equipment, actual date, sequence 
declare bcEMBF cursor FOR
    SELECT BatchSeq
	  
--select BatchSeq, BatchTransType, EMTransType, EMTrans, EMGroup, Source, Equipment, RevCode,
--            CostCode, EMCostType, ActualDate, Description, GLCo, GLTransAcct, OffsetGLCo, GLOffsetAcct, PRCo, PREmployee, WorkOrder,
--            WOItem, UM, TimeUM, JCCo, Job, PhaseGrp, JCPhase, JCCostType, RevRate,
--            RevWorkUnits, RevTimeUnits, RevDollars, RevUsedOnEquipCo, RevUsedOnEquipGroup, OffsetGLCo,
--            RevUsedOnEquip, ComponentTypeCode, Component,
--            isnull(PreviousHourMeter,0), isnull(CurrentHourMeter,0), isnull(PreviousOdometer,0), isnull(CurrentOdometer,0),
--            UniqueAttchID, PRCrew
from bEMBF
where Co = @co and Mth = @mth and BatchId = @batchid
----TK-20805
GROUP BY Co, Mth, BatchId, Equipment, ActualDate, BatchSeq
       
/* open EM Batch cursor */
open bcEMBF
select @opencursor = 1
       
/* loop through all rows in EM Batch cursor */
em_posting_loop:
       
/* reinitialized variables for next transaction */
select @catgy = null, @costtrans = null, @meter_trans = null
    
----TK-20805 
FETCH NEXT FROM bcEMBF INTO @seq
--fetch next from bcEMBF into @seq, @batchtranstype, @emtranstype, @emtrans, @emgroup, @source, @equip, @revcode,
--@costcode, @emct, @actualdate, @description, @glco, @transacct, @offsetglco, @offsetacct, @prco, @employee, @workorder,
--@woitem, @workum, @timeum, @jcco, @job, @phasegroup, @phase, @jcct, @revrate,
--@revworkunits, @revtimeunits, @revdollars, @usedonequipco, @usedonequipgroup, @offsetglco,
--@usedonequip, @comptype, @component,
--@prehourmeter, @currhourmeter, @preodometer, @currodometer, @guid, @prcrew
       
if @@fetch_status = -1 goto em_posting_end
if @@fetch_status <> 0 goto em_posting_loop
select @errorstart = 'Seq# ' + isnull(convert(varchar(6),@seq),'')

---- TK-20805 get batch info
SELECT  @batchtranstype = BatchTransType, @emtranstype = EMTransType, @emtrans = EMTrans, @emgroup = EMGroup,
		@source = Source, @equip = Equipment, @revcode = RevCode, @costcode = CostCode, @emct = EMCostType,
		@actualdate = ActualDate, @description = Description, @glco = GLCo, @transacct = GLTransAcct,
		@offsetglco = OffsetGLCo, @offsetacct = GLOffsetAcct, @prco = PRCo, @employee = PREmployee,
		@workorder = WorkOrder, @woitem = WOItem, @workum = UM, @timeum = TimeUM, @jcco = JCCo, @job = Job,
		@phasegroup = PhaseGrp, @phase = JCPhase, @jcct = JCCostType, @revrate = RevRate,
		@revworkunits = RevWorkUnits, @revtimeunits = RevTimeUnits, @revdollars = RevDollars,
		@usedonequipco = RevUsedOnEquipCo, @usedonequipgroup = RevUsedOnEquipGroup, @offsetglco = OffsetGLCo,
		@usedonequip = RevUsedOnEquip, @comptype = ComponentTypeCode, @component = Component,
		@prehourmeter = ISNULL(PreviousHourMeter,0), @currhourmeter = ISNULL(CurrentHourMeter,0),
		@preodometer = ISNULL(PreviousOdometer,0), @currodometer = ISNULL(CurrentOdometer,0),
		@guid = UniqueAttchID, @prcrew = PRCrew
	--SELECT BatchTransType, EMTransType, EMTrans, EMGroup, Source, Equipment, RevCode,
	--            CostCode, EMCostType, ActualDate, Description, GLCo, GLTransAcct, OffsetGLCo, GLOffsetAcct, PRCo, PREmployee, WorkOrder,
	--            WOItem, UM, TimeUM, JCCo, Job, PhaseGrp, JCPhase, JCCostType, RevRate,
	--            RevWorkUnits, RevTimeUnits, RevDollars, RevUsedOnEquipCo, RevUsedOnEquipGroup, OffsetGLCo,
	--            RevUsedOnEquip, ComponentTypeCode, Component,
	--            isnull(PreviousHourMeter,0), isnull(CurrentHourMeter,0), isnull(PreviousOdometer,0), isnull(CurrentOdometer,0),
	--            UniqueAttchID, PRCrew
FROM dbo.bEMBF
WHERE Co = @co 
	AND Mth = @mth 
	AND BatchId = @batchid
	AND BatchSeq = @seq


            /* retrieve the category */
            select @catgy = Category
            from bEMEM
            where EMCo = @co and Equipment = @equip
       
            begin transaction       /* start a transaction, commit after all lines have been processed */
            if @batchtranstype = 'A'	    /* new EM transaction */
                begin
                /* get next available Transaction # for EMRD */
         	    exec @emtrans = bspHQTCNextTrans 'bEMRD', @co, @mth, @msg output
         	    if @emtrans = 0
                  begin
                  select @errmsg = isnull(@errorstart,'') + ' ' + isnull(@msg,''), @rcode = 1
                  goto em_posting_error
                  end
       
                /* get next available Transaction # for EMCD if necessary */
        	    if @emtranstype in ('E', 'W')
        	      begin
         	      exec @costtrans = bspHQTCNextTrans 'bEMCD', @usedonequipco, @mth, @msg output
         	      if @costtrans = 0
                    begin
                    select @errmsg = isnull(@errorstart,'') + ' ' + isnull(@msg,''), @rcode = 1
                    goto em_posting_error
                    end
        	      end
       
                /* add EM Transaction */
                insert bEMRD(EMCo, Mth, Trans, BatchID, EMGroup, Equipment, RevCode, Source, TransType, PostDate,
                             ActualDate, JCCo, Job, PhaseGroup, JCPhase, JCCostType, PRCo, Employee, GLCo, RevGLAcct,
               	       ExpGLCo, ExpGLAcct, Memo, Category, UM, WorkUnits, TimeUM, TimeUnits, RevRate, Dollars,
                             UsedOnEquipCo, UsedOnEquipGroup, UsedOnEquipment, EMCostTrans, EMCostCode, EMCostType, WorkOrder, WOItem,
        	               UsedOnComponentType, UsedOnComponent, PreviousHourReading, HourReading, PreviousOdoReading, OdoReading,
                             UniqueAttchID, PRCrew)
                values(@co, @mth, @emtrans, @batchid, @emgroup, @equip, @revcode, @source, @emtranstype, @dateposted,
               	    @actualdate, @jcco, @job, @phasegroup, @phase, @jcct, @prco, @employee, @glco, @transacct,
               	    @offsetglco, @offsetacct, @description, @catgy, @workum, @revworkunits, @timeum, @revtimeunits, @revrate, @revdollars,
               	    @usedonequipco, @usedonequipgroup, @usedonequip, @costtrans, @costcode, @emct, @workorder, @woitem,
            	        @comptype, @component, @prehourmeter, @currhourmeter, @preodometer, @currodometer, @guid, @prcrew)
       
                if @@rowcount = 0
                    begin
                    select @errmsg = isnull(@errorstart,'') + ' Unable to insert EM Transaction.', @rcode = 1
                    goto em_posting_error
                    end
       
                /* update EM Trans# to distribution tables */
                update bEMGL set EMTrans = @emtrans where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                update bEMJC set EMTrans = @emtrans where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                update bEMBC set EMTrans = @emtrans where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                /* update EM Trans# to batch record for BatchUserMemoUpdate */
                update bEMBF set EMTrans = @emtrans where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
            
               /* call bspBatchUserMemoUpdate to update user memos in bEMRD before deleting the batch record */
               if @batchtranstype in ('A','C')
               begin
               exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'EM UsePosting', @errmsg output
               if @rcode <> 0
                   begin
                   select @errmsg = 'Unable to update User Memo in EMRD.', @rcode = 1
        			goto em_posting_error
                   end
               end
       
                /* remove current Transaction from batch */
                delete bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                if @@rowcount = 0
                  begin
                  select @errmsg = isnull(@errorstart,'') + ' Unable to remove EM batch sequence.', @rcode = 1
                  goto em_posting_error
                  end
       
                commit transaction
                goto em_posting_loop    /* next batch entry */
            end
       
            if @batchtranstype = 'C'	    /* update existing transaction */
                begin
                update bEMRD -- TV 08/03/04 25252 - needs to update BatchID
                set BatchID = @batchid, Equipment = @equip, EMGroup = @emgroup, RevCode = @revcode, TransType = @emtranstype,
                    ActualDate = @actualdate, JCCo = @jcco, PhaseGroup = @phasegroup, Job = @job, JCPhase = @phase, JCCostType = @jcct,
        	           PRCo = @prco, Employee = @employee, GLCo = @glco, RevGLAcct = @transacct,
            	       ExpGLCo = @offsetglco, ExpGLAcct = @offsetacct, Memo = @description, Category = @catgy, 
					   UM = @workum, WorkUnits = @revworkunits,
        	           TimeUM = @timeum, TimeUnits = @revtimeunits, RevRate = @revrate, Dollars = @revdollars,
                       UsedOnEquipCo = @usedonequipco, UsedOnEquipGroup = @usedonequipgroup,
        	           UsedOnEquipment = @usedonequip, EMCostCode = @costcode, EMCostType = @emct,
        	           WorkOrder = @workorder, WOItem = @woitem, UsedOnComponentType = @comptype, UsedOnComponent = @component,
        	           PreviousHourReading = @prehourmeter, HourReading = @currhourmeter,
        	           PreviousOdoReading = @preodometer, OdoReading = @currodometer, UniqueAttchID = @guid, PRCrew = @prcrew
                where EMCo = @co and Mth = @mth and Trans = @emtrans
                if @@rowcount = 0
                    begin
                    select @errmsg = isnull(@errorstart,'') + ' Unable to update existing EM Transaction.', @rcode = 1
                    goto em_posting_error
                    end
      
                /* remove any existing records in EMRB for this transaction.
                   on a change we are going to reprocess the entire break down routine incase
                   changes were made at the override levels */
                if exists(select * from bEMRB where EMCo = @co and Mth = @mth and Trans = @emtrans)
                  begin
                  delete bEMRB where EMCo = @co and Mth = @mth and Trans = @emtrans
                  end
       
                /* update EM Trans# to distribution tables */
                update bEMGL set EMTrans = @emtrans where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                update bEMJC set EMTrans = @emtrans where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                update bEMBC set EMTrans = @emtrans where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
       
       
      
                /* call bspBatchUserMemoUpdate to update user memos in bEMRD before deleting the batch record */
               if @batchtranstype in ('A','C')
               begin
               exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'EM UsePosting', @errmsg output
               if @rcode <> 0
                   begin
                   select @errmsg = 'Unable to update User Memo in EMRD.', @rcode = 1
        			goto em_posting_error
                   end
               end
                --reindex Attachments TV 12/04/03 18616
                 if @guid is not null
                    begin
                    exec bspHQRefreshIndexes null, null, @guid, null
                    end
       
                /* remove current Transaction from batch */
                delete bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                if @@rowcount = 0
                    begin
                    select @errmsg = isnull(@errorstart,'') + ' Unable to remove EM batch sequence.', @rcode = 1
                    goto em_posting_error
                    end
                commit transaction
                goto em_posting_loop    /* next batch entry */
            end
       
            if @batchtranstype = 'D'     /* delete existing transaction */
                begin
                    /* remove EM Transaction */
                    delete bEMRD where EMCo = @co and Mth = @mth and Trans = @emtrans
                    if @@rowcount = 0
                        begin
                        select @errmsg = isnull(@errorstart,'') + ' Unable to remove EM Transaction.', @rcode = 1
                        goto em_posting_error
                        end
                    /* remove any existing records in EMRB for this transaction */
                    if exists(select * from bEMRB where EMCo = @co and Mth = @mth and Trans = @emtrans)
                      begin
                      delete bEMRB where EMCo = @co and Mth = @mth and Trans = @emtrans
                      end
                    --reindex Attachments TV 12/04/03 18616
                    if @guid is not null
                        begin
                        exec bspHQRefreshIndexes null, null, @guid, null
                        end
     				
   				--update EMJC With the EMTrans so it goes to JCCD 26302 TV 12/09/04
   				update bEMJC set EMTrans = @emtrans where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                
                    /* remove current Transaction from batch */
                    delete bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                    if @@rowcount = 0
                        begin
                        select @errmsg = isnull(@errorstart,'') + ' Unable to remove EM batch sequence.', @rcode = 1
                        goto em_posting_error
                        end
                    commit transaction
                    goto em_posting_loop    /* next batch entry */
            end
       
        em_posting_error:
            rollback transaction
            goto bspexit
       
        em_posting_end:			/* no more Transactions to process */
            if @opencursor=1
                begin
                close bcEMBF
                deallocate bcEMBF
              select @opencursor = 0
            end
       
       
        jc_update:
            exec @rcode=bspEMBFPostJC @co, @mth, @batchid, @dateposted, 'EMRev', @errmsg output
       
            if @rcode <> 0 goto bspexit
            /* make sure all JC Distributions have been processed */
            if exists(select * from bEMJC where EMCo = @co and Mth = @mth and BatchId = @batchid)
                begin
                select @errmsg = 'Not all updates to JC were posted - unable to close the batch!', @rcode = 1
                goto bspexit
                end
       
        gl_update:
            exec @rcode=bspEMBFPostGL @co, @mth, @batchid, @dateposted, 'Usage', 'EMRev', @errmsg output
            if @rcode <> 0 goto bspexit
            /* make sure all GL Distributions have been processed */
            if exists(select * from bEMGL where EMCo = @co and Mth = @mth and BatchId = @batchid)
       begin
         	select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
         	goto bspexit
         	end
       
       
        /* emrb get's at least one record written to it for every transaction */
        rb_update:
            exec @rcode=bspEMBFPostRB @co, @mth, @batchid, @errmsg output
            if @rcode <> 0 goto bspexit
            /* make sure all RB Distributions have been processed */
            if exists(select * from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid)
                begin
         	select @errmsg = 'Not all updates to Rev BreakDown table were posted - unable to close the batch!', @rcode = 1
         	goto bspexit
         	end
       
           -- set interface levels note string
           select @Notes=Notes from bHQBC
           where Co = @co and Mth = @mth and BatchId = @batchid
           if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
           select @Notes=isnull(@Notes,'') +
               'GL Adjustments Interface Level set at: ' + isnull(convert(char(1), a.AdjstGLLvl),'') + char(13) + char(10) +
               'GL Usage Interface Level set at: ' + isnull(convert(char(1), a.UseGLLvl),'') + char(13) + char(10) +
               'GL Parts Interface Level set at: ' + isnull(convert(char(1), a.MatlGLLvl),'') + char(13) + char(10)
           from bEMCO a where EMCo=@co
       
        /* delete HQ Close Control entries */
        delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
        /* set HQ Batch status to 5 (posted) */
        update bHQBC
        set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
        where Co = @co and Mth = @mth and BatchId = @batchid
        if @@rowcount = 0
         	begin
         	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
         	goto bspexit
         	end
       
        bspexit:
         	if @opencursor = 1
                begin
         	    close bcEMBF
         		deallocate bcEMBF
         		end
            return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMBFPost_Usage] TO [public]
GO
