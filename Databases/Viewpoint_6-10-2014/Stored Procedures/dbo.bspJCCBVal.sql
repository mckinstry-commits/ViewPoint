SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************/
CREATE procedure [dbo].[bspJCCBVal]
/***********************************************************
* CREATED BY:	SE 12/03/96
* MODIFIED By:	SE 1/16/97
*				GH 03/10/99 Corrected a few problems with nulls.  Getting the messages
*					'Debit account and credit account cannot be the same' when they were both blank
*					and 'Debit and credit entries are out of balance by' which was a blank amount.
*				JRE 06/14/99	- Allow to change the type of transaction, report correct trans type
*				DANF 03/14/00	- Added validation for closed jobs
*				DANF 03/20/00	- Added Inventory Validation
*				DANF 05/23/00	- Added Source
*				DANF 08/24/00	- Allow accounts to wash.
*				DANF 02/24/01	- Correct Tax Cost Type validation and Tax Gl account Distribution
*								- for 'JC Mat Use' and Trans type 'mi'
*				DANF 03/06/01	- Allow Cost Adjustment accounts to wash
*				TV   03/09/01	- Validate GLCostJournal
*				DANF 03/20/00	- Added Update to new TaxPhase and TaxCostType column & Update of Pst Units
*				ALLENN 04/25/01 - Added Material column for each insert to bJCDA table, either @material or @oldmaterial   (issue#13150)
*				DANF 01/17/02	- Validate Unit of measure to JCCH #15869
*				DANF 01/17/02	- Correct Posted ECM and Unit Cost for Source = JC CostAdj
*				DANF 03/15/02	- Updated UM for JC Mat Use posting if null from JCCH UM.
*				DANF 04/01/02	- Added InterCompany Cost Entries.
*				DANF 06/11/02	- Corrected check for account in balance by GL Company.
*				SR 06/26/02		- issue 17704 - can't insert null errors when chaning Matl Use from IN to MI and visa versa
*				SR 07/08/02		- issue 17738 - pass in @PhaseGroup and @oldPhaseGroup to bspJCVPHASE
*								& bspJCVCOSTTYPE
*				SR 07/29/02		- issue 18074 - make sure ActualDate is not null so it won't stop posting in progress
*				DANF 09/05/02	- 17738 Add phase group to bspJCCAGlacctDflt & bspJCCBValInv
*				DANF 10/18/02	- Corrected GL distribution on IN transactions.
*				RBT 08/21/03	- #21582, add parameter in exec call to bspJCJMPostVal.
*				TV				- 23061 added isnulls
*				DANF 06/28/04	- #24669 Corrected Validation of GL Offset Account for Inventory transactions.
*				DANF 09/07/04	- #25411 Correct validation of the old tax accounts
*				DANF 09/08/04	- #24102 Incorrect GL distribution when deleting transactions with tax
*				DANF 03/15/05	- #27294 - Remove scrollable cursor.
*				DANF 03/13/2005 - Issue 27113 Correct validation of old offset gl account for Inventory transactions.
*				DANF 05/24/2005	- Issue 28754 Allocation code is not being updated to cost detail.
*				GF 01/16/2008	- issue #25569 - allow posting soft closed jobs when allocations. Source: 'JC Cost Adj' Type: 'CA'
*				GF 03/11/2008	- issue #127076 added country as output parameter
*				GF 06/10/2008	- issue #128604 - delete old intercompany 'IN' 'MatlUse' transaction not using old INGLCo.
*				gf 06/24/2008	- ISSUE #128785, #128779 related to #128604 forgot to set old glco first so get missing GLCO for offset
*				GP 07/08/2008	- Issue 120111 Update Hours & OldHours in bJCDA when expense account has a
*									cross-refrenced memo account with type M - memo.
*				GF 07/25/2008	- issue #122986 changes for tax trans for old values for UM, ECM, GL Trans acct
*				GP 09/03/2008	- Issue 129586 changed @phase & @costtype to @taxphase & @taxct when breaking out
*									GL entries to tax codes with their own phase and cost type.
*				CHS 02/26/2009	- issue #132073
*				GP 06/02/2009	- Issue 132805 added null to bspJCJMPostVal
*				GF 05/25/2010 - issue #137811 - added offset glco for material use 'JC MatUse' transactions.
*				AW 02/28/2013 - TFS - 40559 Verify JCTransType is not null required in JCCD for imports
*
*
*				
* USAGE:
* Validates each entry in bJCCB for a selected batch - must be called
* prior to posting the batch.
*
* After initial Batch and JC checks, bHQBC Status set to 1 (validation in progress)
* bHQBE (Batch Errors), and bJCDA (JC GL Batch) entries are deleted.
*
* Creates a cursor on bJCCB to validate each entry individually.
*
* Errors in batch added to bHQBE using bspHQBEInsert
* Account distributions added to bJCDA
*
* Jrnl and GL Reference debit and credit totals must balance.
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
* INPUT PARAMETERS
*   JCCo        JC Co
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

declare @rcode int, @problem varchar(255), @errortext varchar(255), @source bSource, @tablename char(20),
     	@inuseby bVPUserName, @status tinyint, @opencursor tinyint,@lastglmth bMonth,
     	@lastsubmth bMonth, @maxopen tinyint, @accttype char(1),
     	@active bYN, @fy bMonth, @seq int, @jcglco bCompany, @balamt bDollar,

		@glcostlevel tinyint, @glcostoverride bYN, @glcostjournal bJrnl,
		@glcostdetaildesc varchar(60), @glcostsummarydesc varchar(30),

		@transtype char(1), @costtrans bTrans, @job bJob, @PhaseGroup tinyint, @phase bPhase, @costtype bJCCType,
		@actualdate bDate, @jctranstype varchar(2), @description bTransDesc, @glco bCompany, @gltransacct bGLAcct,
		@gloffsetacct bGLAcct, @reversalstatus tinyint, @um bUM, @hours bHrs, @units bUnits, @cost bDollar,

		@inco bCompany, @matlgroup bGroup, @loc bLoc, @material bMatl, @pstum bUM, @pstunits bUnits, @pstunitcost bUnitCost, @pstecm bECM,
		@taxamt bDollar, @taxcode bTaxCode, @taxgroup bGroup, @oldstdunits bUnits, @oldunitcost bUnitCost, @oldstdecm bECM, @stdecm bECM,

		@oldjob bJob, @oldPhaseGroup tinyint, @oldcosttype bJCCType, @oldphase bPhase, @oldactualdate bDate,
		@oldjctranstype varchar(2), @olddescription bTransDesc, @oldglco bCompany, @oldgltransacct bGLAcct,

		@oldgloffsetacct bGLAcct, @oldreversalstatus tinyint, @oldum bUM, @oldhours bHrs, @oldunits bUnits,
		@oldcost bDollar,

		@oldinco bCompany, @oldmatlgroup bGroup, @oldloc bLoc, @oldmaterial bMatl, @oldpstum bUM, @oldpstunits bUnits, @oldpstunitcost bUnitCost, @oldpstecm bECM,
		@oldtaxamt bDollar, @oldtaxcode bTaxCode, @oldtaxgroup bGroup, @taxphase bPhase, @taxct bJCCType,

		@dtjob bJob, @dtPhaseGroup tinyint, @dtcosttype bJCCType, @dtphase bPhase, @dtactualdate bDate,
		@dtjctranstype varchar(2), @dtdescription bTransDesc, @dtglco bCompany, @dtgltransacct bGLAcct,
		@dtgloffsetacct bGLAcct, @dtreversalstatus tinyint, @dtum bUM, @dthours bHrs, @dtunits bUnits,
		@dtcost bDollar,

		@stdum bUM, @stdunits bUnits, @taxglacct bGLAcct, @locmiscglacct bGLAcct, @taxaccuralacct bGLAcct,
		@locvarianceglacct bGLAcct, @i int, @grossamt bDollar, @stdunitcost bUnitCost, @oldstdunitcost bUnitCost,
		@stdtotalcost bDollar, @oldstdum bUM, @inglco bCompany, @oldinglco bCompany, @inpstunitcost bUnitCost,
		@jobsalesacct bGLAcct, @cogsacct bGLAcct, @inventoryacct bGLAcct, @jobsalesqtyacct bGLAcct, @distamt bDollar,
		@c1 bDollar, @c2 bDollar, @c3 bDollar, @u1 bUnits, @u2 bUnits, @oldinpstunitcost bUnitCost, @gltype varchar(3),
		@interamt bDollar, @oldc1 bDollar, @oldc2 bDollar, @oldc3 bDollar, @umconv bUnits, @jcumconv bUnits,

     	@errorstart varchar(50), @subtype char(1), @stmtdate bDate, @inusebatchid bBatchID, @inglunits bYN,
     	@ctstring varchar(5), @glaccttype char(1), @JCCHUM bUM, @dummystdunitcost bUnitCost, @dummystdecm bECM,

		@tojcglco bCompany, @tojcco bCompany, @toglcostlevel tinyint, @toglcostoverride bYN, @toglcostjournal bJrnl,
		@toglcostdetaildesc varchar(60), @toglcostsummarydesc varchar(30),
		@oldtaxaccuralacct bGLAcct, @oldtaxglacct bGLAcct, @oldtaxphase bPhase, @oldtaxct  bJCCType,
		@alloccode tinyint, @memoacct bGLAcct, @oldmemoacct bGLAcct,
		----#137811
		@OffsetGLCo bCompany, @OldOffsetGLCo bCompany


select @rcode = 0, @opencursor = 0

---- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'JC CostAdj', 'JCCB', @errmsg output, @status output
if @rcode <> 0
	begin
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'JC MatUse', 'JCCB', @errmsg output, @status output
	if @rcode <> 0
		begin
		select @errmsg = @errmsg, @rcode = 1
		goto bspexit
		end
	end

if @status < 0 or @status > 3
	begin
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto bspexit
	end

/* get GL Company from JC Company */
select @jcglco = GLCo, @glcostlevel=GLCostLevel, @glcostoverride=GLCostOveride,
		@glcostjournal=GLCostJournal, @glcostdetaildesc=GLCostDetailDesc,
		@glcostsummarydesc=GLCostSummaryDesc
