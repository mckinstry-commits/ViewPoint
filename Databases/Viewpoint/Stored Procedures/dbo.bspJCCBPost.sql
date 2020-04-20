SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**********************************************************/
CREATE procedure [dbo].[bspJCCBPost]
     /***********************************************************
      * CREATED BY: 	SE     12/09/1996
      * MODIFIED By : 	GG     01/26/1999
      *				GG     10/07/1999 - Fix for null GL Description Control
      *				DANF   11/14/1999 - Fix change for additional Fields
      *				DANF   03/02/2000 - change for additional fields.
      *				DANF   03/13/2000 - Fixed updated of actualdate change.
      *				DANF   03/21/2000 - Added update for inventory.
      *				DANF   05/18/2000 - Added Shift
      *				DANF   05/23/2000 - Added source
      *				DANF   10/18/2000 - Added Attachement
      *				GG     11/27/2000 - changed datatype from bAPRef to bAPReference
      *				ALLENN 04/24/2001 - Added isnull to description roll up to prevent
      *                                    string from terminating prematurely (issue#13150)
      *				MV     06/20/2001 - Issue 12769 BatchUserMemoUpdate
      *				DANF   01/18/2002 - Update Acutal unit cost and per ecm if units and Dollars
      *				TV/RM  02/22/2002 - Attachment Fix
      *				DANF   04/03/2002 - Added InterCompany Cost Adjustment Tranactions.
      *				CMW    04/04/2002 - added bHQBC.Notes interface levels update (issue # 16692).
      *				GG     04/08/2002 - #16702 - remove parameter from bspBatchUserMemoUpdate
      *				GG     07/18/2002 - #18001 - update CostTrans to bJCCB for user memo update
      *				TV                - #23061 added isnulls
      *				GWC    04/13/2004 - #18616 Moved re-index of attachment code to below the commit transaction
      *				DANF 05/06/2004 - # 24180 Correct Posted UM for Changed transactions.
      *				DANF 05/24/2005 - Issue 28754 Allocation code is not being updated to cost detail.
      *				DANF 09/29/2005 - Issue 28992 burden posted unit cost
	  *				DANF 10/29/2007 - Issue 125974 corrected datatype for mo from int to bMO.
	  *				GF 01/02/2008 - issue #126083 added with (NOLOCK) to select statements.
	  *				GP 07/08/2008 - Issue 120111 Plug @hours value into @amount column in bGLDT when expense 
	  *									account has a cross-refrenced memo account with type M - memo.
	  *				GF 07/25/2008 - issue #122986 for tax transactions write out UM, PostedUM, PostedECM, INStdECM, INStdUM use main trans values
	  *				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
	  *				DAN SO 02/03/09 - Issue 132131 - HQBC Flag(s) from wrong table and columns
	  *				Jonathan 05/29/09 - issue 133437 - Removed code that changes the TableName column in HQAT
	  *				GF 05/25/2010 - issue #137811 - post offset gl company to JCCD for material use.
	  *				gf 06/25/2010 - issue #135813 expanded SL to varchar(30)
	  *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
	  *				GF 09/07/2011 TK-08225 PO ITEM LINE
	  *                TL 01/18/2012 TK-11851 fixed spelling error (wuth) to with
      *
      * USAGE:
      * Posts a validated batch of JCCB entries
      * deletes successfully posted bJCCB rows
    
      * clears bJCDA and bHQCC when complete
      *
      * INPUT PARAMETERS
      *   JCCo        JC Co
      *   Month       Month of batch
      *   BatchId     Batch ID to validate
      *   PostingDate Posting date to write out if successful
      * OUTPUT PARAMETERS
      *   @errmsg     if something went wrong
      * RETURN VALUE
      *   0   success
      *   1   fail
      *****************************************************/
(@co bCompany, @mth bMonth,@batchid bBatchID,@dateposted bDate=null,@errmsg varchar(60) output)
as
set nocount on

declare @rcode int, @source bSource, @tablename char(20),
		@inuseby bVPUserName, @status tinyint, @seq int,

		@glcostlevel tinyint, @glcostoverride bYN, @glcostjournal bJrnl,
		@glcostdetaildesc varchar(60), @glcostsummarydesc varchar(30), @batchseq int,
		@glmatlevel tinyint, @glmatoverride bYN, @glmatjournal bJrnl,
		@glmatdetaildesc varchar(60), @glmatsummarydesc varchar(30),

		@transtype char(1), @costtrans bTrans, @job bJob, @PhaseGroup tinyint, @phase bPhase, @costtype bJCCType, @actualdate bDate,
		@jctranstype varchar(2), @description bTransDesc, @glco bCompany, @gltransacct bGLAcct,
		@gloffsetacct bGLAcct, @reversalstatus tinyint, @um bUM, @hours bHrs, @units bUnits,
		@cost bDollar, @glacct bGLAcct, @gltrans bTrans, @amount bDollar, @taxcosttrans bTrans,
		@origmth bMonth, @origcosttrans bTrans, @glref bGLRef,

		@prco bCompany,@employee bEmployee,@craft bCraft,@class bClass,@crew varchar(10),@earnfactor bRate,
		@earntype bEarnType,@shift tinyint,@liabilitytype bLiabilityType,@vendorgroup bGroup,@vendor bVendor,
		@apco bCompany,@aptrans bTrans,@apline smallint,@apref bAPReference,@po varchar(30),@poitem bItem,@sl VARCHAR(30),
		@slitem bItem,@mo bMO,@moitem bItem,@matlgroup bGroup,@material bMatl,@inco bCompany,
		@loc bLoc,@mstrans bTrans,@msticket varchar(30),@emco bCompany,@emequip bEquip,
		@emrevcode bRevCode,@emgroup bGroup, @pstum bUM, @pstunits bUnits, @pstunitcost bUnitCost,
		@pstecm bECM, @instdunitcost bUnitCost, @instdecm bECM, @instdum bUM, @taxtype tinyint,
		@taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxamt bDollar,
		@gltype varchar(3), @qty bUnits, @taxphase bPhase, @taxct bJCCType,
		@perecm bECM, @actualunitcost bUnitCost,

		@errorstart varchar(50), @subtype char(1), @stmtdate bDate, @inusebatchid bBatchID,
		@desccontrol varchar(60), @desc varchar(60), @findidx int,
		@found varchar(30), @oldnew tinyint, @lastseq int, @tax bYN,
		@updatekeyfield varchar(128), @ddfhformname varchar(30), @keyfield varchar(128),
		@guid UniqueIdentifier, @tojcco bCompany, @Notes varchar(256), @alloccode smallint,

		@memoacct bGLAcct, @taxgltransacct bGLAcct,
		----#137811
		@OffsetGLCo bCompany,
		----TK-08225
		@POItemLine INT

