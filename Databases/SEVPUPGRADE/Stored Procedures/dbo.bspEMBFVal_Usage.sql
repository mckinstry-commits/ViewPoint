
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE  procedure [dbo].[bspEMBFVal_Usage]
/***********************************************************
 * CREATED: 	bc 01/28/99
 * MODIFIED: bc 10/16/00- changed which bsp validates the Employee
 *           mv 04/10/01- Issue # 12062 - allow posting to down equipment
 *           bc 05/29/01 - added @phase as input parameter to bspEMUsageGlacctDflt
 *           bc 05/30/01 - added case statment to EMJC insert for old records to adhere to the JCCT.TrackHours flag
 *	        JM 08/02/01 - Ref Issue 14068 - Added validation of PRCo before its first use in validating Employee, approx line 254.
 *           bc 08/14/01 - Validate the Expense GLCo when it's different than the FormCo's GLCo
 *        	bc 02/09/02 - issue # 16232
 *           bc 03/19/02 - issue #14415 revisited
 *           JM 04/22/02 - issue #16508 Add JC Distrbution when Hours are not zero and dollars are.
 *           bc 05/16/02 - issue #17385 Add JC Distriution when WorkUnits <> 0 and RevCode Unint Based.
 *           bc 06/03/02 - issue #17541 GL out of balance due to RevBdown Code rounding problem
 *			SR 07/09/02 - issue 17738 added @phasegroup to bspJCVCOSTTYPE
 *           CMW 08/07/02 - issue #18177 - added bspJCVPHASE to validation to pick up inactive entries.
 *           bc 11/04/02 - Needed to correct Cycle 3.  The Revenue Code info should be at the end of the cycle
 *                         and contained in an If ... Then statement depending on @transacct.  
 *                         EMBC calculations should always be computed.
 *			RM 10/02/02 - issue #18613 Fixed not posting work units.
 *           TV 12/10/03 - issue 23061 - Isnulls and dbo.
 *			TV 3/11/04 22518 - If user is applying TotalOnly (with no units) then rev Dollars should be used	
 *			TV 05/12/04 24311 - Added auto usage flag
 *			TV 08/03/04 25252 - needed to compare new vs old
 *			TV 11/16/04 24034  - Insert PRCrew into EMJC
 *			TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
 *			TV 08/15/05 28474- EM Usage Post: Cannot enter Cost Detail/ trigger errorInactive Cost Type
 *			TV 09/22/05 29478 - Need to validate Cost Code on EM Usage imports, make sure it's set up
 *			TV 10/11/05 - 29989 Batch validation needs to catch invalid GL Acct.
 *			DANF 06/13/07 - 124114 Remove Automatic GL on Usage
 *			TJL 12/18/07 - Issue #29824, Provide Greater detail relative to New/Old Phase and CostType validation errors
*			GF 01/19/2008 - issue #125146 add @@rowcount checks to update statements for bEMBC and bEMGL to throw batch error.
 *			GP 05/13/2008 - Issue #124391 added error check for Work Orders that have Inactive items.
*			GF 06/06/2008 - issue #128555 added validate RevCode in EMRR based upon Category of Used/Usage Equipment
*			GF 07/02/2008 - issue #128793 added check for cycle = 3 when updating breakdown total only when @transacct is null
*			GF 08/12/2008 - issue #129385 do not check rowcount when updating bEMGL when trans account is null.
*			Dan So 08/21/2008 - Issue #129426 - NULL out CostCode(EMCostCode in EMRD) and EMCOstType when EMTransType = J or X
*			TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*			TRL 06/30/09 - Issue 133140 - changed @parameter for getting Transaction GL Account
*			TRL 06/30/09 - Issue 135745 - changed @parameter for getting Transaction GL Account
*			GF 10/01/2010 - issue #141031 - use date only function
*			GF 01/21/2013 TK-20836 when creating old entries use EMBR for value to back out
*			GF 04/03/2013 TFS-46093 NS-42471 for old revenue breakdown codes, GLCo may be null set to @oldglco
*
*
*
 * USAGE:
 * Rates are not caluclated here.  If a user imports info into the batch table we
 * will take care of the rate lookup with a completely separate bsp prior to validation.
 *
 * The revenue GL acct(s) are determined solely inside of this routine base on dept, rev code or rev bdown code
 *
 * Errors in batch added to bHQBE using bspHQBEInsert
 * Job distributions added to bEMJC
 * GL Account distributions added to bEMGL
 *
 * GL debit and credit totals must balance.
 *
 * bHQBC Status updated to 2 if errors found, or 3 if OK to post
 *
 * INPUT PARAMETERS
 *   EMCo        EM Co
 *   Month       Month of batch
 *   BatchId     Batch ID to validate
 * OUTPUT PARAMETERS
 *   @errmsg     if something went wrong
 * RETURN VALUE
 *   0   success
 *   1   fail
 *****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @errortext varchar(255), @source bSource, @tablename char(20),
		@inuseby bVPUserName, @status tinyint, @opencursorEMBF tinyint, @maxopen tinyint,
		@accttype char(1), @itemcount int, @deletecount int, @errorstart varchar(50)

/*EMBF declarations*/
declare @seq int, @batchtranstype char(1), @emtranstype varchar(10), @emtrans bTrans, @emgroup bGroup, @equip bEquip,
		@revcode bRevCode, @costcode bCostCode, @emct bEMCType, @actualdate bDate, @glco bCompany,
		@offsetacct bGLAcct, @prco bCompany, @employee bEmployee, @workorder bWO,
		@woitem bItem, @workum bUM, @timeum bUM, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase,
		@jcct bJCCType, @revrate bDollar, @revworkunits bUnits, @revtimeunits bUnits, @revdollars bDollar,
		@usedonequipco bCompany, @usedonequipgroup bGroup, @offsetglco bCompany, @usedonequip bEquip,
		@comptype varchar(10), @component bEquip,@prehourmeter bHrs, @currhourmeter bHrs,
		@preodometer bHrs, @currodometer bHrs, @oldemtranstype varchar(10), @oldemgroup bGroup,
		@oldequip bEquip, @oldrevcode bRevCode, @oldcostcode bCostCode, @oldemct bEMCType,
		@oldactualdate bDate, @oldglco bCompany, @oldoffsetacct bGLAcct, @oldprco bCompany,
		@oldemployee bEmployee, @oldworkorder bWO, @oldwoitem bItem, @oldworkum bUM, @oldtimeum bUM,
		@oldjcco bCompany, @oldjob bJob, @oldphasegroup bGroup, @oldphase bPhase, @oldjcct bJCCType,
		@oldrevrate bDollar, @oldrevworkunits bUnits, @oldrevtimeunits bUnits, @oldrevdollars bDollar,
		@oldusedonequipco bCompany, @oldusedonequipgroup bGroup, @oldoffsetglco bCompany,
		@oldusedonequip bEquip, @oldcomptype varchar(10), @oldcomponent bEquip, @oldprehourmeter bHrs,
		@oldcurrhourmeter bHrs, @oldpreodometer bHrs, @oldcurrodometer bHrs, @usegljrnl bJrnl,
		@usegllvl tinyint, @total_Bdown_dist bDollar, @diff bDollar, @save_bdown_code varchar(10),
		@autousage bYN, @prcrew varchar(10), @oldprcrew varchar(10)