from bJCCO with (nolock) where JCCo = @co
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid JC Company #', @rcode = 1
	goto bspexit
	end

/*Validate GLCostJournal*/
if  @glcostlevel <> 0
	begin
	if @glcostjournal IS NULL 
		begin
		select @errmsg = 'Journal entry must be setup in JC Company parameters for company ' + isnull(convert(varchar(2),@jcglco),''), @rcode = 1
		goto bspexit
		end
	end

/* validate GL Company and Month */
select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
from bGLCO where GLCo = @jcglco
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid GL Company #' + isnull(convert(varchar(2),@jcglco),''), @rcode = 1
	goto bspexit
	end
if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
	begin
	select @errmsg = 'Not an open month', @rcode = 1
	goto bspexit
	end

/* validate Fiscal Year */
select @fy = FYEMO from bGLFY
where GLCo = @jcglco and @mth >= BeginMth and @mth <= FYEMO
if @@rowcount = 0
	begin
	select @errmsg = 'Must first add Fiscal Year', @rcode = 1
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
delete dbo.bHQBE where Co = @co and Mth = @mth and BatchId = @batchid

/* clear IN Detail Audit */
delete dbo.bJCIN where JCCo = @co and Mth = @mth and BatchId = @batchid

/* clear GL Detail Audit */
delete dbo.bJCDA where JCCo = @co and Mth = @mth and BatchId = @batchid

/*clear and refresh HQCC entries */
delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

insert into dbo.bHQCC(Co, Mth, BatchId, GLCo)
select distinct Co, Mth, BatchId, GLCo
from dbo.bJCCB where Co=@co and Mth=@mth and BatchId=@batchid



/* declare cursor on JC Detail Batch for validation */
declare bcJCCB cursor local fast_forward
	for select BatchSeq, TransType, CostTrans, Job, PhaseGroup, Phase,
			CostType, ActualDate, JCTransType, Description, GLCo, GLTransAcct, GLOffsetAcct,
			ReversalStatus, UM, Hours, Units, Cost,
			OldJob, OldPhaseGroup, OldPhase,
			OldCostType, OldActualDate, OldJCTransType, OldDescription, OldGLCo,
			OldGLTransAcct, OldGLOffsetAcct, OldReversalStatus, OldUM, OldHours, OldUnits, OldCost,
			INCo, MatlGroup, Loc, Material, PstUM, PstUnits, PstUnitCost, PstECM,
			OldINCo, OldMatlGroup, OldLoc, OldMaterial, OldPstUM, OldPstUnits, OldPstUnitCost, OldPstECM,
			OldINStdUnitCost, OldINStdECM, TaxAmt, OldTaxAmt, TaxCode, OldTaxCode, TaxGroup, OldTaxGroup,
			Source, ToJCCo, AllocCode,
			----#137811
			OffsetGLCo, OldOffsetGLCo
from dbo.bJCCB where Co = @co and Mth = @mth and BatchId = @batchid

/* open cursor */
open bcJCCB
/* set open cursor flag to true */
set @opencursor = 1


JCCB_loop:
fetch next from bcJCCB into @seq, @transtype, @costtrans, @job, @PhaseGroup, @phase,
		@costtype, @actualdate, @jctranstype, @description, @glco, @gltransacct, @gloffsetacct,
		@reversalstatus, @um, @hours, @units, @cost,
		@oldjob, @oldPhaseGroup, @oldphase,
		@oldcosttype, @oldactualdate, @oldjctranstype, @olddescription, @oldglco,
		@oldgltransacct, @oldgloffsetacct, @oldreversalstatus, @oldum, @oldhours, @oldunits, @oldcost,
		@inco, @matlgroup, @loc, @material, @pstum, @pstunits, @pstunitcost, @pstecm,
		@oldinco, @oldmatlgroup, @oldloc, @oldmaterial, @oldpstum, @oldpstunits, @oldpstunitcost, @oldpstecm,
		@oldstdunitcost, @oldstdecm, @taxamt, @oldtaxamt, @taxcode, @oldtaxcode, @taxgroup, @oldtaxgroup,
		@source, @tojcco, @alloccode,
		----#137811
		@OffsetGLCo, @OldOffsetGLCo


if @@fetch_status <> 0 goto JCCB_end

/* validate JC Detail Batch info for each entry */
select @errorstart = 'Seq# ' + isnull(convert(varchar(6),@seq),'') + ' '

/* issue #18074 - make sure ActualDate is not null so it won't stop posting in progress*/
If @actualdate is null 
	begin
	select @errortext = @errorstart + ' -  You must have an Actual Date'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end 

/* TFS - 40559 Verify JCTransType is not null required in JCCD for imports */
if @jctranstype is null
	begin
	select @errortext = @errorstart + ' -  You must have a JC Trans Type'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end

/* TFS - 40559 Verify ReversalStatus is not null required in JCCD for imports */
if @reversalstatus is null
	begin
	select @errortext = @errorstart + ' -  You must have a JC Reversal Status'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end

/* validate transaction type */
if @transtype not in ('A','C','D')
	begin
	select @errortext = @errorstart + ' -  Invalid transaction type, must be (A, C, or D).'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end

/* validation specific to Add types */
if @transtype = 'A'
	begin
	/* check CM Trans# */
	if @costtrans is not null
		begin
		select @errortext = @errorstart + ' - (New) entries may not reference a Cost Detail Transaction #.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		end

	/* all old values must be null */
	if @oldjob is not null or @oldPhaseGroup is not null or @oldphase is not null or @oldcosttype is not null or
		@oldactualdate is not null or @oldjctranstype is not null or @olddescription is not null or
		@oldglco is not null or @oldgltransacct is not null or @oldgloffsetacct is not null or @oldreversalstatus is not null or
		@oldum is not null or @oldhours is not null or @oldunits is not null or @oldcost is not null
		begin
		select @errortext = @errorstart + ' - Old information in batch must be null for Add entries.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode<>0 goto bspexit
		end

	/* Validate Allocation Code on new transactions */
	if @jctranstype ='CA' and
		not exists(select 1 from dbo.bJCAC where JCCo=@co and AllocCode = @alloccode)
		begin
		select @errortext = @errorstart + ' - invalid cost allocation code.'
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode<>0 goto bspexit
		end
	end -- end transtype = A