set nocount on

select @rcode = 0, @lastseq=0, @perecm = 'E'

/**** get GL interface info from JCCO ****/
select @glcostjournal = GLCostJournal, @glcostdetaildesc = GLCostDetailDesc,
		@glcostsummarydesc = GLCostSummaryDesc, @glcostlevel = GLCostLevel,
		@glmatjournal = GLMatJournal, @glmatdetaildesc = GLMatDetailDesc,
		@glmatsummarydesc = GLMatSummaryDesc, @glmatlevel = GLMaterialLevel
from bJCCO with (nolock) where JCCo = @co
if @@rowcount = 0
	begin
	select @errmsg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

/**** check for date posted ****/
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end

/**** validate HQ Batch ****/
select @source = 'JC CostAdj'
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'JCCB', @errmsg output, @status output
if @rcode <> 0
	begin
	select @source = 'JC MatUse'
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'JCCB', @errmsg output, @status output
	if @rcode <> 0 goto bspexit
	end

if @status <> 3 and @status <> 4	/**** valid - OK to post, or posting in progress ****/
	begin
	select @errmsg = 'Invalid Batch status -  must be Valid - OK to Post or Posting in Progress!', @rcode = 1
	goto bspexit
	end

/**** set HQ Batch status to 4 (posting in progress) ****/
update bHQBC set Status = 4, DatePosted = @dateposted
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end