/* Miscellaeous declarations */
declare @userateoride bYN, @gloverride bYN, @hoursum bUM,
		@emco_glco bCompany, @emco_prco bCompany, @dept bDept,
		@emem_jcco bCompany, @emem_job bJob, @emem_emct bEMCType, @catgy bCat,
		@compupdatehrs bYN, @compupdatemiles bYN, @attachpostrev bYN,
		@post_work_units bYN, @allow_rate_oride bYN, @rev_basis char(1), @oldrev_basis char(1),
		@jobflag bYN, @grp int, @hrsfactor int, @oldhrsfactor int, @jc_timeunits bUnits,
		@oldjc_timeunits bUnits

declare @transacct bGLAcct, @revbdowncode varchar(10), @base_rate bUnitCost, @bdown_rate bUnitCost,
		@bdown_glco bCompany, @arglacct bGLAcct, @xglco bCompany, @old_xglco bCompany, @apglacct bGLAcct,
		@jcco_glco bCompany, @lastmthsubclsd bMonth

declare @cycle int, @trackhours bYN, @oldtrackhours bYN, @switch_a_roo varchar(15), @parameter char(1)
declare @distglco bCompany, @distglacct bGLAcct, @distamt bDollar, @distequip bEquip
declare @oldtransacct bGLAcct, @olddept bDept, @oldcatgy bCat, @newentry bYN, @oldentry bYN, @changed bYN

select @rcode = 0, @opencursorEMBF = 0, @cycle = 0

/* validate HQ Batch */
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'EMRev', 'EMBF', @errmsg output, @status output
if @rcode <> 0
begin
	select @errmsg = @errmsg, @rcode = 1
	goto bspexit
end

if @status < 0 or @status > 3
begin
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto bspexit
end

/* set HQ Batch status to 1 (validation in progress) */
update bHQBC set Status = 1
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
end

/* clear HQ Batch Errors */
delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
/* clear GL Distributions Audit */
delete bEMGL where EMCo = @co and Mth = @mth and BatchId = @batchid
/* clear Job Cost Distributions Audit */
delete bEMJC where EMCo = @co and Mth = @mth and BatchId = @batchid
/* clear Revenue Breakdown Audit */
delete bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid
/*clear and refresh HQCC entries */
delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

insert into bHQCC(Co, Mth, BatchId, GLCo)
select distinct Co, Mth, BatchId, GLCo 
from bEMBF
where Co=@co and Mth=@mth and BatchId=@batchid

/* get Company info from EMCO */
select @userateoride = UseRateOride, @usegljrnl = UseGLJrnl, @usegllvl = UseGLLvl,
@hoursum = HoursUM, @gloverride = GLOverride, @emco_glco = GLCo, @emco_prco = PRCo
from bEMCO where EMCo = @co

/* JM 1/17/02 - Ref Issue 15605 - Make sure the UseGLJrnl is not null in EMCO if GLLvl > 0 */
if @usegljrnl is null and @usegllvl >0
	begin
	select @errortext = isnull(@errorstart,'') + 'UseGLJrnl may not be null in bEMCO for a Usage transaction'
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end

-- *********************************************************** --
-- NULL OUT CostCode(EMRD.EMCostCode) AND EMCostType - #129426 --
-- *********************************************************** --
UPDATE bEMBF
   SET CostCode = NULL,
	   EMCostType = NULL
 WHERE Co = @co 
   AND Mth = @mth 
   AND BatchId = @batchid
   AND EMTransType IN ('J','X')

/* declare cursor on EM Batch for validation */
declare bcEMBF cursor for select BatchSeq, Source, BatchTransType, EMTransType, EMTrans, EMGroup, Equipment, RevCode,
		CostCode, EMCostType, ActualDate, GLCo, GLOffsetAcct, PRCo, PREmployee, WorkOrder,
		WOItem, UM, TimeUM, JCCo, Job, PhaseGrp, JCPhase, JCCostType, RevRate,
		RevWorkUnits, RevTimeUnits, RevDollars, RevUsedOnEquipCo, RevUsedOnEquipGroup, OffsetGLCo,
		RevUsedOnEquip, ComponentTypeCode, Component, PreviousHourMeter, CurrentHourMeter, PreviousOdometer, CurrentOdometer,
		OldEMTransType, OldEMGroup, OldEquipment, OldRevCode,
		OldCostCode, OldEMCostType, OldActualDate, OldGLCo, OldGLOffsetAcct, OldPRCo, OldPREmployee, OldWorkOrder,
		OldWOItem, OldUM, OldTimeUM, OldJCCo, OldJob, OldPhaseGrp, OldJCPhase, OldJCCostType, OldRevRate,
		OldRevWorkUnits, OldRevTimeUnits, OldRevDollars, OldRevUsedOnEquipCo, OldRevUsedOnEquipGroup, OldOffsetGLCo,
		OldRevUsedOnEquip, OldComponentTypeCode, OldComponent, OldPreviousHourMeter, OldCurrentHourMeter, OldPreviousOdometer, OldCurrentOdometer,
		AutoUsage, PRCrew, OldPRCrew
from bEMBF 
where Co = @co and Mth = @mth and BatchId = @batchid

/* open cursor */
open bcEMBF
select @opencursorEMBF = 1


get_next_bcEMBF:
fetch next from bcEMBF into @seq, @source, @batchtranstype, @emtranstype, @emtrans, @emgroup, @equip,
		@revcode, @costcode, @emct, @actualdate, @glco, @offsetacct, @prco, @employee, @workorder,
		@woitem, @workum, @timeum, @jcco, @job, @phasegroup, @phase, @jcct, @revrate,
		@revworkunits, @revtimeunits, @revdollars, @usedonequipco, @usedonequipgroup, @offsetglco,
		@usedonequip, @comptype, @component, @prehourmeter, @currhourmeter, @preodometer, @currodometer,
		@oldemtranstype, @oldemgroup, @oldequip, @oldrevcode, @oldcostcode, @oldemct, @oldactualdate,
		@oldglco, @oldoffsetacct, @oldprco, @oldemployee, @oldworkorder,
		@oldwoitem, @oldworkum, @oldtimeum, @oldjcco, @oldjob, @oldphasegroup, @oldphase, @oldjcct,
		@oldrevrate, @oldrevworkunits, @oldrevtimeunits, @oldrevdollars, @oldusedonequipco,
		@oldusedonequipgroup, @oldoffsetglco, @oldusedonequip, @oldcomptype, @oldcomponent,
		@oldprehourmeter, @oldcurrhourmeter, @oldpreodometer, @oldcurrodometer, @autousage,
		@prcrew, @oldprcrew 