----Added InterCompany Code for JC Trnasaction types of 'JC'
----Set @glco and @co to To Company and To Company Gl Company
if isnull(@tojcco,'') = ''
	begin
	select @tojcco = @co
	update bJCCB Set ToJCCo = @tojcco
	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
	end


	/**** 120111 - Insert and update Hours & OldHours in bJCDA if corresponding expense account
		exists in bGLAC of AcctType Memo ****/
	IF @transtype = 'A'
	BEGIN
		SELECT @memoacct = CrossRefMemAcct FROM bGLAC with(nolock) WHERE GLCo = @glco and GLAcct = @gltransacct
		IF exists(SELECT TOP 1 1 FROM bGLAC with(nolock) WHERE GLCo = @glco and GLAcct = @memoacct
		and AcctType = 'M')
		BEGIN
			INSERT INTO bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew, CostTrans, 
			Job, Phase, CostType, JCTransType, ActDate, Description, Amount, Payee, INCo, Loc, 
			Material, Qty, Hours, OldHours)
       		VALUES (@co, @mth, @batchid, 'HRS', @glco, @memoacct, @seq, 1, @costtrans, 
			@job, @phase, @costtype, @jctranstype, @actualdate, @description, 0, null, @inco, @loc,
			@material, null, isnull(@hours, 0), 0)
		END
	END

	IF @transtype in ('C','D')
	BEGIN
		SELECT @oldmemoacct = CrossRefMemAcct FROM bGLAC with(nolock) WHERE GLCo = @glco and GLAcct = @oldgltransacct
		IF @transtype = 'C' and exists(SELECT TOP 1 1 FROM bGLAC with(nolock) WHERE GLCo = @glco and GLAcct = @oldmemoacct
		and AcctType = 'M') and (@hours <> @oldhours)
		BEGIN
			INSERT INTO bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew, CostTrans, 
			Job, Phase, CostType, JCTransType, ActDate, Description, Amount, Payee, INCo, Loc, 
			Material, Qty, Hours, OldHours)
       		VALUES (@co, @mth, @batchid, 'HRS', @oldglco, @oldmemoacct, @seq, 0, @costtrans, 
			@oldjob, @oldphase, @oldcosttype, @oldjctranstype, @oldactualdate, @olddescription, 0, null, @oldinco, @oldloc,
			@oldmaterial, null, -(@oldhours), @oldhours)

			INSERT INTO bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew, CostTrans, 
			Job, Phase, CostType, JCTransType, ActDate, Description, Amount, Payee, INCo, Loc, 
			Material, Qty, Hours, OldHours)
       		VALUES (@co, @mth, @batchid, 'HRS', @oldglco, @oldmemoacct, @seq, 1, @costtrans, 
			@oldjob, @oldphase, @oldcosttype, @oldjctranstype, @oldactualdate, @olddescription, 0, null, @oldinco, @oldloc,
			@oldmaterial, null, isnull(@hours, 0), isnull(@oldhours, 0))

		END
		IF @transtype = 'D' and exists(SELECT TOP 1 1 FROM bGLAC with(nolock) WHERE GLCo = @glco and GLAcct = @oldmemoacct
		and AcctType = 'M')
		BEGIN
			INSERT INTO bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew, CostTrans, 
			Job, Phase, CostType, JCTransType, ActDate, Description, Amount, Payee, INCo, Loc, 
			Material, Qty, Hours, OldHours)
       		VALUES (@co, @mth, @batchid, 'HRS', @oldglco, @oldmemoacct, @seq, 0, @costtrans, 
			@oldjob, @oldphase, @oldcosttype, @oldjctranstype, @oldactualdate, @olddescription, 0, null, @oldinco, @oldloc,
			@oldmaterial, null, isnull(-(@hours), 0), isnull(@oldhours, 0))
		END
	END
   

   	if @jctranstype = 'IC'
          begin
          	-- get GL Company from JC Company
     		select @tojcglco = GLCo, @toglcostlevel=GLCostLevel, @toglcostoverride=GLCostOveride,
            		@toglcostjournal=GLCostJournal, @toglcostdetaildesc=GLCostDetailDesc,
            		@toglcostsummarydesc=GLCostSummaryDesc from bJCCO where JCCo = @tojcco
     		if @@rowcount = 0
     			begin
     			select @errmsg = 'Invalid JC Company #', @rcode = 1
     			goto bspexit
     			end
     		--Validate GLCostJournal=
 
     		if  @toglcostlevel <> 0
   			begin
     			if @toglcostjournal IS NULL 
    				begin
    				select @errmsg = 'Journal entry must be up in JC Company parameters for company ' + convert(varchar(2),@tojcglco), @rcode = 1
    				goto bspexit
    				end
   			end
   		-- validate GL Company and Month
     		select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
     		from bGLCO where GLCo = @tojcglco
     		if @@rowcount = 0
     			begin
     			select @errmsg = 'Invalid GL Company #' + isnull(convert(varchar(2),@tojcglco),''), @rcode = 1
     			goto bspexit
     			end
     		if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
     			begin
     			select @errmsg = 'Not an open month', @rcode = 1
     			goto bspexit
     			end
   
     		-- validate Fiscal Year 
     		select @fy = FYEMO from bGLFY
     		where GLCo = @tojcglco and @mth >= BeginMth and @mth <= FYEMO
     		if @@rowcount = 0
     			begin
     			select @errmsg = 'Must first add Fiscal Year', @rcode = 1
     			goto bspexit
     			end 
   
          end -- End JCTransAction Type 'IC'
   
        if @jctranstype <> 'IC' select @tojcglco = @jcglco
   
        /* validation specific to Add and change types */
        if @transtype = 'A' or @transtype = 'C'
           begin
   
             select @ctstring=convert(varchar(5),@costtype)
             exec @rcode = bspJCVCOSTTYPE @tojcco, @job, @PhaseGroup, @phase, @ctstring, 'N',@um=@JCCHUM output, @msg=@errmsg output
   
             -- Set PstUm and PstUnits for JobCostAdj's
             If @source ='JC CostAdj'
                begin
                --Set Pst Units to units and Pst um to the um form JCCH
   
                     if @um <> @JCCHUM
                        Begin
     	                  select @errortext = @errorstart + ' - entry has a unit of measure ' + isnull(@um,'') + ' which does not match the Job / Phase / Cost type unit of measure ' + isnull(@JCCHUM,'') +'.'
     	                  exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	                  if @rcode <> 0 goto bspexit
                        End
                    
                     select @pstunitcost = 0
                     if isnull(@cost,0) <> 0 and isnull(@units,0) <> 0 select @pstunitcost = isnull(@cost,0) / isnull(@units,0)
                     update bJCCB
                     Set PstUM =@JCCHUM, PstUnits = @units, PstECM = 'E', PstUnitCost = @pstunitcost
                     where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
                end
   
   
             If @source ='JC MatUse' and isnull(@um,'')=''
                begin
   	               select @um=@JCCHUM
   	
   	   		  update bJCCB
   	               Set UM =@JCCHUM
   	               where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
                end
   
   
   
		/* validate JobJC Transaction Type - AP, AR, JC, Etc...*/
		if (@jctranstype not in ('AP','AR','JC','PR','MO','MS','EM','CA','IC') and @source ='JC CostAdj') or (@jctranstype not in ('IN','MI') and @source ='JC MatUse')
			begin
			select @errortext = @errorstart + isnull(@jctranstype,'') + ' is an Invalid JCTransType for this batch.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end

		---- validate job - need to do something different for @source = 'JC CostAdj' and @jctranstype = 'CA'
		---- first check if status = 3 and post closed jobs = 'N' if true execute bsp so that message is consistent.
		if @jctranstype = 'CA' and @source = 'JC CostAdj'
			begin
			if exists(select top 1 1 from JCJM j with (nolock) join JCCO c with (nolock) on c.JCCo=j.JCCo
							where j.JCCo=@tojcco and j.Job = @job and j.JobStatus = 3 and c.PostClosedJobs = 'N')
				begin
				exec @rcode = bspJCJMPostVal @tojcco, @job, null, null, null, null, null, null, null, null, null, null, null, null, null, @msg=@errmsg output
				if @rcode = 1
					begin
					select @errortext = @errorstart + 'Job ' + isnull(@job,'') + ' ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto SkipPhaseCtVal   /* if invalid then skip all related validation*/
					end
				end
			end
		else
			begin
			exec @rcode = bspJCJMPostVal @tojcco, @job, null, null, null, null, null, null, null, null, null, null, null, null, null, @msg=@errmsg output
			if @rcode = 1
				begin
				select @errortext = @errorstart + 'Job ' + isnull(@job,'') + ' ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto SkipPhaseCtVal   /* if invalid then skip all related validation*/
				end
			end

		/* validate phase */
		exec @rcode = bspJCVPHASE @tojcco, @job, @phase, @PhaseGroup, 'N', @msg=@errmsg output
		if @rcode = 1
			begin
			select @errortext = @errorstart + 'Phase: ' + isnull(@phase,'') + ' - ' + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto SkipPhaseCtVal   /* if invalid then skip all related validation*/
			end

		/* validate CostType */
		select @ctstring=convert(varchar(5),@costtype)
		exec @rcode = bspJCVCOSTTYPE @tojcco, @job, @PhaseGroup,@phase, @ctstring, 'N', @msg=@errmsg output
		if @rcode = 1
			begin
			select @errortext = @errorstart + 'Cost Type: ' + isnull(convert(char(3),@costtype),'') + ' - ' + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto SkipPhaseCtVal   /* if invalid then skip all related validation*/
			end

		---- null out tax phase and cost type
		update bJCCB Set TaxPhase = Null, TaxCostType = Null
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq


		/** Check for redirection of phase and cost type **/
		if @taxcode is not null and @taxgroup is not null and @taxamt <> 0
			begin
			select @taxphase = Phase, @taxct = JCCostType
			from bHQTX
			where TaxGroup = @taxgroup and TaxCode = @taxcode
			if not @taxphase is null or not @taxct is null
				begin
				if @taxphase is null select @taxphase = @phase
				if @taxct is null select @taxct = @costtype
				---- update JCCB with tax phase and cost type
				update bJCCB Set TaxPhase = @taxphase, TaxCostType = @taxct
				where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq

				/* validate tax phase */
				exec @rcode = bspJCVPHASE @tojcco, @job, @taxphase, @PhaseGroup,'N', @msg=@errmsg output
				if @rcode = 1
					begin
					select @errortext = @errorstart + 'Tax code : ' + isnull(@taxcode,'') + ' ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto SkipPhaseCtVal   /* if invalid then skip all related validation*/
					end
   
				/* validate tax CostType */
				select @ctstring=convert(varchar(5),@taxct)
				exec @rcode = bspJCVCOSTTYPE @tojcco, @job, @PhaseGroup, @taxphase, @ctstring, 'N', @msg=@errmsg output
				if @rcode = 1
					begin
					select @errortext = @errorstart + 'Tax: ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto SkipPhaseCtVal   /* if invalid then skip all related validation*/
					end
				end
			end





     SkipPhaseCtVal:
   
		-- #132073
		if @gloffsetacct is not null and @gltransacct = @gloffsetacct and @jctranstype <> 'IC'
			begin
			select @errortext = @errorstart + 'The transaction GLAcct:' + isnull(@gltransacct,'') + ' cannot equal the GL Off set account.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end

		/*validate GLAccounts */
		exec @rcode = bspGLACfPostable @glco, @gltransacct, 'J', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + 'Transaction GLAcct:' + isnull(@gltransacct,'') + ' ' + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
   
		/*Only validate Offset account if its not null */
		if not @gloffsetacct is null
			begin
			select @glaccttype = 'N', @inglco=@jcglco
			if (@source='JC MatUse' and @jctranstype = 'IN')
				begin
				---- #137811
				---- we are now storing the offset gl company for material use transactions.
				---- we need to use the @OffsetGLCo and @OldOffsetGLCo from JCCB
				set @glaccttype = 'I'
				set @inglco = @OffsetGLCo
				if @OffsetGLCo is null
					begin
					select @inglco=GLCo from dbo.bINCO with (nolock) where INCo = @inco
					end
				end

			exec @rcode = bspGLACfPostable @inglco, @gloffsetacct, @glaccttype, @errmsg output
			if @rcode <> 0
				begin
				select @errortext = @errorstart + 'Offset GLAcct:' + isnull(@gloffsetacct,'') + ' ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
            end
		/*if its a reversal transaction then  Offset acct cant be null */
		else
     		if @reversalstatus=1
				begin
				select @errortext = @errorstart + 'You must have an offset account for reversal transactions! '
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end

			/*validate Reversal Status,must be 0, 1, 2, 3, 4 */
			if @reversalstatus not in (0,1,2,3,4)
				begin
				select @errortext = @errorstart + 'reversal status:' + isnull(convert(char(2),@reversalstatus),'') + ' is invalid!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end

			if @reversalstatus=4 and @transtype = 'C'
				begin
				select @errortext = @errorstart + 'cannot cancel reversal entry unless it is the original reversing entry.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end

			if @reversalstatus=1 and @gloffsetacct is null
				begin
				select @errortext = @errorstart + 'reversal transactions must have an offset account! is invalid!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end

			/*unit of measure against HQUM*/
			if not exists(select * from bHQUM where @um=UM)
				begin
				select @errortext = @errorstart + 'Unit of measure:' + isnull(@um,'') + ' is invalid!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   
   
	if @taxcode is not null and @source='JC MatUse' and @jctranstype = 'MI'
		begin
		select @taxaccuralacct = GLAcct, @taxphase = Phase, @taxct = JCCostType
		from bHQTX with (nolock)
		where TaxGroup = @taxgroup and TaxCode = @taxcode
		if @@rowcount = 0
			begin
			select @errortext = @errorstart + 'Invalid Tax Code:' + isnull(@taxcode,'') + ' Tax Group ' + isnull(convert(varchar(3),@taxgroup),'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto JCCB_loop
			end

		-- validate Tax Account
		if @taxaccuralacct is null
			begin
			select @errortext = @errorstart + 'Missing Tax GL Account for Tax code : ' + isnull(@taxcode,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto JCCB_loop
			end

		exec @rcode = bspGLACfPostable @jcglco, @taxaccuralacct, 'P', @errmsg output
		If @rcode <> 0
			begin
			select @errortext = @errorstart + 'Tax Accural GL Account:' + isnull(@taxaccuralacct,'') + ' -   ' + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto JCCB_loop
			end

		---- Tax Phase and Cost Type
		---- use 'posted' phase and cost type unless overridden by tax code
		if @taxphase is null select @taxphase = @phase
		if @taxct is null select @taxct = @costtype
		select @taxglacct = @gltransacct     -- default is 'posted' account

		if @taxphase <> @phase or @taxct <> @costtype
			begin
			---- get GL Account for Tax Expense
			exec @rcode = bspJCCAGlacctDflt @co, @job, @PhaseGroup, @taxphase, @taxct, 'J', @taxglacct output, @errmsg output
			if @rcode <> 0
				begin
				select @errortext = @errorstart + 'Tax: ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto JCCB_loop
				end
			---- validate Tax Account
			exec @rcode = bspGLACfPostable @jcglco, @taxglacct , 'J', @errmsg output
			If @rcode <> 0
				begin
				select @errortext = @errorstart + 'Tax Expense for Job ' + isnull(@job,'') + ' Phase ' + isnull(@taxphase,'') + ' cost type ' + isnull(convert(varchar(3),@taxct),'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto JCCB_loop
				end
			end
		end
   
   
		/* validate IN Co#, Location, Material, and UM*/
		if (@source='JC MatUse' and @jctranstype = 'IN')
			begin
			exec @rcode = bspJCCBValInv @mth, @inco, @loc, @matlgroup, @material, @pstum, @pstunits, @taxcode,
				@jcglco, @taxgroup, @PhaseGroup, @phase, @costtype, @job, @co, @gltransacct,
				@stdum output, @stdunits output, @stdunitcost output, @stdecm output, @inpstunitcost output,
				@taxglacct output, @taxaccuralacct output, @locmiscglacct output, @locvarianceglacct output, @inglco output,
				@taxphase output, @taxct output, @inglunits output, @jobsalesacct output, @cogsacct output,
				@inventoryacct output, @jobsalesqtyacct output, @errmsg output
			if @rcode <> 0
				begin
				select @errortext = @errmsg
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto JCCB_loop
				end
			end
		end
   
	--#25411 Correct validation of the old tax accounts
	if @oldtaxcode is not null and @source='JC MatUse' and @jctranstype = 'MI'
         begin
         select @oldtaxaccuralacct = GLAcct, @oldtaxphase = Phase, @oldtaxct = JCCostType
         from bHQTX
         where TaxGroup = @oldtaxgroup and TaxCode = @oldtaxcode
         if @@rowcount = 0
             begin
               select @errortext = @errorstart + 'Invalid Old Tax Code:' + isnull(@oldtaxcode,'') + ' Tax Group ' + isnull(convert(varchar(3),@oldtaxgroup),'')
               exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto JCCB_loop
             end
          -- validate Tax Account
          if @oldtaxaccuralacct is null
            begin
               select @errortext = @errorstart + 'Missing Old Tax GL Account for Tax code : ' + isnull(@oldtaxcode,'')
               exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
               goto JCCB_loop
        	 end
          exec @rcode = bspGLACfPostable @jcglco, @oldtaxaccuralacct, 'P', @errmsg output
          If @rcode <> 0
				begin
				select @errortext = @errorstart + 'Old Tax Accural GL Account:' + isnull(@oldtaxaccuralacct,'') + ' -   ' + isnull(@errmsg,'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto JCCB_loop
				end
			-- Tax Phase and Cost Type
			-- use 'posted' phase and cost type unless overridden by tax code
			if @oldtaxphase is null select @oldtaxphase = @phase
			if @oldtaxct is null select @oldtaxct = @costtype
			select @oldtaxglacct = @oldgltransacct     -- default is 'posted' account
			
			if @oldtaxglacct is null or @oldtaxphase <> @oldphase or @oldtaxct <> @oldcosttype
				begin
----             if @oldtaxphase <> @oldphase or @oldtaxct <> @oldcosttype
----       		    begin
      	        -- get GL Account for Tax Expense
				exec @rcode = bspJCCAGlacctDflt @co, @oldjob, @oldPhaseGroup, @oldtaxphase, @oldtaxct, 'J', @oldtaxglacct output, @errmsg output
              	if @rcode <> 0
					begin
					select @errortext = @errorstart + ' Old Tax: ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto JCCB_loop
					end
				-- validate Tax Account
				exec @rcode = bspGLACfPostable @jcglco, @oldtaxglacct , 'J', @errmsg output
				If @rcode <> 0
					begin
					select @errortext = @errorstart + 'Tax Expense for Job ' + isnull(@oldjob,'') + ' Phase ' + isnull(@oldtaxphase,'') + ' cost type ' + isnull(convert(varchar(3),@oldtaxct),'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto JCCB_loop
					end
				if @oldgltransacct is null set @oldgltransacct = @oldtaxglacct
				end
   	end /* end validation of old tax code*/
   
         /* validation specific for Change and Delete types */
       if @transtype = 'C' or @transtype = 'D'
			begin
			/* get existing values from JCCD */
			select @dtjob=Job, @dtPhaseGroup=PhaseGroup, @dtphase=Phase,
				@dtcosttype=CostType, @dtactualdate=ActualDate,
				@dtjctranstype=JCTransType, @dtdescription=Description,
				@dtglco=GLCo, @dtgltransacct=GLTransAcct, @dtgloffsetacct=GLOffsetAcct,
				@dtreversalstatus=ReversalStatus, @dtum=UM, @dthours=ActualHours,
				@dtunits=ActualUnits, @dtcost=ActualCost, @inusebatchid = InUseBatchId
			from bJCCD where JCCo = @co and Mth = @mth and CostTrans = @costtrans
			if @@rowcount = 0
				begin
				select @errortext = @errorstart + ' - Missing JC Detail Transaction#:' + isnull(convert(char(3),@costtrans),'')
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto JCCB_loop
				end

			/* check In Use Batch info */
			if @inusebatchid <> @batchid
				begin
				select @errortext = @errorstart + ' - Existing Detail Transaction has not been assigned to this batch.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
   
     		/* make sure old values in batch match existing values in detail */
			if @oldtaxcode is not null and @source='JC MatUse' and @jctranstype = 'MI'
				begin
				if @dtjob<>@oldjob or @dtphase<>@oldphase or
					@dtcosttype<>@oldcosttype or @dtactualdate<>@oldactualdate or
					@dtjctranstype<>@oldjctranstype or @dtdescription<>@olddescription or
					@dtglco <> @oldglco or @dtreversalstatus<>@oldreversalstatus or @dtum<>@oldum or
					@dthours<>@oldhours or @dtunits<>@oldunits or @dtcost<>@oldcost
					begin
					select @errortext = @errorstart + ' - Old information in batch does not match existing info in JC Detail.'
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto JCCB_loop
					end
				end
			else
				begin
				if @dtjob<>@oldjob or @dtphase<>@oldphase or
					@dtcosttype<>@oldcosttype or @dtactualdate<>@oldactualdate or
					@dtjctranstype<>@oldjctranstype or @dtdescription<>@olddescription or
					@dtglco <> @oldglco or isnull(@dtgltransacct,'')<>isnull(@oldgltransacct,'') or
					isnull(@dtgloffsetacct,'') <> isnull(@oldgloffsetacct,'') or
					@dtreversalstatus<>@oldreversalstatus or @dtum<>@oldum or @dthours<>@oldhours or
					@dtunits<>@oldunits or @dtcost<>@oldcost
					begin
					select @errortext = @errorstart + ' - Old information in batch does not match existing info in JC Detail.'
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto JCCB_loop
					end
				end

     	/*validate the old values*/
		/* validate old JobJC Transaction Type - AP, AR, JC, Etc...*/
		if (@source='JC CostAdj' and @oldjctranstype not in ('AP','AR','JC','PR','MO', 'MS', 'EM','CA')) or (@source='JC MatUse' and @oldjctranstype not in ('IN','MI'))
			begin
			select @errortext = @errorstart + isnull(@oldjctranstype,'') + ' is an Invalid JCTransType for this batch.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
   
		---- validate old job - need to do something different for @source = 'JC CostAdj' and @jctranstype = 'CA'
		---- first check if status = 3 and post closed jobs = 'N' if true execute bsp so that message is consistent.
		if @oldjctranstype = 'CA' and @source = 'JC CostAdj'
			begin
			if exists(select top 1 1 from JCJM j with (nolock) join JCCO c with (nolock) on c.JCCo=j.JCCo
							where j.JCCo=@tojcco and j.Job = @oldjob and j.JobStatus = 3 and c.PostClosedJobs = 'N')
				begin
				exec @rcode = bspJCJMPostVal @tojcco, @oldjob, null, null, null, null, null, null, null, null, null, null, null, null, null, @msg=@errmsg output
				if @rcode = 1
					begin
					select @errortext = @errorstart + 'Job ' + isnull(@oldjob,'') + ' ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto SkipPhaseCtVal2   /* if invalid then skip all related validation*/
					end
				end
			else
				begin
				exec @rcode = bspJCJMPostVal @tojcco, @oldjob, null, null, null, null, null, null, null, null, null, null, null, null, null, @msg=@errmsg output
				if @rcode = 1
					begin
					select @errortext = @errorstart + 'Job ' + isnull(@oldjob,'') + ' ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto SkipPhaseCtVal2   /* if invalid then skip all related validation*/
					end
				end
			end

   
           /* validate old phase */
           exec @rcode = bspJCVPHASE @tojcco, @oldjob, @oldphase, @oldPhaseGroup,'N', @msg=@errmsg output
           if @rcode = 1
              begin
               select @errortext = @errorstart + 'Old Phase' + isnull(@oldphase,'') + ' - ' + isnull(@errmsg,'')
     	      exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	      if @rcode <> 0 goto bspexit
      	      goto SkipPhaseCtVal2   /* if invalid then skip all related validation*/
             end
   
           /* validate Old CostType */
           select @ctstring=convert(varchar(5),@oldcosttype)
           exec @rcode = bspJCVCOSTTYPE @tojcco, @oldjob, @oldPhaseGroup,@oldphase, @ctstring, 'N', @msg=@errmsg output
           if @rcode = 1
     	  begin
            select @errortext = @errorstart + 'Old Costtype:' + isnull(convert(char(3),@oldcosttype),'') + ' - ' + isnull(@errmsg,'')
     	   exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	   if @rcode <> 0 goto bspexit
      	   goto SkipPhaseCtVal2   /* if invalid then skip all related validation*/
           end
   
     SkipPhaseCtVal2:
   
		/*validate Old GLAccounts */
		exec @rcode = bspGLACfPostable @oldglco, @oldgltransacct, 'J', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + 'OLD Transaction GLAcct:' + isnull(@oldgltransacct,'') + ' ' + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
   
		/*only validate offset acct if not null */
		/*Currently we are not storing the offset gl company therefore we
		cannot allow Intercompany transactions to be pulled back into 
		a batch and changed. */ 
		if not @oldgloffsetacct is null
			begin
			select @glaccttype = 'N', @inglco=@jcglco, @oldinglco=@oldglco ----#128785
			if (@source='JC MatUse' and @jctranstype = 'IN')
				begin
				---- #137811
				---- we are now storing the offset gl company for material use transactions.
				---- we need to use the @OffsetGLCo and @OldOffsetGLCo from JCCB
				set @glaccttype = 'I'
				set @oldinglco = @OldOffsetGLCo
				if @OldOffsetGLCo is null
					begin
					select @oldinglco=GLCo from dbo.bINCO with (nolock) where INCo = @oldinco
					end
				end
			----#128604
			----exec @rcode = bspGLACfPostable @oldglco, @oldgloffsetacct, @glaccttype, @errmsg output
			exec @rcode = bspGLACfPostable @oldinglco, @oldgloffsetacct, @glaccttype, @errmsg output
			if @rcode <> 0
				begin
				select @errortext = @errorstart + 'OLD Offset GLAcct:' + isnull(@oldgloffsetacct,'') + ' ' + isnull(@errmsg,'') ----+ ' ' + convert(varchar(3),@oldglco) + ', ' + convert(varchar(3),@inglco)
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
			end -- end oldgloffsetacct
   
            /*validate Reversal Status, can only be 0 or 1, 2, 3 for changed entries */
           if @oldreversalstatus not in (0,1,2,3)
       	  begin
     	   select @errortext = @errorstart + 'old reversal status:' + isnull(convert(char(2),@oldreversalstatus),'') + ' is invalid!'
     	   exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	   if @rcode <> 0 goto bspexit
           end
   
           /*unit of measure against HQUM*/
           if not exists(select * from bHQUM where @oldum=UM)
       	  begin
     	   select @errortext = @errorstart + 'Old Unit of measure:' + isnull(@oldum,'') + ' is invalid!'
     	   exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	   if @rcode <> 0 goto bspexit
           end
   
         /* validate IN Co#, Location, Material, and UM*/
              if (@source='JC MatUse' and @oldjctranstype = 'IN')
                 begin
                 exec @rcode = bspJCCBValInv @mth, @oldinco, @oldloc, @oldmatlgroup, @oldmaterial, @oldpstum, @oldpstunits, @oldtaxcode,
                       @jcglco, @oldtaxgroup, @oldPhaseGroup, @oldphase, @oldcosttype, @oldjob, @co, @oldgltransacct,
                       @oldstdum output, @oldstdunits output, @dummystdunitcost output, @dummystdecm output, @oldinpstunitcost output,
                       @taxglacct output, @taxaccuralacct output, @locmiscglacct output, @locvarianceglacct output, @oldinglco output,
                       @taxphase output, @taxct output, @inglunits output, @jobsalesacct output, @cogsacct output,
                       @inventoryacct output, @jobsalesqtyacct output,@errmsg output
                  if @rcode <> 0
                      begin
         		        select @errortext =  @errmsg
                         exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	                if @rcode <> 0 goto bspexit
      	        goto JCCB_loop
        	 end
             end -- end oldjctranstype = MS
         end -- end @transtype = 'C' or @transtype = 'D'
   
         -- before we update the audit make sure that both accounts arent the same
         -- Corrected so the accounts can be the same
   
         /*if @gltransacct=@gloffsetacct
     	 begin
     	  select @errortext = @errorstart + 'Debit account'+ @gltransacct+'  and credit account'+ @gloffsetacct + ' cannot be the same!'
     	  exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	  if @rcode <> 0 goto bspexit
      	  goto JCCB_loop
          end
   
         if (@transtype <> 'A' and @oldgltransacct=@oldgloffsetacct)
     	 begin
     	  select @errortext = @errorstart + 'Debit account and credit account cannot be the same!'
   
     	  exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	  if @rcode <> 0 goto bspexit
      	  goto JCCB_loop
         end*/
   
         update_audit:	-- update GL Detail Audit  - only update if Amount, GLAcct or Void flag changes */
   
       --- update jc units form posted units
        if @source='JC MatUse' and @transtype<>'D'
          begin -- source
          select @units = 0
          -- if JC unit of measure equals posted unit of measure, set JC units eqaul to posted
          if @um <> @pstum and @matlgroup is not null and @material is not null and @pstunits <> 0
            begin
              -- get conversion for posted unit of measure
              exec @rcode = bspHQStdUMGet @matlgroup, @material, @pstum, @umconv output, @stdum output, @errmsg output
              if @rcode = 0
                 begin
            -- get conversion for JC unit of measure
                   exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @jcumconv output, @stdum output, @errmsg output
                   if @rcode = 0
                      begin
                         if @jcumconv <> 0 select @units = @pstunits * (@umconv / @jcumconv)
                      end
                 end
              end
              if @um = @pstum select @units = @pstunits
              update bJCCB
              Set Units = @units
               where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
            end -- source
   
            if @source='JC MatUse'
            begin
                -- 'New' IN distributions
                If (@transtype<>'D' and @jctranstype = 'IN')
                begin
                  select @i = 1
                  if @pstecm = 'C' select @i = 100
                  if @pstecm = 'M' select @i = 1000
                  select @u1 = (-1 * @pstunits), @c1 = -1 * (@pstunits * @inpstunitcost)/@i
                  select @c3 = (-1 * @pstunits * @pstunitcost)/@i
                  select @i = 1
                  if @stdecm = 'C' select @i = 100
                  if @stdecm = 'M' select @i = 1000
                  select @u2 = (-1 * @stdunits), @c2 = (-1 * @stdunits * @stdunitcost)/@i
                  -- add new JCIN entry
                      exec @rcode = bspJCCBValINInsert @co, @mth, @batchid, @inco, @loc,
                                    @matlgroup, @material, @seq, 1,
                                    @job, @PhaseGroup, @phase, @costtype,
                                    @actualdate, @description, @glco, @gltransacct,
                                    @pstum, @u1, @inpstunitcost, @pstecm, @c1,
                                    @stdum, @u2, @stdunitcost, @stdecm, @c2,
                                    @pstunitcost, @c3
                      if @rcode = 0 -- Update JCCB with IN values from costing Method
                         begin
                          update bJCCB
                          Set INStdUM = @stdum, INStdUnitCost = @stdunitcost, INStdECM = @stdecm
                          where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
                        end
                   end -- end transtype <> D
   			
   			-- Old
                if (@transtype<>'A' and @oldjctranstype='IN')
                 begin
                  select @i = 1
                  if @oldpstecm = 'C' select @i = 100
                  if @oldpstecm = 'M' select @i = 1000
                  select @oldc1 = (@oldpstunits * @oldinpstunitcost)/@i
                  select @oldc3 = (@oldpstunits * @oldpstunitcost)/@i
                select @i = 1
                  if @oldstdecm = 'C' select @i = 100
                  if @oldstdecm = 'M' select @i = 1000
                  select @oldc2 = (@oldstdunits * @oldstdunitcost)/@i
                  exec @rcode = bspJCCBValINInsert @co, @mth, @batchid, @oldinco, @oldloc,
                                @oldmatlgroup, @oldmaterial, @seq, 0,
                                @oldjob, @oldPhaseGroup, @oldphase, @oldcosttype,
                                @oldactualdate, @olddescription, @oldglco, @oldgltransacct,
   
                                @oldpstum, @oldpstunits, @oldinpstunitcost, @oldpstecm, @oldc1,
                                @oldstdum, @oldstdunits, @oldstdunitcost, @oldstdecm, @oldc2,
                                @oldpstunitcost, @oldc3
                end -- end trans type <> A
   
               end -- end jctranstype = MS
   
		select @gltype = 'CST'
		-- Make GL Entries for Job Cost Adjustments and Job Material Use Entries that have a transaction type of 'MI'
		if @source='JC CostAdj' or @jctranstype <> 'IN' or (@oldjctranstype <> 'IN' and isnull(@oldjctranstype,'')<>'')
			begin
			if (@transtype<>'C') or (@oldgltransacct <> @gltransacct or @oldgloffsetacct <> @gloffsetacct or @oldcost <> @cost or isnull(@oldtaxamt,0)<>isnull(@taxamt,0))
				begin
				if @transtype <> 'A' and @oldcost <> 0 /* don't add GL distributions for 0 amounts */
					begin
					/* insert 'old' entry for posted GL Account */
					if @oldgltransacct is not null
						begin
						update bJCDA Set Amount = Amount + (-1*(@oldcost-isnull(@oldtaxamt,0)))
						where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType=@gltype and GLCo=@oldglco and GLAcct=@oldgltransacct and BatchSeq=@seq and OldNew=0
						if @@rowcount = 0
							Begin
							insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
									CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount,Material)
							values (@co, @mth, @batchid, @gltype, @oldglco, @oldgltransacct, @seq, 0,
									@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype,
									@oldactualdate, @olddescription, (-1* (@oldcost-isnull(@oldtaxamt,0))),@oldmaterial)
							if @@rowcount = 0
								begin
								select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
								goto bspexit
								end
						end
					END

				if not @oldgloffsetacct is null
					begin
					update bJCDA Set Amount = Amount + (@oldcost-isnull(@oldtaxamt,0))
					where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType=@gltype and GLCo=@oldglco and GLAcct=@oldgloffsetacct and BatchSeq=@seq and OldNew=0
					if @@rowcount = 0
						Begin
						insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
							CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount, Material)
						values (@co, @mth, @batchid, @gltype, @oldglco, @oldgloffsetacct, @seq, 0,
							@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype,
							@oldactualdate, @olddescription,  (@oldcost-isnull(@oldtaxamt,0)),@oldmaterial)
						if @@rowcount = 0
							begin
							select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
							goto bspexit
							end
						end
					end -- end gl account offset

			-- Tax amount for JC Material Use with a trans type of 'MI'
			If @oldtaxcode is not null and @oldtaxamt <> 0 and @source='JC MatUse' and @jctranstype = 'MI'
				begin
				--Insert Job Expense Tax Account
				if @oldtaxglacct is not null
					begin
					update bJCDA Set Amount = Amount - @oldtaxamt
					where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@glco and GLAcct=@oldtaxglacct and BatchSeq=@seq and OldNew=0
					if @@rowcount = 0
						Begin
						--Insert Job Expense Tax Account
						insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
     		       	  		CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount,Material)
						values (@co, @mth, @batchid, @gltype, @oldglco, @oldtaxglacct, @seq, 0,
        					@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype,
     			    		@oldactualdate, @olddescription, (-@oldtaxamt),@oldmaterial)
						if @@rowcount = 0
							begin
							select @errmsg = 'Unable to JC Detail audit!', @rcode = 1
							goto bspexit
							end
						end
					end
					
				--Insert tax accual account
				if @oldtaxaccuralacct is not null
					begin
					update bJCDA Set Amount = Amount + (@oldtaxamt)
					where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@oldinglco and GLAcct= @oldtaxaccuralacct and BatchSeq=@seq and OldNew=0
					if @@rowcount = 0
						begin
						insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
							CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount, Material)
      					values (@co, @mth, @batchid, @gltype, @oldglco, @oldtaxaccuralacct, @seq, 0,
							@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype,
							@oldactualdate, @olddescription, ( @oldtaxamt), @oldmaterial)
						if @@rowcount = 0
							begin
							select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
							goto bspexit
							end
						end
					end
				end -- end old tax amounts
			 end -- end trans type <> A

		if @transtype <> 'D' and @cost <> 0	/* don't add GL distributions for 0 amounts */
			begin
			/* insert entry for Adjustment*/
              update bJCDA Set Amount = Amount + ((@cost)-isnull(@taxamt,0))
              where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType=@gltype and GLCo=@glco and GLAcct=@gltransacct and BatchSeq=@seq and OldNew=1
     	      if @@rowcount = 0
              Begin
     	      insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
     		       		CostTrans, Job, Phase, CostType, JCTransType,
     			    	ActDate, Description, Amount, Material)
      			values (@co, @mth, @batchid, @gltype, @glco, @gltransacct, @seq, 1,
        				@costtrans, @job, @phase, @costtype, @jctranstype,
     				@actualdate, @description, (@cost)-isnull(@taxamt,0), @material)
     			if @@rowcount = 0
     		   		begin
     		    		select @errmsg = 'Unable to JC Detail audit!', @rcode = 1
     		     		goto bspexit
     		   		end
              end


		/* if theres a credit account, make that entry too*/
		if not @gloffsetacct is null
			begin
			update bJCDA Set Amount = Amount + ((-1 * @cost)+isnull(@taxamt,0))
			--	#132073 - CHS
			--            where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType=@gltype and GLCo=@glco and GLAcct=@gloffsetacct and BatchSeq=@seq and OldNew=1
			where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType=@gltype and GLCo=@jcglco and GLAcct=@gloffsetacct and BatchSeq=@seq and OldNew=1
			if @@rowcount = 0
				Begin
				insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
						CostTrans, Job, Phase, CostType, JCTransType,
						ActDate, Description, Amount, Material)
				values (@co, @mth, @batchid, @gltype, @jcglco, @gloffsetacct, @seq, 1,
						@costtrans, @job, @phase, @costtype, @jctranstype,
						@actualdate, @description, (-1 * @cost)+isnull(@taxamt,0),@material)
				if @@rowcount = 0
					begin
					select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
					goto bspexit
					end
				end
			end -- end gl account offset


		-- Tax Accounts for JC MatUse
		If @taxcode is not null and @taxamt <> 0 and @source='JC MatUse' and @jctranstype = 'MI'
			begin
			--Insert Job Expense Tax Account
			update bJCDA Set Amount = Amount + @taxamt
			where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@glco and GLAcct=@taxglacct and BatchSeq=@seq and OldNew=1
			if @@rowcount = 0
				begin
				insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
					CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount,Material)
				values (@co, @mth, @batchid, @gltype, @glco, @taxglacct, @seq, 1,
					@costtrans, @job, @taxphase, @taxct, @jctranstype, @actualdate, @description, (@taxamt),@material)
				if @@rowcount = 0
					begin
					select @errmsg = 'Unable to JC Detail audit!', @rcode = 1
					goto bspexit
					end
                end
			
			---- update JCCB TaxGLTransAcct
			update bJCCB set TaxGLTransAcct = @taxglacct
			where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq

			--Insert tax accual account--------------------here
            update bJCDA Set Amount = Amount + (-1 * @taxamt)
			where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType=@gltype and GLCo=@glco and GLAcct=@taxaccuralacct and BatchSeq=@seq and OldNew=1
			if @@rowcount = 0              
				begin
				insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
					CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount,Material)
				values (@co, @mth, @batchid, @gltype, @glco, @taxaccuralacct, @seq, 1,
				@costtrans, @job, @taxphase, @taxct, @jctranstype, @actualdate, @description, (-1 * @taxamt),@material)
     			if @@rowcount = 0
					begin
					select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
					goto bspexit
					end
				 end
   
			end -- end tax accounts

                 /* If an Intercompany transaction create payable and receivable distributions */
                 if @glco <> @jcglco and @jctranstype = 'IC'
                   begin
                   select @interamt = -((@cost)-isnull(@taxamt,0))
                   exec @rcode = bspJCCBValIntercompany  @glco, @jcglco, @co, @mth, @batchid, @seq, 1,
        	                        @costtrans, @job, @phase, @costtype, @jctranstype, @actualdate, @description,
                                 @interamt, @inco, @loc, @material, @errmsg output
                    if @rcode <> 0
                      begin
         		        select @errortext = @errorstart + ' Intercompany - ' + isnull(@errmsg,'')
                         exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        		          	if @rcode <> 0 goto bspexit
        	             end
                  end -- end Intercompany validaiton
   
     	   end -- end transtype<>D
          end  -- end transtype<>C
         end -- end jctranstype <> MS