/**** loop through all rows in this batch ****/
select @seq = min(BatchSeq) from bJCCB with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid
while @seq is not null
BEGIN

	select @source=Source, @transtype=TransType, @costtrans=CostTrans, @job=Job, @PhaseGroup=PhaseGroup,
		@phase=Phase, @costtype=CostType, @actualdate=ActualDate, @jctranstype=JCTransType,
		@description=Description, @glco=GLCo, @gltransacct=GLTransAcct, @gloffsetacct=GLOffsetAcct,
		@reversalstatus=ReversalStatus, @origmth=OrigMth, @origcosttrans=OrigCostTrans, @um=UM,
		@hours=IsNull(Hours,0), @units=IsNull(Units,0), @cost=IsNull(Cost,0),@prco=PRCo,@employee=Employee,
		@craft=Craft,@class=Class,@crew=Crew,@earnfactor=EarnFactor,@earntype=EarnType,@shift=Shift,
		@liabilitytype=LiabilityType,@vendorgroup=VendorGroup,@vendor=Vendor,@apco=APCo,@aptrans=APTrans,
		@apline=APLine,@apref=APRef,@po=PO,@poitem=POItem,@sl=SL,@slitem=SLItem,@mo=MO,@moitem=MOItem,
		@matlgroup=MatlGroup,@material=Material,@inco=INCo,@loc=Loc,@mstrans=MSTrans,@msticket=MSTicket,
		@emco=EMCo,@emequip=EMEquip,@emrevcode=EMRevCode,@emgroup=EMGroup, @pstum=PstUM,
		@pstunits=isnull(PstUnits,0), @pstunitcost=isnull(PstUnitCost,0),@pstecm=PstECM,
		@instdunitcost=isnull(INStdUnitCost,0), @instdecm=INStdECM, @instdum=INStdUM, @taxtype=TaxType,
		@taxgroup=TaxGroup,@taxcode=TaxCode,@taxbasis=isnull(TaxBasis,0),@taxamt=isnull(TaxAmt,0),
		@taxphase=TaxPhase,@taxct=TaxCostType,@guid=UniqueAttchID,@tojcco=ToJCCo,@alloccode=AllocCode,
		@taxgltransacct=TaxGLTransAcct,
		----#137811
		@OffsetGLCo=OffsetGLCo,
		----TK-08225
		@POItemLine=POItemLine
	from dbo.bJCCB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq

	if @jctranstype <> 'IC' select @tojcco = @co

	begin transaction

	select @ddfhformname = 'JCCOSTADJ'
	if @source = 'JC MatUse' select @ddfhformname = 'JCMatUse'
	if isnull(@taxgltransacct,'') = '' set @taxgltransacct = null

	if @transtype = 'A'	/**** add new JC Detail Transaction ****/
		begin
		/**** get next available transaction # for JCCD ****/
		select @tablename = 'bJCCD'
		exec @costtrans = bspHQTCNextTrans @tablename, @tojcco, @mth, @errmsg output
		if @costtrans = 0 goto jc_posting_error

		/**** update GL with cost trans *****/
		update bJCDA set CostTrans=@costtrans
		where JCCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq

		/** Check for redirection of phase and cost type **/
		select @tax = 'N'
		if not @taxcode is null and not @taxgroup is null and @taxamt <> 0
			begin
			if not @taxphase is null or not @taxct is null
				begin
				select @tax = 'Y'
				if @taxphase is null select @taxphase = @phase
				if @taxct is null select @taxct = @costtype
				end
			end

   		--Moved this code below commit transaction to address rejection for #18616
   		-- issue 18616 Refresh indexes for this header if attachments exist
   		--if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null
     
		If @tax = 'Y'
			begin
			/**** insert JC Detail with out tax ****/
			begin
			select @actualunitcost = 0
			if @units <> 0 and (@cost-@taxamt) <> 0 select @actualunitcost = (@cost-@taxamt)/@units

			insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
				JCTransType, Source, Description, BatchId, GLCo, GLTransAcct, GLOffsetAcct,
				ReversalStatus, PostedUM, UM, ActualUnitCost, PerECM, ActualHours, ActualUnits, ActualCost,
				PRCo,Employee,Craft,Class,Crew,EarnFactor,EarnType,Shift,LiabilityType,VendorGroup,
				Vendor,APCo,APTrans,APLine,APRef,PO,POItem,SL,SLItem,MO,MOItem,MatlGroup,Material,
				INCo,Loc,MSTrans,MSTicket,EMCo,EMEquip,EMRevCode,EMGroup,PostedUnits,PostedUnitCost,
				PostedECM,INStdUnitCost,INStdECM,INStdUM,TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,
				UniqueAttchID, SrcJCCo, AllocCode,
				----#137811
				OffsetGLCo,
				----TK-08225
				POItemLine)
			values (@tojcco, @mth, @costtrans, @job, @PhaseGroup, @phase, @costtype, @dateposted, @actualdate,
				@jctranstype, @source, @description, @batchid, @glco, @gltransacct, @gloffsetacct,
				@reversalstatus, @pstum, @um, @actualunitcost, @perecm, @hours, @units, (@cost-@taxamt),
				@prco, @employee, @craft, @class,@crew,@earnfactor,@earntype,@shift,@liabilitytype,
				@vendorgroup,@vendor,@apco,@aptrans,@apline,@apref,	@po,@poitem,@sl,@slitem,@mo,@moitem,
				@matlgroup,@material,@inco,@loc,@mstrans,@msticket,@emco,@emequip,@emrevcode,@emgroup,
				@pstunits,@pstunitcost,@pstecm,@instdunitcost,@instdecm,@instdum,@taxtype,@taxgroup,
				@taxcode,0,0, @guid, @co, @alloccode,
				----#137811
				@OffsetGLCo,
				----TK-08225
				@POItemLine)
			if @@rowcount = 0 goto jc_posting_error

			-- update Trans back to batch table for user memo update
			update bJCCB set CostTrans = @costtrans
			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq
			if @@rowcount <> 1 goto jc_posting_error
			end

			/**** insert JC Detail with tax ****/
			begin
			select @tablename = 'bJCCD'
			exec @taxcosttrans = bspHQTCNextTrans @tablename, @tojcco, @mth, @errmsg output
			if @taxcosttrans = 0 goto jc_posting_error

			select @actualunitcost = 0

			insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
				JCTransType, Source, Description, BatchId, GLCo, GLTransAcct, GLOffsetAcct,
				ReversalStatus, PostedUM, UM, ActualUnitCost, PerECM, ActualHours, ActualUnits, ActualCost,
				PRCo,Employee,Craft,Class,Crew,EarnFactor,EarnType,Shift,LiabilityType,VendorGroup,
				Vendor,APCo,APTrans,APLine,APRef,PO,POItem,SL,SLItem,MO,MOItem,MatlGroup,Material,
				INCo,Loc,MSTrans,MSTicket,EMCo,EMEquip,EMRevCode,EMGroup,PostedUnits,PostedUnitCost,
				PostedECM,INStdUnitCost,INStdECM,INStdUM,TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,
				UniqueAttchID, SrcJCCo, AllocCode,
				----#137811
				OffsetGLCo,
				----TK-08225
				POItemLine)
			values (@tojcco,@mth,@taxcosttrans,@job,@PhaseGroup,@taxphase,@taxct,@dateposted,@actualdate,
				@jctranstype, @source, @description, @batchid, @glco, @taxgltransacct, NULL,
				0, @pstum, @um, @actualunitcost, @perecm, 0, 0, @taxamt, @prco, @employee, @craft, @class,
				@crew,@earnfactor,@earntype,@shift,@liabilitytype,@vendorgroup,@vendor,@apco,@aptrans,@apline,
				@apref,	@po,@poitem,@sl,@slitem,@mo,@moitem,@matlgroup,@material,@inco,@loc,
				@mstrans,@msticket,@emco,@emequip,@emrevcode,@emgroup,
				0, 0,@pstecm,0,@instdecm,@instdum,@taxtype,@taxgroup,@taxcode,@taxbasis,@taxamt,
				@guid, @co, @alloccode,
				----#137811
				@OffsetGLCo,
				----TK-08225
				@POItemLine)
			if @@rowcount = 0 goto jc_posting_error
			end
		end

		if @tax = 'N'
		begin

		select @actualunitcost = 0
		if @units <> 0 and (@cost) <> 0 select @actualunitcost = (@cost)/@units

		-- issue 28992 burden posted unit cost
		if isnull(@taxamt,0)<>0 and isnull(@units,0)<>0  select @pstunitcost = @cost/@pstunits

		/**** insert JC Detail ****/
		insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
			JCTransType, Source, Description, BatchId, GLCo, GLTransAcct, GLOffsetAcct,
			ReversalStatus, PostedUM, UM, ActualUnitCost, PerECM, ActualHours, ActualUnits, ActualCost,
			PRCo,Employee,Craft,Class,Crew,EarnFactor,EarnType,Shift,LiabilityType,VendorGroup,
			Vendor,APCo,APTrans,APLine,APRef,PO,POItem,SL,SLItem,MO,MOItem,MatlGroup,Material,
			INCo,Loc,MSTrans,MSTicket,EMCo,EMEquip,EMRevCode,EMGroup,PostedUnits,PostedUnitCost,
			PostedECM,INStdUnitCost,INStdECM,INStdUM,TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,
			UniqueAttchID, SrcJCCo, AllocCode,
			----#137811
			OffsetGLCo,
			----TK-08225
			POItemLine)
		values (@tojcco, @mth, @costtrans, @job, @PhaseGroup, @phase, @costtype, @dateposted, @actualdate,
			@jctranstype, @source, @description, @batchid, @glco, @gltransacct, @gloffsetacct,
			@reversalstatus, @pstum, @um,  @actualunitcost, @perecm, @hours, @units, @cost, 
			@prco, @employee, @craft, @class,@crew,@earnfactor,@earntype,@shift,@liabilitytype,
			@vendorgroup,@vendor,@apco,@aptrans,@apline,@apref,	@po,@poitem,@sl,@slitem,@mo,@moitem,
			@matlgroup,@material,@inco,@loc,@mstrans,@msticket,@emco,@emequip,@emrevcode,@emgroup,
			@pstunits,@pstunitcost,@pstecm,@instdunitcost,@instdecm,@instdum,@taxtype,@taxgroup,
			@taxcode,@taxbasis,@taxamt, @guid, @co, @alloccode,
			----#137811
			@OffsetGLCo,
			----TK-08225
			@POItemLine)
		if @@rowcount = 0 goto jc_posting_error

		-- update Trans back to batch table for user memo update
		update bJCCB set CostTrans = @costtrans
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq
		if @@rowcount <> 1 goto jc_posting_error
		end

		/**** If new transaction is a reversing entry then flag the original entry as reversed ****/
		if @reversalstatus = 2
			begin
			update bJCCD set ReversalStatus = 3
			where JCCo=@tojcco and Mth=@origmth and CostTrans=@origcosttrans
			end

		/**** If new transaction is canceling reversing entry then flag the original entry as not reversing ****/
		if @reversalstatus = 4
			begin
			update bJCCD set ReversalStatus = 0
			where JCCo=@tojcco and Mth=@origmth and CostTrans=@origcosttrans
			end
		end

		
	if @transtype = 'C'	/**** update existing JC Cost Detail Transaction ****/
		begin
		
		select @actualunitcost = 0
   
   		--Moved this code below commit transaction to address rejection for #18616 			
   		-- issue 18616 Refresh indexes for this header if attachments exist
   		--if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null

		if @units <> 0 and (@cost) <> 0 select @actualunitcost = (@cost)/@units

		-- issue 28992 burden posted unit cost
		if isnull(@taxamt,0)<>0 and isnull(@units,0)<>0 select @pstunitcost = @cost/@pstunits

		---- update JCCD
		update dbo.bJCCD set Job = @job, PhaseGroup = @PhaseGroup, Phase=@phase, CostType=@costtype,
			PostedDate = @dateposted, ActualDate=@actualdate, JCTransType=@jctranstype, Source=@source,
			Description = @description, BatchId=@batchid, GLCo=@glco, GLTransAcct=@gltransacct,
			GLOffsetAcct=@gloffsetacct,  ReversalStatus=@reversalstatus, PostedUM=@pstum,
			UM=@um, ActualUnitCost=@actualunitcost, PerECM=@perecm, ActualHours=@hours, 
			ActualUnits=@units, ActualCost=@cost, PRCo=@prco, Employee=@employee, Craft=@craft, 
			Class=@class, Crew=@crew, EarnFactor=@earnfactor, EarnType=@earntype, Shift=@shift,
			LiabilityType=@liabilitytype, VendorGroup=@vendorgroup, Vendor=@vendor, APCo=@apco,
			APTrans=@aptrans, APLine=@apline, APRef=@apref, PO=@po, POItem=@poitem, SL=@sl,
			SLItem=@slitem, MO=@mo, MOItem=@moitem, MatlGroup=@matlgroup, Material=@material,
			INCo=@inco, Loc=@loc, MSTrans=@mstrans, MSTicket=@msticket, EMCo=@emco, EMEquip=@emequip,
			EMRevCode=@emrevcode,EMGroup=@emgroup, PostedUnits=@pstunits, PostedUnitCost=@pstunitcost,
			PostedECM=@pstecm, INStdUnitCost=@instdunitcost, INStdECM=@instdecm, INStdUM=@instdum,
			TaxType=@taxtype, TaxGroup=@taxgroup, TaxCode=@taxcode, TaxBasis=@taxbasis, TaxAmt=@taxamt,
			InUseBatchId=null, UniqueAttchID = @guid, SrcJCCo = @co,
			----#137811
			OffsetGLCo = @OffsetGLCo,
			----TK-08225
			POItemLine = @POItemLine
			where JCCo = @tojcco and Mth = @mth and CostTrans = @costtrans
			if @@rowcount = 0 goto jc_posting_error
		end

	if @transtype = 'D'	/**** delete existing JC Detail Transaction ****/
		begin
		delete bJCCD where JCCo = @tojcco and Mth = @mth and CostTrans = @costtrans
		if @@rowcount = 0
		goto jc_posting_error
		end

	if @transtype in ('C','A')
		begin
		/* call bspBatchUserMemoUpdate to update user memos in bJCCD before deleting the batch record */
		exec @rcode = bspBatchUserMemoUpdate @tojcco, @mth, @batchid, @seq, @ddfhformname, @errmsg output
		if @rcode <> 0
		begin
		select @errmsg = 'Unable to update User Memo in JCCD.', @rcode = 1
		goto jc_posting_error
		end
	end

	/**** commit transaction ****/
	delete from bJCCB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq

	commit transaction
   
	if @transtype in ('A', 'C')
		begin
		if @guid is not null 
			begin
			exec bspHQRefreshIndexes null, null, @guid, null
			end
		end


	goto jc_posting_next


	jc_posting_error:		/**** error occured within transaction - rollback any updates and continue ****/
		select @errmsg
		rollback transaction

	jc_posting_next:
		select @seq=min(BatchSeq) from bJCCB with (nolock) 
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq>@seq
END