/* loop through all rows */
while (@@fetch_status = 0)
	BEGIN
	/* initialize some variables that are not fetched with the cursor and need to be reset */
	select @transacct = null, @oldtransacct = null, @jcco_glco = null, @arglacct = null, @apglacct = null, @oldrev_basis = null

	/* validate EM Batch info for each entry */
	select @errorstart = 'Seq#' + isnull(convert(varchar(6),@seq),'')
          
	/* validate batch transaction type */
	if @batchtranstype not in ('A','C','D')
		begin
		select @errortext = isnull(@errorstart,'') + ' -  Invalid transaction type, must be A,C, or D.'
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto nextseq
		end

	/* validate revenue transaction type */
	if @emtranstype not in ('J','E','X','W')
		begin
		select @errortext = isnull(@errorstart,'') + ' -  Invalid revenue transaction type, must be J,E,X or W.'
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto nextseq
		end

	/* get the trackhours flag to know whether or not we need to add the hour related values into EMJC */
	if @emtranstype = 'J'
		begin
		select @trackhours = TrackHours
		from bJCCT
		where PhaseGroup = @phasegroup and CostType = @jcct
		select @oldtrackhours = TrackHours
		from bJCCT
		where PhaseGroup = @oldphasegroup and CostType = @oldjcct
		end

	/* validation specific to Add types of transactions */
	if @batchtranstype = 'A'
		Begin
		/* check Trans number to make sure it is null*/
		if not @emtrans is null
			begin
			select @errortext = isnull(@errorstart,'') + ' - invalid to have transaction number on new entries!'
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end

		if not (@oldemgroup is null and @oldequip is null and @oldrevcode is null and
				@oldcostcode is null and @oldemct is null and @oldactualdate is null and @oldglco is null and
				@oldoffsetacct is null and @oldprco is null and @oldemployee is null and @oldworkorder is null and
				@oldwoitem is null and @oldworkum is null and @oldtimeum is null and @oldjcco is null and
				@oldjob is null and @oldphasegroup is null and @oldphase is null and @oldjcct is null and
				@oldrevrate is null and @oldrevworkunits is null and @oldrevtimeunits is null and @oldrevdollars is null and
				@oldusedonequipco is null and @oldusedonequipgroup is null and @oldoffsetglco is null and
				@oldusedonequip is null and @oldcomptype is null and @oldcomponent is null and @oldprehourmeter is null and
				@oldcurrhourmeter is null and @oldpreodometer is null and @oldcurrodometer is null and @oldprcrew is null)
			begin
			select @errortext = isnull(@errorstart,'') + ' - all old values must be null for add records!'
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
		End  /* type Adds */

	/* validation specific to Add and Change types of transactions */
	if @batchtranstype in ('A','C')
		BEGIN
		/* validate the equipment and retrieve other important info while we are there */
		select @dept = Department, @catgy = Category, @emem_jcco = JCCo, @emem_job = Job, @emem_emct = UsageCostType,
				@compupdatehrs = CompUpdateHrs, @compupdatemiles = CompUpdateMiles,
				@attachpostrev = AttachPostRevenue
		from bEMEM
		where EMCo = @co and Equipment = @equip and Status in ('A', 'D')
		if @@rowcount <> 1
			begin
			select @errortext = isnull(@errorstart,'') + ' - invalid equipment!'
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto nextseq
			end

		/* validate the category */
		exec @rcode = dbo.bspEMCategoryVal @co, @catgy, @jobflag output, @msg = @errmsg output
		if @rcode <> 0
			begin
			select @errortext = isnull(@errorstart,'') + ' ' + @errmsg
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto nextseq
			end

		/* validate the department */
		if not exists(select * from EMDM where EMCo = @co and isnull(Department,'') = isnull(@dept,''))
			begin
			select @errortext = isnull(@errorstart,'') + ' Department ' + isnull(@dept,'') + ' is invalid on equipment ' + 
			isnull(@equip,'')
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto nextseq
			end

		---- Validate RevCode in EMRR based upon Category of Used/Usage Equipment #128555
		if not exists(select * from EMRR with (nolock) where EMCo=@co and RevCode=@revcode
				and EMGroup=@emgroup and Category=@catgy)
			begin
			select @errortext = isnull(@errorstart,'') + ' Revenue code: ' + isnull(@revcode,'') + ' must be setup in Revenue Rates by Category.'
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto nextseq
			end




            /* validate the form company glco */
            exec dbo.bspGLCompanyVal @glco, @msg = @errmsg output
            if @rcode <> 0
              begin
              select @errortext = isnull(@errorstart,'') + ' ' + @errmsg
              exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              if @rcode <> 0 goto bspexit
              goto nextseq
              end
            
            /* JM 08/02/01 - Ref Issue 14068 - Validate @prco before it's first use in validating Employee. */
            if @prco is not null
              begin
              exec @rcode = dbo.bspPRCompanyVal @prco, @msg = @errmsg output
              if @rcode <> 0
                begin
                select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
              end
          
            /* validate employee */
            if @employee is not null
              begin
              select @switch_a_roo = convert(varchar(15),@employee)
              exec @rcode = dbo.bspPREmplValName @prco, @switch_a_roo, 'Y', @msg = @errmsg output
              if @rcode <> 0
                begin
                select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
              end
          
            /* validate revenue code and/or the job and retrieve some important usage flags */
            exec @rcode = dbo.bspEMUsageFlagsGet @co, @emgroup, @emtranstype, @equip, @catgy, @revcode,@jcco,
                  			   @job, @post_work_units = @post_work_units output, @allow_rate_oride = @allow_rate_oride output,
                  			   @rev_basis = @rev_basis output, @msg=@errmsg output
            if @rcode <> 0
              begin
              select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
              exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              if @rcode <> 0 goto bspexit
              goto nextseq
              end
          
            /* set some basic defaults */
            ----#141031
            if @actualdate is null SET @actualdate = dbo.vfDateOnly()
          
			/* validate fields for line type of Job */
			if @emtranstype = 'J'
				Begin
				/* validate the job info for that piece of equipment when the Restrict To Current Job flag = Y */
				if (@jobflag = 'Y' and @autousage = 'N')and (@jcco <> @emem_jcco or @job <> @emem_job)
					begin
					select @errortext = isnull(@errorstart,'') + 
					' - job information does not match that of the Equipment Master for equipment ' + isnull(@equip,'')
					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto nextseq
					end

				/* validate phase */ -- CMW 08/07/02 added (issue # 18177)
				exec @rcode = dbo.bspJCVPHASE @jcco, @job, @phase, @phasegroup, 'N', @msg = @errmsg output
				if @rcode <> 0
					begin
					select @errortext = isnull(@errorstart,'') + ': ' + 'New Job Cost values, '
					select @errortext = @errortext + 'JCCo ' + isnull(convert(varchar(3), @jcco), '') + ', Job ' + isnull(@job, '')
					select @errortext = @errortext  + ', Phase ' + isnull(@phase, '')
					select @errortext = @errortext + ' - ' + isnull(@errmsg,'')
					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto nextseq
					end

				/* validate the job/phase/costtype with a heavy hitting stored procedure */
				select @switch_a_roo = convert(varchar(5),@jcct)
				exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @switch_a_roo, 'N', @msg = @errmsg output
				if @rcode <> 0
					begin
					select @errortext = isnull(@errorstart,'') + ': ' + 'New Job Cost values, '
					select @errortext = @errortext + 'JCCo ' + isnull(convert(varchar(3), @jcco), '') + ', Job ' + isnull(@job, '')
					select @errortext = @errortext  + ', Phase ' + isnull(@phase, '') + ', CostType' + isnull(convert(varchar(3), @switch_a_roo), '')
					select @errortext = @errortext + ' - ' + isnull(@errmsg,'')
					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto nextseq
					end
   
				-- TV 09/22/05 29478 - Need to validate Cost Code on EM Usage imports, make sure it's set up
				if @costcode is not null
					begin
					update bEMBF set CostCode = null
					where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
					if @@rowcount <> 1
						begin
						select @errortext =  isnull(@errorstart,'') + ' error occurred updating Cost Code.'
						exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						if @rcode <> 0 goto bspexit
						goto nextseq
						end
					end	
				End /* job type line */


            /* validate fields for line type of Equipment */
            if @emtranstype = 'E'
              Begin
              /* validate the expense em company */
              exec @rcode = dbo.bspEMCompanyVal @usedonequipco, @msg = @errmsg output
              if @rcode <> 0
                begin
                select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
          
              /* validate the expense side group */
              select @grp = EMGroup
              from bHQCO
              where HQCo = @usedonequipco
              if @grp <> @usedonequipgroup
                begin
                select @errortext = @errorstart + ' - Equipment group is not set up in HQCO!'
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
              
              /* validate the used on equipment company and the used on equipment */
              exec @rcode = dbo.bspEMEquipVal @usedonequipco, @usedonequip, @msg = @errmsg output
              if @rcode <> 0
                begin
                select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
          
              /* component validation */
              if @comptype is not null or @component is not null
                begin
                /* validate the component type code */
                exec @rcode = dbo.bspEMComponentTypeCodeVal @usedonequipco, @comptype, @component, @equip, @emgroup, @msg = @errmsg output
                if @rcode <> 0
                  begin
                  select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
                  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                  if @rcode <> 0 goto bspexit
                  goto nextseq
               	end
              
                /* validate the component itself */
                exec @rcode = dbo.bspEMComponentVal @usedonequipco, @component, @usedonequip, @emgroup, @msg = @errmsg output
                if @rcode <> 0
                  begin
                  select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
               	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               	if @rcode <> 0 goto bspexit
               	goto nextseq
               	end
                end
          
              /* validate the used on : group, cost code and cost type */
              select @switch_a_roo = convert(varchar(5),@emct)
              exec @rcode = dbo.bspEMCostTypeCostCodeVal @usedonequipgroup, @costcode, @switch_a_roo, @msg = @errmsg output
              if @rcode <> 0
                begin
                select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
              /* end equipment type line */
              End
          
              /* validate fields for line type of Work Order */
              if @emtranstype = 'W'
                Begin
                /* validate the work order */
                exec @rcode = dbo.bspEMWOVal @usedonequipco, @workorder, @msg = @errmsg output
                if @rcode <> 0
                  begin
                  select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
                  exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                  if @rcode <> 0 goto bspexit
                  goto nextseq
                  end
          
                /* validate the work order item */
                exec @rcode = dbo.bspEMWOItemVal @usedonequipco, @workorder, @woitem, @msg = @errmsg output
                if @rcode <> 0
                  begin
                  select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
               	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               	if @rcode <> 0 goto bspexit
               	goto nextseq
                  end

				/* validate that work order equipment components are not set to Inactive */
				if exists(select top 1 1 from bEMRD e join bEMEM r on e.UsedOnEquipCo = r.EMCo 
					and e.UsedOnComponent = r.Equipment and e.WOItem = @woitem and r.Status = 'I')
					begin
						select @errortext = @errorstart + ' - Work order item equipment is Inactive!'
						exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						if @rcode <> 0 goto bspexit
						goto nextseq
					end
 
                /* validate the used on : group, cost code and cost type */
                select @switch_a_roo = convert(varchar(5),@emct)
                exec @rcode = dbo.bspEMCostTypeCostCodeVal @usedonequipgroup, @costcode, @switch_a_roo, @msg = @errmsg output
                if @rcode <> 0
                  begin
                  select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
               	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               	if @rcode <> 0 goto bspexit
               	goto nextseq
                  end
               /* end work order field validation */
               End
          
               /* validate fields for line type of Expense */
               /* the off set account must be present on an expense type because there is no where for us to get one otherwise */
               if @emtranstype = 'X' and @offsetacct is null
                 begin
                 select @errortext = isnull(@errorstart,'') + ' - missing gl offset account!'
                 exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                 if @rcode <> 0 goto bspexit
                 goto nextseq
           end
          
            /* GENERAL NON-LINETYPE VALIDATION */
            /* get intercompany gl accounts */
            /* first set default xglco to formCo glco */
            select @xglco = @glco
          
            if @emtranstype in ('E','W') and @co <> @usedonequipco select @xglco = @offsetglco
          
            if @emtranstype = 'J'
            begin
				select @jcco_glco = GLCo   from bJCCO where JCCo = @jcco
				if @jcco_glco is null
                begin
					select @errortext = isnull(@errorstart,'') + '- gl company missing from job cost company ' + 
					isnull(convert(char(2),@jcco),'') + ' !'
					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					
					if @rcode <> 0 goto bspexit
				 
					goto nextseq
   
                end
              select @xglco = @jcco_glco
             end
          
            /* if the line is cross company, get the inter company accounts */
            if @glco <> @xglco
            begin
          
                /* validate the expense GLCo */
                select @lastmthsubclsd = null
                select @lastmthsubclsd = LastMthSubClsd
                from bGLCO
                where GLCo = @xglco
          
                if @mth <= @lastmthsubclsd
                  begin
                  select @errortext = isnull(@errorstart,'') + ' Month is closed in GL Company ' + 
                  isnull(convert(varchar(3),@xglco),'')
               	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               	if @rcode <> 0 goto bspexit
               	goto nextseq
                  end
          
              select @arglacct = ARGLAcct, @apglacct = APGLAcct
              from bGLIA
              where ARGLCo = @glco and APGLCo = @xglco
              if @arglacct is null or @apglacct is null
                begin
                select @errortext = isnull(@errorstart,'') + '- Missing cross company gl account(s) !'
    
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
              end
          
            /* Search for the proper offset account if nothing had been entered in EMBF.
               If auto GL is set to yes then the account was not sought after during user entry because this routine
               would do it anyway */
            if @offsetacct is null or
               @batchtranstype = 'C' and (@jcco <> @oldjcco or @job <> @oldjob or @jcct <> @oldjcct or @phase <> @oldphase or
            			      	@usedonequipco <> @oldusedonequipco or @usedonequip <> @oldusedonequip or
            			      	@costcode <> @oldcostcode or @emct <> @oldemct)
              begin
              exec @rcode = dbo.bspEMUsageGlacctDflt @co, @emgroup, @emtranstype, @jcco, @job, @phase, @jcct,
               	                               @usedonequipco, @usedonequip, @costcode, @emct,
               	                               @glacct = @offsetacct output, @msg = @errmsg output
              if @offsetacct is null
                begin
                select @errortext = isnull(@errorstart,'') + 
                ' - no offset account is set up in the EM or JC department form for revenue code ' + 
                isnull(@revcode,'') + ' or job ' + isnull(@job,'') + ' !'
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
              end
          
            /* validate the offset gl account */
             /*Issue 133140*/
            select @parameter = case @emtranstype when 'J' then 'J' else 'E' end
            exec @rcode = dbo.bspGLACfPostable @xglco, @offsetacct, @parameter, @errmsg output
            if @rcode <> 0
              begin
              select @errortext = isnull(@errorstart,'') + ' - '  + @errmsg
              exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              if @rcode <> 0 goto bspexit
              goto nextseq
              end
          
            /**************************************************************************************************
             * get the revenue acct(s) for EMGL based on the department revenue code or revenue bdown code(s) *
             * insert into EMBC any revbdowncode accts for a given entry.                                     *
             * revbdownval also inflates or deflates the bdown rates if the standard rate was overridden      *
             *************************************************************************************************/
            select @transacct = null
            select @transacct = GLAcct
            from bEMDR
            where EMCo = @co and EMGroup = @emgroup and isnull(Department,'') = isnull(@dept,'') and RevCode = @revcode
            if @transacct is not null
              begin
			 /*Issue 135745*/
              exec @rcode = dbo.bspGLACfPostable @glco, @transacct, 'E', @errmsg output
              if @rcode <> 0
                begin
                select @errortext = isnull(@errorstart,'') + ' - ' + isnull(@errmsg,'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
          	end
 
			/* update EMBF with the transacct based on the revenue code in EMDR so that we can update EMRD and JCCD */
			---- TV 10/11/05 - 29989 always update with Dept Revenue Account
			update bEMBF set GLTransAcct = @transacct
			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
			if @@rowcount <> 1
				begin
				select @errortext =  isnull(@errorstart,'') + ' error occurred updating GL Transaction Account.'
				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto nextseq
				end
              
          
            /* build the EMBC table for EMRB distirbutions and, potentially, GLDT distirbution */
            /* if a problem occurs in this bsp it will be written to the hqbe table within */
            select @parameter = case when isnull(@transacct,'') = '' then 'Y' else 'N' end
            exec @rcode = dbo.bspEMBFRevBdownVal @co, @emgroup, @batchid, @seq, @mth, @dept, @revcode, @equip, @catgy, @jcco, @job,
            				   @emtranstype, @revrate, 1, @parameter,
							   ----TK-20836
							   0, @emtrans, @errmsg = @errmsg output
            if @rcode <> 0
              begin
              select @rcode = 0
              goto nextseq
              end
          
            /* validate Units of Measure */
            /* unit based requirements */
            if @rev_basis = 'U'
              begin
              if @workum is null
                begin
                select @errortext = isnull(@errorstart,'') + ' - Work unit of measure required!'
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
              select @jc_timeunits = @revtimeunits
              end
          
            /* hour based requirements */
            if @rev_basis = 'H'
              begin
              if @timeum is null
                begin
                select @errortext = isnull(@errorstart,'') + ' - Time unit of measure required!'
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
          
              /* convert time unit of measure into hours for job cost and hour meter update */
              select @hrsfactor = HrsPerTimeUM
              from bEMRC
              where EMGroup = @emgroup and RevCode = @revcode
              select @jc_timeunits = @revtimeunits * @hrsfactor
              end
          
            if @workum is not null
              begin
              exec @rcode = dbo.bspHQUMVal @workum, @errmsg output
              if @rcode <> 0
                begin
                select @errortext = isnull(@errorstart,'') + ' ' + isnull(@workum,'') + ': ' + isnull(@errmsg,'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
              end
          
            if @timeum is not null
              begin
              exec @rcode = dbo.bspHQUMVal @timeum, @msg = @errmsg output
              if @rcode <> 0
                begin
                select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
          
                goto nextseq
                end
              end
            /* end type Add of Change type lines */
            END
          
          /* BEGIN the Change or Delete batch type lines */
          if @batchtranstype in ('C','D')
            BEGIN
            /* get 'old' dept and 'old' category based on the current settings of @oldequip */
            select @olddept = Department, @oldcatgy = Category
            from bEMEM
            where EMCo = @co and Equipment = @oldequip
          
   
            /* get old xglco */
            select @old_xglco = @oldglco
          
            if @emtranstype in ('E','W') and @co <> @oldusedonequipco select @old_xglco = @oldoffsetglco
          
        
			if @emtranstype = 'J'
				begin
				select @jcco_glco = GLCo
				from bJCCO
				where JCCo = @oldjcco
				if @jcco_glco is null
					begin
					select @errortext = isnull(@errorstart,'') + 
					'- gl company missing from old job cost company ' + isnull(convert(char(3),@oldjcco),'') + ' !'
					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto nextseq
					end
				select @old_xglco = @jcco_glco
			    
				-- TV 08/15/05 28474- EM Usage Post: Cannot enter Cost Detail/ trigger error Inactive Cost Type
				if (@jcco <> @oldjcco or @job <> @oldjob or @phase <> @oldphase or @jcct <> @oldjcct)
					begin
					exec @rcode = dbo.bspJCVPHASE @oldjcco, @oldjob, @oldphase, @oldphasegroup, 'N', @msg = @errmsg output
					if @rcode <> 0
						begin
						select @errortext = isnull(@errorstart,'') + ': ' + 'Old Job Cost values, '
						select @errortext = @errortext + 'JCCo ' + isnull(convert(varchar(3), @oldjcco), '') + ', Job ' + isnull(@oldjob, '')
						select @errortext = @errortext  + ', Phase ' + isnull(@oldphase, '')
						select @errortext = @errortext + ' - ' + isnull(@errmsg,'')
						exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						if @rcode <> 0 goto bspexit
						goto nextseq
						end
					end

					select @switch_a_roo = convert(varchar(5),@oldjcct)
					exec @rcode = dbo.bspJCVCOSTTYPE @oldjcco, @oldjob, @oldphasegroup, @oldphase, @switch_a_roo, 'N', @msg = @errmsg output
					if @rcode <> 0
						begin
						select @errortext = isnull(@errorstart,'') + ': ' + 'Old Job Cost values, '
						select @errortext = @errortext + 'JCCo ' + isnull(convert(varchar(3), @oldjcco), '') + ', Job ' + isnull(@oldjob, '')
						select @errortext = @errortext  + ', Phase ' + isnull(@oldphase, '') + ', CostType' + isnull(convert(varchar(3), @switch_a_roo), '')
						select @errortext = @errortext + ' - ' + isnull(@errmsg,'')
						exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						if @rcode <> 0 goto bspexit
						goto nextseq
						end
					end
          
            if @oldglco <> @old_xglco
              Begin
              /* validate the old expense GLCo */
              select @lastmthsubclsd = null
              select @lastmthsubclsd = LastMthSubClsd
              from bGLCO
              where GLCo = @old_xglco
          
              if @mth <= @lastmthsubclsd
                begin
                select @errortext = isnull(@errorstart,'') + ' Month is closed in the old GL Company ' + 
                isnull(convert(varchar(3),@old_xglco),'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
          
              select @arglacct = ARGLAcct, @apglacct = APGLAcct
              from bGLIA
              where ARGLCo = @oldglco and APGLCo = @old_xglco
              if @arglacct is null or @apglacct is null
                begin
                select @errortext = isnull(@errorstart,'') + '- Missing old cross company gl account(s) !'
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
          
              End
          
            /* get old revenue basis & old jc_timeunits,
               they really should not be changing a revcode basis or the hours conversion factor. if they do..... */
            select @oldrev_basis = Basis
            from bEMRC
            where EMGroup = @oldemgroup and RevCode = @oldrevcode
            if @oldrev_basis is null
                begin
         
                select @errortext = isnull(@errorstart,'') + ' - The old transactions revenue code: ' + 
                isnull(@oldrevcode,'') + ' no longer exists!'
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
          
            if @oldrev_basis = 'U' select @oldjc_timeunits = @oldrevtimeunits
            if @oldrev_basis = 'H'
                begin
                select @oldhrsfactor = HrsPerTimeUM
                from bEMRC
                where EMGroup = @oldemgroup and RevCode = @oldrevcode
                select @oldjc_timeunits = @oldrevtimeunits * @oldhrsfactor
                end
          
            /* get the revenue acct(s) for EMGL based on the old department revenue code or revenue bdown code(s) */
            /* insert into EMBC any revbdowncode accts for a given entry.
               revbdownval also inflates or deflates the bdown rates if the standard rate was overridden */
            select @oldtransacct = GLAcct
            from bEMDR
            where EMCo = @co and EMGroup = @oldemgroup and isnull(Department,'') = isnull(@olddept,'') and RevCode = @oldrevcode
            if @oldtransacct is not null
              begin
              exec @rcode = dbo.bspGLACfPostable @glco, @oldtransacct, 'E', @errmsg output
              if @rcode <> 0
                begin
                select @errortext = isnull(@errorstart,'') + ' - ' + isnull(@errmsg,'')
                exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto nextseq
                end
          	end

			/* update EMBF with the oldtransacct based on the old revenue code in EMDR so that we can update EMRD and JCCD */
			update bEMBF set OldGLTransAcct = @oldtransacct
			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
			if @@rowcount <> 1
				begin
				select @errortext =  isnull(@errorstart,'') + ' error occurred updating Old GL Transaction Account.'
				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto nextseq
				end

            /* build the EMBC table for EMRB distirbutions and, potentially, GLDT distirbution */
            /* if a problem occurs in this bsp it will be written to the hqbe table within */
            select @parameter = case when @oldtransacct is null then 'Y' else 'N' end
            exec @rcode = dbo.bspEMBFRevBdownVal @co, @oldemgroup, @batchid, @seq, @mth, @olddept, @oldrevcode, @oldequip,
          				   @oldcatgy, @oldjcco, @oldjob, @oldemtranstype, @oldrevrate, 0, @parameter,
						   ----TK-20836
						   @oldrevdollars, @emtrans, @errmsg = @errmsg output
            if @rcode <> 0
              begin
              select @rcode = 0
              goto nextseq
              END
           
            /* end change & delete code */
            END
          
          /* validation specific for Deletion of a transaction */
          if @batchtranstype = 'D'
            BEGIN
            select @itemcount = count(*)
            from bEMRD
            where EMCo=@co and Mth=@mth and Trans=@emtrans
            select @deletecount= count(*)
            from bEMBF
            where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and BatchTransType='D'
            if @itemcount <> @deletecount
              begin
              select @errortext = isnull(@errorstart,'') + 
              ' - In order to delete a transaction all entries must be in the current batch and marked for delete! '
              exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              if @rcode <> 0 goto bspexit
              end
          
            select @deletecount= count(*)
            from bEMBF
            where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and BatchTransType<>'D'
            if  @deletecount  <> 0
              begin
              select @errortext = isnull(@errorstart,'') + 
              ' - In order to delete a transaction you cannot have any Add or Change lines! '
              exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
              if @rcode <> 0 goto bspexit
              end
          
            END /*Delete */
          
          /* update EMGL and if neccessary, EMJC */
          update_audit:
          
          /*JC distributions */
          /* first back out any old entry */
          select @changed = 'N'
          if @oldemtranstype = 'J'
            begin
            /* skip jc update on a change type transaction if nothing did indeed change */
            if @batchtranstype = 'C' and (isnull(@jcco,0) <> isnull(@oldjcco,0) or isnull(@job,'') <> isnull(@oldjob,'') or
               isnull(@phasegroup,0) <> isnull(@oldphasegroup,0) or isnull(@phase,'') <> isnull(@oldphase,'') or
               isnull(@jcct,0) <> isnull(@oldjcct,0) or isnull(@equip,'') <> isnull(@oldequip,'') or isnull(@emgroup,0) <> isnull(@oldemgroup,0) or
               isnull(@revcode,0) <> isnull(@oldrevcode,0) or isnull(@oldglco,0) <> isnull(@jcco_glco,0) or
               isnull(@offsetacct,'') <> isnull(@oldoffsetacct,'') or isnull(@prco,0) <> isnull(@oldprco,0) or
               isnull(@employee,'') <> isnull(@oldemployee,0) or isnull(@workum,'') <> isnull(@oldworkum,'') or
               isnull(@revworkunits,0) <> isnull(@oldrevworkunits,0) or isnull(@timeum,'') <> isnull(@oldtimeum,'') or
               isnull(@revtimeunits,0) <> isnull(@oldrevtimeunits,0) or-- TV 08/03/04 25252 - needed to compare new vs old
               isnull(@revdollars,0) <> isnull(@oldrevdollars,0) or isnull(@actualdate,'') <> isnull(@oldactualdate,'')) select @changed = 'Y'
          
            if @batchtranstype = 'D' or @changed = 'Y'
              begin
              if @oldrevdollars <> 0 or
                 (((case @oldtrackhours when 'Y' then isnull(@oldjc_timeunits,0) else 0 end) <> 0) or
                 --(@rev_basis = 'U' and @oldrevworkunits <> 0))
          		(@oldrevworkunits <> 0))
         
                begin
                insert into bEMJC (EMCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
                                   OldNew, Equipment, TransDesc, ActualDate, EMGroup, RevCode, GLCo, GLAcct, PRCo, PREmployee,
              		         WorkUM, WorkUnits, TimeUM, TimeUnits,
                                   UnitCost, TotalCost,PRCrew)
                values (@co, @mth, @batchid, @oldjcco, @oldjob, @oldphasegroup, @oldphase, @oldjcct, @seq,
           	      0, @oldequip, 'Equipment Usage', @oldactualdate, @emgroup, @oldrevcode, @old_xglco, @oldoffsetacct, @oldprco, @oldemployee,
           	      @oldworkum, -1*@oldrevworkunits, @oldtimeum, case @oldtrackhours when 'Y' then -1 * isnull(@oldjc_timeunits,0) else 0 end,
                        0, -1 * @oldrevdollars, @prcrew)
                end
              end
            end
          
          if @emtranstype = 'J' and (@batchtranstype = 'A' or @changed = 'Y')
            begin
            /* insert new entry */
            if @revdollars <> 0 or 
               (((case @trackhours when 'Y' then isnull(@jc_timeunits,0) else 0 end) <> 0) or
                --(@rev_basis = 'U' and @revworkunits <> 0))
         		(@revworkunits <> 0))
              
              begin
              insert into bEMJC (EMCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
              		       OldNew, Equipment, TransDesc, ActualDate, EMGroup, RevCode, GLCo, GLAcct, PRCo, PREmployee,
              		       WorkUM, WorkUnits, TimeUM, TimeUnits,
                                 UnitCost, TotalCost, PRCrew)
           	values (@co, @mth, @batchid, @jcco, @job, @phasegroup, @phase, @jcct, @seq,
           	       	1, @equip, 'Equipment Usage', @actualdate, @emgroup, @revcode, @xglco,  @offsetacct, @prco, @employee,
           		@workum, @revworkunits, @timeum, case @trackhours when 'Y' then isnull(@jc_timeunits,0) else 0 end,
                          0, @revdollars, @prcrew)
              end
            /* end JC distributions */
            end
          
          
          /* begin gl distributions */
          if @batchtranstype <> 'A'  /* do old entries */
            BEGIN
            if @old_xglco = @oldglco select @cycle = 3 else select @cycle = 1
          /* do gl distributions */
            while @cycle < 5
              Begin
              /* cycle 1.  debit cross company ap account */
              if @cycle = 1 select @distglco = @old_xglco, @distglacct = @apglacct, @distamt = @oldrevdollars, @distequip = @oldequip
              
              /* cycle 2.  credit cross company ar account */
              if @cycle = 2
                begin
                select @distglco = @oldglco, @distglacct = @arglacct, @distamt = -1 *@oldrevdollars,
                			 @distequip = case @emtranstype when 'E' then @oldusedonequip else @oldequip end
                end
          
/* cycle 3.  debit revenue account */     
if @cycle = 3
	Begin
	if @oldtransacct is not null
		begin
		select @distglco = @oldglco, @distglacct = @oldtransacct, @distamt = @oldrevdollars, @distequip = @oldequip
		end
	else
		/* Bdownrate is not updated in EMBC from old records since the previous transaction that was sent to
		EMRB is to be deleted after which the new transactions value is freshly inserted.
		An adjustment to the amount only happens in this section if the GL is influenced by the
		breakdown codes in lieu of the rev codes. */
		----TK-20836 ONLY REMMED OUT OLD CODE IN CASE PROBLEM ARISE
		BEGIN
		SET @save_bdown_code = null
		select @revbdowncode = min(RevBdownCode)
		from dbo.bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and OldNew = 0
		while @revbdowncode is not null
			BEGIN
			---- get revenue breakdown info          
			SELECT  @distglco	= GLCo,
					@distglacct = Account,
					@distamt	= BdownRate,
					@distequip	= Equipment
			FROM dbo.bEMBC
			WHERE EMCo = @co 
				AND Mth = @mth
				AND BatchId = @batchid
				AND BatchSeq = @seq
				AND RevBdownCode = @revbdowncode
				AND OldNew = 0  
			
			---- TFS-46093 for old entries may be null set to old values
			IF @distglco IS NULL SET @distglco = @oldglco
			IF @distglacct IS NULL SET @distglacct = @oldtransacct

			---- update EMGL distributions for old revenue breakdown
			UPDATE dbo.bEMGL SET Amount = Amount + -(@distamt)
			WHERE EMCo = @co
				AND Mth = @mth
				AND BatchId = @batchid
				AND GLCo = @distglco
				AND GLAcct = @distglacct
				AND BatchSeq = @seq
				AND OldNew = 0
			IF @@ROWCOUNT = 0
				BEGIN
                ---- if no update occured, insert the new record
				INSERT INTO dbo.bEMGL(EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, EMTrans, Equipment,
						ActualDate, Source, EMTransType, JCCo, Job, EMGroup, RevCode,
						RevBdownCode, WorkOrder, WOItem, Amount)
				SELECT @co, @mth, @batchid, @distglco, @distglacct, @seq, 0, @emtrans, @distequip,
						@oldactualdate, @source, @emtranstype, @oldjcco, @oldjob, @oldemgroup, @oldrevcode,
						@revbdowncode, @oldworkorder, @oldwoitem, -(@distamt)
				FROM dbo.bEMBC EMBC
				WHERE EMBC.EMCo = @co
					AND EMBC.Mth = @mth
					AND EMBC.BatchId = @batchid
					AND EMBC.BatchSeq = @seq
					and EMBC.RevBdownCode = @revbdowncode
					AND EMBC.OldNew = 0
				END

			---- save rev breakdown code
			SET @save_bdown_code = @revbdowncode

			SELECT @revbdowncode = min(RevBdownCode)
			from dbo.bEMBC WHERE EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
				AND OldNew = 0 and RevBdownCode > @revbdowncode
			END    /* end while loop */

			----TV 3/11/04 22518 - If user is applying TotalOnly (with no units) then rev Dollars should be used
		--	if (@oldrev_basis = 'H' and  @oldrevtimeunits <> 0) or (@oldrev_basis = 'U' and  @oldrevworkunits <> 0)
		--		begin
		--		select @distglco = GLCo, @distglacct = Account,
		--				@distamt = BdownRate * -(case @oldrev_basis when 'H' then @oldrevtimeunits else @oldrevworkunits end),
		--				@distequip = Equipment
		--		from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
		--		and RevBdownCode = @revbdowncode and OldNew = 0
		--		end
		--	else
		--		begin
		--		select @distglco = GLCo, @distglacct = Account, @distamt = (@oldrevdollars), @distequip = Equipment
		--		from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
		--		and RevBdownCode = @revbdowncode and OldNew = 0
		--		end

		--	/* change the EMBC rate right here so that the amount going over to EMRB is properly adjusted */
		--	/* also need to switch the sign back on an update from here on EMBC */
		--	update bEMBC set BdownRate = -(@distamt)
		--	where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
		--	and OldNew = 0 and RevBdownCode = @revbdowncode
		--	if @@rowcount <> 1
		--		begin
		--		select @errortext =  isnull(@errorstart,'') + ' error occurred updating Breakdown rate.'
		--		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		--		if @rcode <> 0 goto bspexit
		--		goto nextseq
		--		end

		--	select @distglco = GLCo, @distglacct = Account, @distamt = (@oldrevdollars), @distequip = Equipment
		--	from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
		--	and RevBdownCode = @revbdowncode and OldNew = 0

		--	if @distamt <> 0
		--		begin
		--		update bEMGL set Amount  = Amount + @distamt
		--		where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @distglco
		--		and GLAcct = @distglacct and BatchSeq = @seq and OldNew = 0
		--		/* if no update occured, insert the new record */
		--		if @@rowcount = 0
		--			begin
		--			insert into bEMGL(EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, EMTrans, Equipment, ActualDate, Source, EMTransType,
		--					JCCo, Job, EMGroup, RevCode, RevBdownCode, WorkOrder, WOItem, Amount)
		--			values(@co, @mth, @batchid, @distglco, @distglacct, @seq, 0, @emtrans, @distequip, @oldactualdate, @source, @emtranstype,
		--					@oldjcco, @oldjob, @oldemgroup, @oldrevcode, @revbdowncode, @oldworkorder, @oldwoitem, @distamt)
		--			end
		--		end

		--	-- save rev breakdown code
		--	select @save_bdown_code = @revbdowncode

		--	select @revbdowncode = min(RevBdownCode)
		--	from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and
		--	OldNew = 0 and RevBdownCode > @revbdowncode
		--	end    /* end while loop */

		--/* Need to make sure that old rev dollars is equal to old total rev breakdown amounts */
		--select @total_Bdown_dist = isnull(sum(BdownRate),0)
		--from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and OldNew = 0
		--if @@rowcount <> 0 ----HACK
		--	begin
		--	if @save_bdown_code is not null and @total_Bdown_dist <> -1 * @oldrevdollars 
		--		begin
		--		select @diff = 0
		--		select @diff = @oldrevdollars + @total_Bdown_dist

		--		update bEMBC set BdownRate = BdownRate - @diff
		--		where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
		--		and OldNew = 0 and RevBdownCode = @save_bdown_code  --should be the last bdown code from the above psuedo-cursor
		--		if @@rowcount <> 1
		--			begin
		--			select @errortext =  isnull(@errorstart,'') + ' error occurred updating Breakdonw rate.'
		--			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		--			if @rcode <> 0 goto bspexit
		--			goto nextseq
		--			end

		--		update bEMGL set Amount  = Amount + @diff
		--		where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @distglco
		--		and GLAcct = @distglacct and BatchSeq = @seq and OldNew = 0  --@diff is added to EMGL which is differnet than the update to EMBC
		--		if @@rowcount <> 1
		--			begin
		--			select @errortext =  isnull(@errorstart,'') + ' error occurred updating Amount for distribution GL account.' + ' <> A'
		--			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		--			if @rcode <> 0 goto bspexit
		--			goto nextseq
		--			end
		--		end
		--	end

		/* If the code fell into this section, GL has already been updated.  Increment now. */
		goto old_increment
		end
	End    /* end cycle 3 */

	/* cycle 4.  credit the offset account */
	if @cycle = 4
		begin
		select @distglco = @old_xglco, @distglacct = @oldoffsetacct, @distamt = -1 * @oldrevdollars,
		@distequip = case @emtranstype when 'E' then @oldusedonequip else @oldequip end
		end

	/* first try an update in case a record already exists */
	update bEMGL
	set Amount  = Amount + @distamt
	where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @distglco and GLAcct = @distglacct
	and BatchSeq = @seq and RevCode = @oldrevcode and OldNew = 0
	/* if no update occured, insert the new record */
	if @@rowcount = 0
		begin
		insert into bEMGL(EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, Equipment, ActualDate, Source, EMTransType,
			JCCo, Job, EMGroup, CostCode, EMCostType, RevCode, Amount)
		values(@co, @mth, @batchid, @distglco, @distglacct, @seq, 0, @distequip, @actualdate, @source, @emtranstype,
			@oldjcco, @oldjob, @oldemgroup, @oldcostcode, @oldemct, @oldrevcode, @distamt)
		end

	old_increment:
	select @cycle = @cycle + 1
	End /* while gl dist loop */

END /* audit type <> A */

if @batchtranstype <> 'D'  /* do new entries */
	BEGIN
	if @xglco = @glco select @cycle = 3 else select @cycle = 1
	/* do gl distributions */
	while @cycle < 5
		Begin
		/* cycle 1.  credit cross company ap account */
		if @cycle = 1 select @distglco = @xglco, @distglacct = @apglacct, @distamt = -1 * @revdollars, @distequip = @equip

		/* cycle 2.  debit cross company ar account */
		if @cycle = 2
			begin
			select @distglco = @glco, @distglacct = @arglacct, @distamt = @revdollars,
			@distequip = case @emtranstype when 'E' then @usedonequip else @equip end
			end

		/* cycle 3.  credit revenue account */
		if @cycle = 3
			BEGIN
			/* if transacct is null then post to GL at the rev breakdown code level.
			Even if gl is not to be updated by revenue breakdown codes, this code must be executed so that the
			update to EMRB is accurate */

			select @save_bdown_code = null

			select @revbdowncode = min(RevBdownCode)
			from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and OldNew = 1
			while @revbdowncode is not null
				begin
				----TV 3/11/04 22518 - If user is applying TotalOnly (with no units) then rev Dollars should be used	
				if (@rev_basis = 'H' and  @revtimeunits <> 0) or (@rev_basis = 'U' and  @revworkunits <> 0)
					begin
					select @distglco = GLCo, @distglacct = Account,
							@distamt = BdownRate * -(case @rev_basis when 'H' then @revtimeunits else @revworkunits end),
							@distequip = Equipment
					from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
					and OldNew = 1 and RevBdownCode = @revbdowncode
					end
				else
					begin
					select @distglco = GLCo, @distglacct = Account, @distamt =  - (@revdollars), @distequip = Equipment
					from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
					and OldNew = 1 and RevBdownCode = @revbdowncode
					end

				/* change the EMBC rate right here so that the amount going over to EMRB is properly adjusted */
				/* also need to switch the sign back on an update from here on EMBC */
				update bEMBC set BdownRate = -(@distamt)
				where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
				and OldNew = 1 and RevBdownCode = @revbdowncode
				if @@rowcount <> 1
					begin
					select @errortext =  isnull(@errorstart,'') + ' error occurred updating breakdown rate.'
					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto nextseq
					end

			/* if the transacct is not null then gl dist. will be driven by the revenue codes.
			otherwise gl distribution will be driven by revenue breakdown codes */
			--Do not remove @transacct from this statement.  It needs to be here and nowhere else.
			if @distamt <> 0 and @transacct is null  
				begin
				update bEMGL set Amount  = Amount + @distamt
				where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @distglco
				and GLAcct = @distglacct and BatchSeq = @seq and OldNew = 1
				if @@rowcount = 0
					begin
					insert into bEMGL(EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, Equipment, ActualDate, Source, EMTransType,
						JCCo, Job, EMGroup, RevCode, RevBdownCode, WorkOrder, WOItem, Amount)
					values(@co, @mth, @batchid, @distglco, @distglacct, @seq, 1, @distequip, @actualdate, @source, @emtranstype,
						@jcco, @job, @emgroup, @revcode, @revbdowncode, @workorder, @woitem, @distamt)
					end
				end  /* emgl update or insert */

			select @save_bdown_code = @revbdowncode

			select @revbdowncode = min(RevBdownCode)
			from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
			and OldNew = 1 and RevBdownCode > @revbdowncode
			end  /* end while loop */

		/* Need to make sure that rev dollars is equal to total rev breakdown amounts */
		select @total_Bdown_dist = isnull(sum(BdownRate),0)
		from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and OldNew = 1
		IF @@rowcount <> 0 ----HACK
			begin
			if @save_bdown_code is not null and @total_Bdown_dist <> @revdollars 
				begin
				select @diff = 0
				select @diff = @revdollars - @total_Bdown_dist  --subtract these two from each other on new transactions

				update bEMBC set BdownRate = BdownRate + @diff
				where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
				and OldNew = 1 and RevBdownCode = @save_bdown_code  --should be the last bdown code from the above psuedo-cursor
				if @@rowcount <> 1
					begin
					select @errortext =  isnull(@errorstart,'') + ' error occurred updating Breakdown Rate.'
					exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto nextseq
					end

				if @transacct is null ---- issue #128793
					begin
					update bEMGL set Amount  = Amount - @diff  --@diff is subtracted out of EMGL which is differnet than the update to EMBC
					where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @distglco
					and GLAcct = @distglacct and BatchSeq = @seq and OldNew = 1
					---- #129385 if unable to update distglacct do not throw error
----					if @@rowcount <> 1
----						begin
----						select @errortext =  isnull(@errorstart,'') + ' error occurred updating Amount for distribution GL Account.'
----						exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
----						if @rcode <> 0 goto bspexit
----						goto nextseq
----						end
					end
				end
			end

		If @transacct is not null  -- do not move this code to the top of Cycle 3.  It needs to be right here.
			/* Override BreakDown Code GL Accounts with Revenue Code GL Accounts and amount.
			This code must come after the above RevBreakDown section or EMRB will be incorrect ! */
			begin
			select @distglco = @glco, @distglacct = @transacct, @distamt = - 1 * @revdollars, @distequip = @equip
			end
		Else
			begin        
			goto increment
			end
		END    /* end cycle 3 */

	/* cycle 4.  debit the offset account */
	if @cycle = 4
		begin
		select @distglco = @xglco, @distglacct = @offsetacct, @distamt = @revdollars,
		@distequip = case @emtranstype when 'E' then @usedonequip else @equip end
		end

	if @distamt <> 0
		begin
        /* first try an update in case a record already exists */
        update bEMGL set Amount  = Amount + @distamt
        where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @distglco and GLAcct = @distglacct
		and BatchSeq = @seq and RevCode = @revcode and OldNew = 1
        /* if no update occured, insert the new record */
        if @@rowcount = 0
			begin
			insert into bEMGL(EMCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, Equipment, ActualDate, Source, EMTransType,
					JCCo, Job, EMGroup, CostCode, EMCostType, RevCode, WorkOrder, WOItem, Amount)
			values(@co, @mth, @batchid, @distglco, @distglacct, @seq, 1, @distequip, @actualdate, @source, @emtranstype,
					@jcco, @job, @emgroup, @costcode, @emct, @revcode, @workorder, @woitem, @distamt)
			end
        end

	increment:
	select @cycle = @cycle + 1
	End /* while gl dist loop */
  
    END /* audit type <> D */
          
	nextseq:
	goto get_next_bcEMBF

END /*EMBF LOOP*/

close bcEMBF
deallocate bcEMBF
select @opencursorEMBF=0
          
-- make sure debits and credits balance
select @glco = GLCo
from bEMGL

where EMCo = @co and Mth = @mth and BatchId = @batchid
group by GLCo
having isnull(sum(Amount),0) <> 0
if @@rowcount <> 0
	begin
	select @errortext =  'GL Company ' + isnull(convert(varchar(3), @glco),'') + ' entries dont balance!'
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end






bspexit:
	---- check HQ Batch Errors and update HQ Batch Control status
	select @status = 3	/* valid - ok to post */
	if exists(select * from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
	select @status = 2	/* validation errors */
	update bHQBC set Status = @status
	where Co = @co and Mth = @mth and BatchId = @batchid
	if @@rowcount <> 1
		begin
		select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
		goto bspexit
		end

	if @opencursorEMBF = 1
		begin
		close bcEMBF
		deallocate bcEMBF
		end

	return @rcode






GO

GRANT EXECUTE ON  [dbo].[bspEMBFVal_Usage] TO [public]
GO