if @source = 'JC MatUse'
	begin
	if (@transtype <> 'A' and @oldjctranstype = 'IN')
		begin
		--insert 'old' entry for posted GL Account
		update dbo.bJCDA Set Amount = Amount +  (-1*@oldc3)
		where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@oldglco and GLAcct=@oldgltransacct and BatchSeq=@seq and OldNew=0
		if @@rowcount = 0
			begin
			insert into dbo.bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
					CostTrans, Job, Phase, CostType, JCTransType,
					ActDate, Description, Amount, INCo, Loc, Material)
			values (@co, @mth, @batchid, @gltype, @oldglco, @oldgltransacct, @seq, 0,
					@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype,
					@oldactualdate, @olddescription, (-1*@oldc3), @oldinco, @oldloc, @oldmaterial)
			if @@rowcount = 0
				begin
				select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
				goto bspexit
				end
			end
			
		-- insert job sale account
		update dbo.bJCDA Set Amount = Amount +  (@oldc3)
		where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@oldinglco and GLAcct=@jobsalesacct and BatchSeq=@seq and OldNew=0
		if @@rowcount = 0
			begin
			insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
					CostTrans, Job, Phase, CostType, JCTransType,
					ActDate, Description, Amount, INCo, Loc, Material)
			values (@co, @mth, @batchid, @gltype, @oldinglco, @jobsalesacct, @seq, 0,
					@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype,
					@oldactualdate, @olddescription, (@oldc3), @oldinco, @oldloc, @oldmaterial)
		if @@rowcount = 0
			begin
			select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
			goto bspexit
			end
		end

	if @oldglco <> @oldinglco
		begin
		select @interamt = (@oldc3)
		exec @rcode = bspJCCBValIntercompany  @oldglco, @oldinglco, @co, @mth, @batchid, @seq, 0,
				@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype, @oldactualdate, @olddescription,
				@interamt, @inco, @loc, @material, @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + '- ' + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
		end -- end Intercompany validaiton
   
	-- Insert Cost Of Goods Sold Account
	update bJCDA Set Amount = Amount + (-1*@oldc2)
	where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@oldinglco and GLAcct=@cogsacct and BatchSeq=@seq and OldNew=0
	if @@rowcount = 0
		begin
		insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
				CostTrans, Job, Phase, CostType, JCTransType,
				ActDate, Description, Amount, INCo, Loc, Material)
		values (@co, @mth, @batchid, @gltype, @oldinglco, @cogsacct, @seq, 0,
				@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype,
				@oldactualdate, @olddescription, (-1*@oldc2), @oldinco, @oldloc, @oldmaterial)
		if @@rowcount = 0
			begin
			select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
			goto bspexit
			end
		end

	if @oldglco <> @oldinglco
		begin
		select @interamt = (-1*@oldc2)
		exec @rcode = bspJCCBValIntercompany  @oldglco, @oldinglco, @co, @mth, @batchid, @seq, 0,
				@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype, @oldactualdate, @olddescription,
				@interamt, @inco, @loc, @material, @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + '- ' + @errmsg
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
		end -- end Intercompany validaiton
   
	-- Insert Inventory Account
	update dbo.bJCDA Set Amount = Amount + (@oldc2)
	where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@oldinglco and GLAcct=@inventoryacct and BatchSeq=@seq and OldNew=0
	if @@rowcount = 0
		begin
		insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
				CostTrans, Job, Phase, CostType, JCTransType,
				ActDate, Description, Amount, INCo, Loc, Material)
		values (@co, @mth, @batchid, @gltype, @oldinglco, @inventoryacct, @seq, 0,
				@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype,
				@oldactualdate, @olddescription, (@oldc2), @oldinco, @oldloc, @oldmaterial)
		if @@rowcount = 0
			begin
			select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
			goto bspexit
			end
		end

	if @oldglco <> @oldinglco
		begin
		select @interamt = (@oldc2)
		exec @rcode = bspJCCBValIntercompany  @oldglco, @oldinglco, @co, @mth, @batchid, @seq, 0,
				@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype, @oldactualdate, @olddescription,
				@interamt, @inco, @loc, @material, @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + '- ' + @errmsg
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			end
		end -- end Intercompany validaiton
   
	-- insert Job sale quantiy account
	if not @jobsalesqtyacct is null
		begin
		update dbo.bJCDA Set Qty = Qty + (@oldstdunits)
		where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='QTY' and GLCo=@oldinglco and GLAcct= @jobsalesqtyacct and BatchSeq=@seq and OldNew=0
		if @@rowcount = 0
			begin
			insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
					CostTrans, Job, Phase, CostType, JCTransType,
					ActDate, Description, Amount, INCo, Loc, Material, Qty)
			values (@co, @mth, @batchid, 'QTY', @oldinglco, @jobsalesqtyacct, @seq, 0,
					@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype,
					@oldactualdate, @olddescription, 0, @oldinco, @oldloc, @oldmaterial, (@oldstdunits))
			if @@rowcount = 0
				begin
				select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
				goto bspexit
				end
			end
		end -- end old job sale quanity account
   
	If @oldtaxcode is not null and @oldtaxamt <> 0
		begin
		--Insert Job Expense Tax Account
		update dbo.bJCDA Set Amount = Amount - @oldtaxamt
		--	#132073 - CHS
		--				where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@glco and GLAcct=@taxglacct and BatchSeq=@seq and OldNew=0
		where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@oldglco and GLAcct=@taxglacct and BatchSeq=@seq and OldNew=0
		if @@rowcount = 0
			Begin
			--Insert Job Expense Tax Account
			insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
					CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount, Material)
			values (@co, @mth, @batchid, @gltype, @oldglco, @taxglacct, @seq, 0,
					@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype, @oldactualdate, @olddescription, (-@oldtaxamt),@oldmaterial)
			if @@rowcount = 0
				begin
				select @errmsg = 'Unable to JC Detail audit!', @rcode = 1
				goto bspexit
				end
			end

		--Insert tax accual account
		update dbo.bJCDA Set Amount = Amount + (@oldtaxamt)
		where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@oldinglco and GLAcct= @taxaccuralacct and BatchSeq=@seq and OldNew=0
		if @@rowcount = 0
			begin
			insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
				CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount,Material)
			values (@co, @mth, @batchid, @gltype, @oldinglco, @taxaccuralacct, @seq, 0,
				@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype, @oldactualdate, @olddescription, ( @oldtaxamt),@oldmaterial)
			if @@rowcount = 0
				begin
				select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
				goto bspexit
				end
			end

		if @oldglco <> @oldinglco
			begin
			select @interamt = (@oldtaxamt)
			exec @rcode = bspJCCBValIntercompany  @glco, @oldinglco, @co, @mth, @batchid, @seq, 0,
				@costtrans, @oldjob, @oldphase, @oldcosttype, @oldjctranstype, @oldactualdate, @olddescription,
				@interamt, @inco, @loc, @material, @errmsg output
			if @rcode <> 0
				begin
				select @errortext = @errorstart + '- ' + @errmsg
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
			end -- end Intercompany validaiton
		end -- end old tax amounts
	end -- end where @transtype<>'A'
                
              -- 'New' IN distributions
              If (@transtype<>'D' and @jctranstype='IN')
            begin
      	        --insert entry for Adjustment
                           update bJCDA
                           Set Amount = Amount +  (-1 * @c3)
        where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@glco and GLAcct= @gltransacct and BatchSeq=@seq and OldNew=1
     	         if @@rowcount = 0
                           begin
     	        insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
     		       		CostTrans, Job, Phase, CostType, JCTransType,
     			    	ActDate, Description, Amount, INCo, Loc, Material)
      			values (@co, @mth, @batchid, @gltype, @glco, @gltransacct, @seq, 1,
        				@costtrans, @job, @phase, @costtype, @jctranstype,
     				@actualdate, @description, (-1 * @c3), @inco, @loc, @material)
     			if @@rowcount = 0
     		   		begin
     		    		select @errmsg = 'Unable to JC Detail audit!', @rcode = 1
     		     		goto bspexit
     		   		end
                            end
     	        -- insert job sale account
                           update bJCDA
                           Set Amount = Amount +  ( @c3)
              where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@inglco and GLAcct= @jobsalesacct and BatchSeq=@seq and OldNew=1
     	         if @@rowcount = 0
                           begin
     	         insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
       		       		    CostTrans, Job, Phase, CostType, JCTransType,
     				        ActDate, Description, Amount, INCo, Loc, Material)
      			    values (@co, @mth, @batchid, @gltype, @inglco, @jobsalesacct, @seq, 1,
        				    @costtrans, @job, @phase, @costtype, @jctranstype,
     				    @actualdate, @description, (@c3), @inco, @loc, @material)
     			 if @@rowcount = 0
     		   		begin
     		    		select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
     		     		goto bspexit
     		   		end
                             end
   
                 if @glco <> @inglco
                   begin
                   select @interamt = (@c3)
                   exec @rcode = bspJCCBValIntercompany  @glco, @inglco, @co, @mth, @batchid, @seq, 1,
        	                        @costtrans, @job, @phase, @costtype, @jctranstype, @actualdate, @description,
                                 @interamt, @inco, @loc, @material, @errmsg output
                    if @rcode <> 0
                      begin
         		        select @errortext = @errorstart + '- ' + @errmsg
                        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        		        	if @rcode <> 0 goto bspexit
        	           end
                  end -- end Intercompany validaiton
   
      	        --Insert Cost Of Goods Sold Account
                           update bJCDA
                           Set Amount = Amount + (-1*@c2)
                           where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@inglco and GLAcct= @cogsacct and BatchSeq=@seq and OldNew=1
     	         if @@rowcount = 0
                           begin
     	         insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
     		       		CostTrans, Job, Phase, CostType, JCTransType,
     			    	ActDate, Description, Amount, INCo, Loc, Material)
      			values (@co, @mth, @batchid, @gltype, @inglco, @cogsacct, @seq, 1,
        				@costtrans, @job, @phase, @costtype, @jctranstype,
     				@actualdate, @description, (-1*@c2), @inco, @loc, @material)
     			if @@rowcount = 0
     		   		begin
     		    		select @errmsg = 'Unable to JC Detail audit!', @rcode = 1
     		     		goto bspexit
     		   		end
                           end
   
   
                 if @glco <> @inglco
                   begin
                   select @interamt = (@c2)
                   exec @rcode = bspJCCBValIntercompany  @glco, @inglco, @co, @mth, @batchid, @seq, 1,
        	                        @costtrans, @job, @phase, @costtype, @jctranstype, @actualdate, @description,
                                 @interamt, @inco, @loc, @material, @errmsg output
                    if @rcode <> 0
                      begin
         		        select @errortext = @errorstart + '- ' + @errmsg
           exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        		          	if @rcode <> 0 goto bspexit
        	             end
                  end -- end Intercompany validaiton
   
     	        --Insert Inventory Account
                           update bJCDA
                           Set Amount = Amount + (@c2)
                           where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@inglco and GLAcct= @inventoryacct and BatchSeq=@seq and OldNew=1
     	         if @@rowcount = 0
                           begin
     	        insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
       		       		    CostTrans, Job, Phase, CostType, JCTransType,
     				        ActDate, Description, Amount, INCo, Loc, Material)
      			values (@co, @mth, @batchid, @gltype, @inglco, @inventoryacct, @seq, 1,
        				    @costtrans, @job, @phase, @costtype, @jctranstype,
     				    @actualdate, @description, (@c2), @inco, @loc, @material)
     			if @@rowcount = 0
     		   		begin
     		    		select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
     		     		goto bspexit
     		   		end
                            end
   
                 if @glco <> @inglco
                   begin
                   select @interamt = (-1*@c2)
                   exec @rcode = bspJCCBValIntercompany  @glco, @inglco, @co, @mth, @batchid, @seq, 1,
        	                        @costtrans, @job, @phase, @costtype, @jctranstype, @actualdate, @description,
                                 @interamt, @inco, @loc, @material, @errmsg output
                    if @rcode <> 0
                      begin
         		        select @errortext = @errorstart + '- ' + @errmsg
                         exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        		          	if @rcode <> 0 goto bspexit
        	             end
                  end -- end Intercompany validaiton
   
            -- insert Job sale quantiy account
     	     if not @jobsalesqtyacct is null
         begin
           update bJCDA
                           Set Qty = Qty + (-1*@stdunits)
                           where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='QTY' and GLCo=@inglco and GLAcct= @jobsalesqtyacct and BatchSeq=@seq and OldNew=1
     	         if @@rowcount = 0
                           begin
     	         insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
       		       		    CostTrans, Job, Phase, CostType, JCTransType,
     				        ActDate, Description, Amount, INCo, Loc, Material, Qty)
      			    values (@co, @mth, @batchid, 'QTY', @inglco, @jobsalesqtyacct, @seq, 1,
        				    @costtrans, @job, @phase, @costtype, @jctranstype,
     				    @actualdate, @description, 0, @inco, @loc, @material, (-1*@stdunits))
     			if @@rowcount = 0
     		   		begin
     		    		select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
     		     		goto bspexit
     		   		end
                           end
                  end -- end old job sale quanity account
   
		If @taxcode is not null and @taxamt <> 0
			begin
			--Insert Job Expense Tax Account
			update bJCDA Set Amount = Amount + @taxamt
			where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@glco and GLAcct=@taxglacct and BatchSeq=@seq and OldNew=1
			if @@rowcount = 0
				begin
				insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
					CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount)
				values (@co, @mth, @batchid, @gltype, @glco, @taxglacct, @seq, 1,
					@costtrans, @job, @taxphase, @taxct, @jctranstype, @actualdate, @description, (@taxamt))
				if @@rowcount = 0
					begin
					select @errmsg = 'Unable to JC Detail audit!', @rcode = 1
					goto bspexit
					end
				end  -- if not exist
   
			---- update JCCB TaxGLTransAcct
			update bJCCB set TaxGLTransAcct = @taxglacct
			where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq

			--Insert tax accual account
			update bJCDA Set Amount = Amount + (-1 * @taxamt)