/************/
/**** make sure batch is empty ****/
if exists(select TOP 1 1 from bJCCB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all JC Cost batch entries were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end

glcost_update:	/**** update GL Cost using entries from bJCDA ****/
if @glcostlevel = 0	 /**** no update ****/
	begin
	delete bJCDA where JCCo = @co and Mth = @mth and BatchId = @batchid and (JCTransType <> 'MI' and JCTransType <> 'IN')
	goto glcost_update_end
	end

/**** set GL Reference using Batch Id - right justified 10 chars ****/
select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)

if @glcostlevel = 1	 /**** summary - one entry per GL Co/GLAcct, unless GL Acct flagged for detail do not include JCTransType of MS ****/
	begin
	/* get glco */
	select @glco=min(GLCo) from bJCDA with (nolock) where JCCo=@co and Mth=@mth and BatchId=@batchid and (JCTransType <> 'MI' AND JCTransType <> 'IN')
	while @glco is not null
	begin
    
		/* get glacct */
 		select @glacct=min(c.GLAcct)
		from bJCDA c with (nolock) join bGLAC g with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct and g.InterfaceDetail='N'
		where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and g.InterfaceDetail = 'N' and (c.JCTransType <> 'MI' AND c.JCTransType <> 'IN')
  		while @glacct is not null
		begin
			select @amount=convert(numeric(12,2),sum(c.Amount))
			from bJCDA c with (nolock)
			where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
			and c.GLAcct=@glacct and (c.JCTransType <> 'MI' AND c.JCTransType <> 'IN')

			begin transaction
			/**** get next available transaction # for GLDT ****/
			select @tablename = 'bGLDT'
           	exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
           	if @gltrans = 0 goto glcost_summary_posting_error

			insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate,
					DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
			values(@glco, @mth, @gltrans, @glacct, @glcostjournal, @glref, @co, @source, @dateposted,
					@dateposted, @glcostsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
			if @@rowcount = 0 goto glcost_summary_posting_error

			delete bJCDA where JCCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
			and GLAcct = @glacct and (JCTransType <> 'MI' AND JCTransType <> 'IN')
    
          	commit transaction
			goto glcost_summary_posting_end
    
     		glcost_summary_posting_error:	/**** error occured within transaction - rollback any updates and continue ****/
				rollback transaction

			glcost_summary_posting_end:	/**** no more rows to process ****/
			/* get next glacct */
			select @glacct=min(c.GLAcct)
     		from bJCDA c with (nolock)
     		join bGLAC g with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct and g.InterfaceDetail='N'
     		where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
			and g.InterfaceDetail = 'N' and c.GLAcct>@glacct and (c.JCTransType <> 'MI' AND c.JCTransType <> 'IN')
    	  	end

		/* get next glco */
		select @glco=min(GLCo) from bJCDA with (nolock) where JCCo=@co and Mth=@mth and BatchId=@batchid
		and GLCo>@glco and (JCTransType <> 'MI' AND JCTransType <> 'IN')
		end
	end


/**** detail update to GL for everything remaining in bJCDA ****/
    
/* get glco */
select @glco=min(GLCo) from bJCDA with (nolock) where JCCo=@co and Mth=@mth and BatchId=@batchid and (JCTransType <> 'MI' AND JCTransType <> 'IN')
while @glco is not null
begin
    
	/* get glacct */
	select @glacct=min(c.GLAcct)
	from bJCDA c with (nolock)
	where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and (c.JCTransType <> 'MI' AND c.JCTransType <> 'IN')
	
	while @glacct is not null
	begin
    
		/* get BatchSeq */
		select @batchseq=min(c.BatchSeq)
		from bJCDA c with (nolock) 
		where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and (c.JCTransType <> 'MI' AND c.JCTransType <> 'IN')
		and GLAcct=@glacct

		while @batchseq is not null
		begin
    
			/* get OldNew */
			select @oldnew=min(c.OldNew)
			from bJCDA c with (nolock)
			where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and (c.JCTransType <> 'MI' AND c.JCTransType <> 'IN')
			and GLAcct=@glacct and BatchSeq=@batchseq
			
			while @oldnew is not null
			begin
    
			select @job=Job,@phase=Phase,@costtype=CostType,@jctranstype=JCTransType,@costtrans=CostTrans,
					@actualdate=ActDate, @description=Description, @amount=Amount, @hours=Hours
			from bJCDA with (nolock) where JCCo = @co and Mth = @mth and BatchId = @batchid
			and GLCo=@glco and (JCTransType <> 'MI' AND JCTransType <> 'IN')
			and GLAcct=@glacct and BatchSeq=@batchseq and OldNew=@oldnew

			/**** 120111 get GLType to determine if we should plug @amount with the @hours value ****/
			select @gltype = GLType from bJCDA with(nolock) where JCCo = @co and Mth = @mth and BatchId = @batchid
			and GLCo=@glco and (JCTransType <> 'MI' AND JCTransType <> 'IN')
			and GLAcct=@glacct and BatchSeq=@batchseq and OldNew=@oldnew

			begin transaction
			/**** parse out the description ****/
			select @desccontrol = isnull(rtrim(@glcostdetaildesc),''), @desc = ''

			while (@desccontrol <> '')
				begin
				select @findidx = charindex('/',@desccontrol)
				if @findidx = 0
					begin
					select @found = @desccontrol
					select @desccontrol = ''
					end
				else
					begin
					select @found=substring(@desccontrol,1,@findidx-1)
					select @desccontrol = substring(@desccontrol,@findidx+1,60)
					end

  				if @found = 'Trans #' select @desc = @desc + '/' + isnull(convert(varchar(8), @costtrans),'')
  				if @found = 'Job' select @desc = @desc + '/' + isnull(@job,'')
  				if @found = 'Phase' select @desc = @desc + '/' +  isnull(@phase,'')
  				if @found = 'CT' select @desc = @desc + '/' + isnull(convert(varchar(4), @costtype),'')
  				if @found = 'Trans Type' select @desc = @desc + '/' +  isnull(@jctranstype,'')
  				if @found = 'Desc' select @desc = @desc + '/' + isnull(@description,'')
				end

			---- remove leading '/'
			if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))

			if @gltype = 'HRS' select @amount = @hours
			
			/**** get next available transaction # for GLDT ****/
			select @tablename = 'bGLDT'
			exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
			if @gltrans = 0 goto glcost_detail_posting_error

			insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate,
					DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
			values(@glco, @mth, @gltrans, @glacct, @glcostjournal, @glref, @co, @source, @actualdate,
					@dateposted, @desc, @batchid, @amount, 0, 'N', null, 'N')
			if @@rowcount = 0 goto glcost_detail_posting_error

			/*delete from bJCDA */
			delete from bJCDA where JCCo = @co and Mth = @mth and BatchId = @batchid and GLCo=@glco
			and GLAcct=@glacct and BatchSeq=@batchseq and OldNew=@oldnew and CostTrans=@costtrans
    
     		commit transaction
    
     		goto glcost_detail_posting_end
    
		glcost_detail_posting_error:	/**** error occured within transaction - rollback any updates and continue ****/
			rollback transaction

		glcost_detail_posting_end:

		/* get next OldNew */
		select @oldnew=min(c.OldNew) from bJCDA c with (nolock)
		where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
		and GLAcct=@glacct and BatchSeq=@batchseq and OldNew>@oldnew and (c.JCTransType <> 'MI' AND c.JCTransType <> 'IN')
		end
    
		/* get next BatchSeq */
		select @batchseq=min(c.BatchSeq) from bJCDA c with (nolock)
		where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
		and GLAcct=@glacct and BatchSeq>@batchseq and (c.JCTransType <> 'MI' AND c.JCTransType <> 'IN')
		end
    
	/* get next glacct */
	select @glacct=min(c.GLAcct) from bJCDA c with (nolock) 
	where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
	and GLAcct>@glacct  and (c.JCTransType <> 'MI' or c.JCTransType <> 'IN')
	end

/* get next glco */
select @glco=min(GLCo) from bJCDA with (nolock) 
where JCCo=@co and Mth=@mth and BatchId=@batchid and GLCo>@glco and (JCTransType <> 'MI' AND JCTransType <> 'IN')
end


glcost_update_end:
/**** make sure GL Audit is empty ****/
if exists(select * from bJCDA with (nolock) where JCCo = @co and Mth = @mth and BatchId = @batchid and (JCTransType <> 'MI' AND JCTransType <> 'IN'))
	begin
	select @errmsg = 'Not all updates to GL were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end

/**** Material Update to General Ledger ****/
glmat_update:	/**** update GL using entries from bJCDA ****/
if @glmatlevel = 0	 /**** no update ****/
	begin
	delete bJCDA where JCCo = @co and Mth = @mth and BatchId = @batchid and (JCTransType = 'MI' or JCTransType = 'IN')
	goto glmat_update_end
	end


/**** set GL Reference using Batch Id - right justified 10 chars ****/
select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)

if @glmatlevel = 1	 /**** summary - one entry per GL Co/GLAcct, unless GL Acct flagged for detail do not include JCTransType of MS ****/
	begin
	/* get glco */
	select @glco=min(GLCo) from bJCDA with (nolock) where JCCo=@co and Mth=@mth and BatchId=@batchid and (JCTransType = 'MI' or JCTransType = 'IN')
	while @glco is not null
	begin
		/* get glacct */
		select @glacct=min(c.GLAcct)
		from bJCDA c with (nolock) 
		join bGLAC g with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct and g.InterfaceDetail='N'
		where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and g.InterfaceDetail = 'N' and (c.JCTransType = 'MI' or c.JCTransType = 'IN')
		while @glacct is not null
		begin
			select @amount=convert(numeric(12,2),sum(c.Amount)), @qty=convert(numeric(12,4),sum(c.Qty)), @gltype = c.GLType
			from bJCDA c with (nolock)
			where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
			and c.GLAcct=@glacct and (c.JCTransType = 'MI' or JCTransType = 'IN')
			Group By c.GLType

			begin transaction

			if @gltype = 'QTY' select @amount = @qty
			/**** get next available transaction # for GLDT ****/

			select @tablename = 'bGLDT'
			exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
			if @gltrans = 0 goto glmat_summary_posting_error

			insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate,
					DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
			values(@glco, @mth, @gltrans, @glacct, @glmatjournal, @glref, @co, @source, @dateposted,
					@dateposted, @glmatsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
			if @@rowcount = 0 goto glmat_summary_posting_error

			delete bJCDA where JCCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
			and GLAcct = @glacct and (JCTransType = 'MI' OR JCTransType = 'IN')

			commit transaction
			goto glmat_summary_posting_end

			glmat_summary_posting_error:	/**** error occured within transaction - rollback any updates and continue ****/
			rollback transaction

     		glmat_summary_posting_end:	/**** no more rows to process ****/

			/* get next glacct */
			select @glacct=min(c.GLAcct)
			from bJCDA c with (nolock)
			join bGLAC g with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct and g.InterfaceDetail='N'
			where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
			and g.InterfaceDetail = 'N' and c.GLAcct>@glacct and (c.JCTransType = 'MI' or c.JCTransType = 'IN')
			end

		/* get next glco */
		select @glco=min(GLCo) from bJCDA with (nolock) where JCCo=@co and Mth=@mth and BatchId=@batchid
		and GLCo>@glco and (JCTransType = 'MI' or JCTransType = 'IN')
		end
	end


/**** detail update to GL for everything remaining in bJCDA ****/

/* get glco */
select @glco=min(GLCo) from bJCDA with (nolock) where JCCo=@co and Mth=@mth and BatchId=@batchid and (JCTransType = 'MI' or JCTransType = 'IN')
while @glco is not null
begin
	/* get glacct */
	select @glacct=min(c.GLAcct)
	from bJCDA c with (nolock) 
	where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and (c.JCTransType = 'MI' or c.JCTransType = 'IN')
	while @glacct is not null
	begin
		/* get BatchSeq */
		select @batchseq=min(c.BatchSeq)
		from bJCDA c with (nolock)
		where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and (c.JCTransType = 'MI' or c.JCTransType = 'IN')
		and GLAcct=@glacct
		while @batchseq is not null
		begin
			/* get OldNew */
			select @oldnew=min(c.OldNew)
			from bJCDA c with (nolock)
			where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco and (c.JCTransType = 'MI' or c.JCTransType = 'IN')
			and GLAcct=@glacct and BatchSeq=@batchseq
			while @oldnew is not null
			begin

				select @job=Job,@phase=Phase,@costtype=CostType,@jctranstype=JCTransType,@costtrans=CostTrans,
						@actualdate=ActDate, @description=Description, @amount=Amount, @gltype = GLType,
						@inco = INCo, @loc = Loc, @material = Material, @qty = Qty
				from bJCDA with (nolock) where JCCo = @co and Mth = @mth and BatchId = @batchid and GLCo=@glco
				and (JCTransType = 'MI' or JCTransType = 'IN') and GLAcct=@glacct and BatchSeq=@batchseq
				and OldNew=@oldnew
    
     	      	begin transaction
    
				/**** parse out the description ****/
				select @desccontrol = isnull(rtrim(@glmatdetaildesc),''), @desc = ''

				while (@desccontrol <> '')
					begin
					select @findidx = charindex('/',@desccontrol)
					if @findidx = 0
						begin
						select @found = @desccontrol
						select @desccontrol = ''
						end
					else
						begin
						select @found=substring(@desccontrol,1,@findidx-1)
						select @desccontrol = substring(@desccontrol,@findidx+1,60)
						end

					if @found = 'Trans #' select @desc = @desc + '/' + isnull(convert(varchar(8), @costtrans),'')
					if @found = 'Job' select @desc = @desc + '/' + isnull(@job,'')
					if @found = 'Phase' select @desc = @desc + '/' +  isnull(@phase,'')
					if @found = 'CT' select @desc = @desc + '/' + isnull(convert(varchar(4), @costtype),'')
					if @found = 'Trans Type' select @desc = @desc + '/' +  isnull(@jctranstype,'')
					if @found = 'Desc' select @desc = @desc + '/' + isnull(@description,'')
					if @found = 'INCo' select @desc = @desc + '/' + isnull(convert(varchar(4), @inco),'')
					if @found = 'Location' select @desc = @desc + '/' + isnull(@loc,'')
					if @found = 'Mat #' select @desc = @desc + '/' + isnull(@material, '')
					end

				-- remove leading '/'
				if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
				if @gltype = 'QTY' select @amount = @qty
			
				/**** get next available transaction # for GLDT ****/
				select @tablename = 'bGLDT'
				exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
				if @gltrans = 0 goto glmat_detail_posting_error
  
     	       	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate,
						DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
				values(@glco, @mth, @gltrans, @glacct, @glmatjournal, @glref, @co, @source, @actualdate,
						@dateposted, @desc, @batchid, @amount, 0, 'N', null, 'N')
				if @@rowcount = 0 goto glmat_detail_posting_error

				/*delete from bJCDA */
				delete from bJCDA where JCCo = @co and Mth = @mth and BatchId = @batchid and GLCo=@glco
				and GLAcct=@glacct and BatchSeq=@batchseq and OldNew=@oldnew and CostTrans=@costtrans

				commit transaction

				goto glmat_detail_posting_end

				glmat_detail_posting_error:	/**** error occured within transaction - rollback any updates and continue ****/
					rollback transaction

				glmat_detail_posting_end:

				/* get next OldNew */
				select @oldnew=min(c.OldNew) from bJCDA c with (nolock)
				where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
				and GLAcct=@glacct and BatchSeq=@batchseq and OldNew>@oldnew and (c.JCTransType = 'MI' or c.JCTransType = 'IN')
				end
    
			/* get next BatchSeq */
			select @batchseq=min(c.BatchSeq) from bJCDA c with (nolock)
			where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
			and GLAcct=@glacct and BatchSeq>@batchseq and (c.JCTransType = 'MI' or c.JCTransType = 'IN')
			end
    
		/* get next glacct */
		select @glacct=min(c.GLAcct) from bJCDA c with (nolock)
		where c.JCCo=@co and c.Mth=@mth and c.BatchId=@batchid and c.GLCo=@glco
		and GLAcct>@glacct  and (c.JCTransType = 'MI' or c.JCTransType = 'IN')
		end

	/* get next glco */
	select @glco=min(GLCo) from bJCDA with (nolock)
	where JCCo=@co and Mth=@mth and BatchId=@batchid and GLCo>@glco and (JCTransType = 'MI' or JCTransType = 'IN')
	end

glmat_update_end:
/**** make sure GL Audit is empty ****/
if exists(select * from bJCDA with (nolock) where JCCo = @co and Mth = @mth and BatchId = @batchid and (JCTransType = 'MI' or JCTransType = 'IN'))
	begin
	select @errmsg = 'Not all updates to GL were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end

in_update:
exec @rcode=bspJCCBPostIN @co, @mth, @batchid, @dateposted, @errmsg output
if @rcode <> 0 goto bspexit

---- make sure all IN Distributions have been processed
if exists(select * from bJCIN where JCCo = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all updates to IN were posted - unable to close the batch!', @rcode = 1
	goto bspexit
	end
    
-- ************* --
-- ISSUE: 132131 --
-- ************* --
-- set interface levels note string
select @Notes=Notes from bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
select @Notes=@Notes +
	        'GL Cost Interface Level set at: ' + isnull(convert(char(1), a.GLCostLevel),'') + char(13) + char(10) +
            'GL Revenue Interface Level set at: ' + isnull(convert(char(1), a.GLRevLevel),'') + char(13) + char(10) +
            'GL Close Interface Level set at: ' + isnull(convert(char(1), a.GLCloseLevel),'') + char(13) + char(10) +
            'GL Material Interface Level set at: ' + isnull(convert(char(1), a.GLMaterialLevel),'') + char(13) + char(10) 
from bJCCO a with (nolock) where JCCo=@co

--	          'GL Adjustment Interface Level set at: ' + isnull(convert(char(1), a.GLAdjInterfaceLvl),'') + char(13) + char(10) +
--            'GL Transfer Interface Level set at: ' + isnull(convert(char(1), a.GLTrnsfrInterfaceLvl),'') + char(13) + char(10) +
--            'GL Production Interface Level set at: ' + isnull(convert(char(1), a.GLProdInterfaceLvl),'') + char(13) + char(10) +
--            'GL MO Interface Level set at: ' + isnull(convert(char(1), a.GLMOInterfaceLvl),'') + char(13) + char(10) +
--            'JC MO Interface Level set at: ' + isnull(convert(char(1), a.JCMOInterfaceLvl),'') + char(13) + char(10)
--from bINCO a with (nolock) where INCo=@co
    

/**** delete HQ Close Control entries ****/
delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    
/**** set HQ Batch status to 5 (posted) ****/
update bHQBC set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspJCCBPost] TO [public]
GO