--	#132073 - CHS
			--where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@glco and GLAcct=@taxaccuralacct and BatchSeq=@seq and OldNew=1
			where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@inglco and GLAcct=@taxaccuralacct and BatchSeq=@seq and OldNew=1
			if @@rowcount = 0
				begin
				insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
					CostTrans, Job, Phase, CostType, JCTransType, ActDate, Description, Amount, Material)
				values (@co, @mth, @batchid, @gltype, @inglco, @taxaccuralacct, @seq, 1,
					@costtrans, @job, @taxphase, @taxct, @jctranstype, @actualdate, @description, (-1 * @taxamt),@material)
				if @@rowcount = 0
					begin
					select @errmsg = 'Unable to add JC Detail audit!', @rcode = 1
					goto bspexit
					end
				end
   
                 if @glco <> @inglco
                   begin
                   select @interamt = (-1 * @taxamt)
                   exec @rcode = bspJCCBValIntercompany  @glco, @inglco, @co, @mth, @batchid, @seq, 1,
        	                        @costtrans, @job, @taxphase, @taxct, @jctranstype, @actualdate, @description,
                                 @interamt, @inco, @loc, @material, @errmsg output
                    if @rcode <> 0
                      begin
         		        select @errortext = @errorstart + '- ' + @errmsg
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        		          	if @rcode <> 0 goto bspexit
        	             end
                  end -- end Intercompany validaiton
   
                 end -- end tax accounts
               end -- end where @transtpye <> 'D'
          end -- @jctranstype = 'IN'



GOTO JCCB_loop


----------------------------------
-- finished with cost adjustment entries --
----------------------------------
JCCB_end:   
	close bcJCCB
	deallocate bcJCCB
	set @opencursor = 0


/* check GL totals - This should always be in balance  */
select @glco = GLCo, @balamt=isnull(sum(Amount),0) 
from dbo.bJCDA where JCCo = @co and Mth = @mth and BatchId = @batchid
group by GLCo
having isnull(sum(Amount),0) <> 0
if @@rowcount <> 0
	begin
	select @errortext =  'GL Company ' + isnull(convert(varchar(3), @glco),'') + ' entries do not balance!'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	end

/* check HQ Batch Errors and update HQ Batch Control status */
select @status = 3	/* valid - ok to post */
if exists(select * from dbo.bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @status = 2	/* validation errors */
	end
	
update bHQBC set Status = @status
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	end




bspexit:
	if @opencursor = 1
		begin
		close bcJCCB
		deallocate bcJCCB
		end
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCBVal] TO [public]
GO
