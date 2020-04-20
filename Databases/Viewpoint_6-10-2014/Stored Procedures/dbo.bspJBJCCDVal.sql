SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBJCCDVal    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBJCCDVal]
/***********************************************************
* CREATED BY	: kb 9/12/00
* MODIFIED BY : bc 10/26/00 - removed the jcctCatgy check that throws an error if
*                             if the category is flagged to be used by JBTM.
*		GG 11/27/00 - changed datatype from bAPRef to bAPReference
*   	kb 8/13/1 - issue #13963
*    	kb 3/11/2 - issue #16560
*		TJL 08/27/02 - Issue #18346, Rewrite. Important to read this issue.
*		TJL 10/08/02 - Issue #18542, Do Not allow adding JCTrans to Non-JCTrans Seq w/Dollar Value
*		TJL 03/19/03 - Issue #19765, Not calling bspJBTandMGetCategory when JCTransType = 'MS'
*		TJL 04/12/04 - Issue #24304, Use errmsg directly from bspJBTandMGetCategory proc
*		TJL 04/22/04 - Issue #22838, Use errmsg directly from bspJBTandMGetTemplateSeq proc
*		TJL 06/08/06 - Issue #28229, Modified warning messages (only) to better accomodate 6x form.
*		TJL 10/08/07 - Issue #125078, TransTypes 'IC' from 'JC CostAdj' need to be processed as JCTransTypes 'JC'
*		TJL 12/20/07 - Issue #125982, Don't show IN Material Committed JCCD transactions on JB Bill
*		TJL 01/11/08 - Issue #123452, TransTypes 'MI' from 'JC MatlUse' need to be processed as JCTransTypes 'JC'
*		TJL 12/04/08 - Issue #131219, Related to #125982 - Committed or not based on ActualCost and ActualUnits
*		TJL 01/21/08 - Issue #131622, Should have been part of Issue #123452.  Call bspJBTandMGetCategory for JC Matl
*		TJL 03/19/09 - Issue #120614, Add ability to include Rate value in summarization of PR Sources
*		GF  06/25/2010 - issue #135813 expanded SL to varchar(30)
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*
* USED IN:
*
* USAGE:
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
    
(@co bCompany, @billmth bMonth, @billnum int, @jcmonth bMonth, @jctrans bTrans,
	@line int, @jbidseq int, @jbidsource char(2), @tempseq int, @msg varchar(500) output)
as

/* NOTE:  Regarding @jbidsource input above:  Since the purpose of this
   routine is to validate JC Transactions, I decided that this value should be derived
   specifically from the JC Transaction itself.  Therefore, the input above is not being 
   used at this time.  I left it in place in the event it had some value down the road. */
    
set nocount on
    
declare @rcode int, @jbcontract bContract, @jccontract bContract, @jcjpitem bContractItem,
	@phasegroup bGroup, @billtype char(1), @jbbillgroup bBillingGroup,
	@jcbillgroup bBillingGroup, @template varchar(10), @costtype bJCCType,
	@jcctCatgy char(1), @jbtm_lcat bYN, @jbtm_ecat  bYN, @jbtm_mcat bYN,
	@prco bCompany, @employee bEmployee, @craft bCraft,
	@restrictbillgroup bYN, @class bClass, @earntype bEarnType, @factor bRate,
	@shift tinyint, @emco bCompany, @liabtype bLiabilityType, @equip bEquip,
	@revcode bRevCode,@currentcategory varchar(10), @dumbint int, @dumbtinyint tinyint,
	@temp_sortorder char(1), @jbil_date bDate, @jbil_job bJob, @jbil_phase bPhase,
	@jbil_phasegroup bGroup, @jbid_costtype bJCCType, @jbid_prco bCompany,
	@jbid_employee bEmployee, @jbid_earntype bEarnType, @jbid_craft bCraft,
	@jbid_class bClass, @jbid_factor bRate, @jbid_shift tinyint, @jbid_emco bCompany,
	@jbid_liabtype bLiabilityType, @jbid_apco bCompany, @jbid_vendorgroup bGroup,
	@jbid_vendor bVendor, @jbid_apref bAPReference, @jbid_inco bCompany,
	@jbid_matlgroup bGroup, @material bMatl, @jbid_material bMatl, @jbid_equip bEquip,
	@apco bCompany, @vendorgroup bGroup, @vendor bVendor, @apref bAPReference,
	@inco bCompany, @matlgroup bGroup, @loc bLoc, @jbid_loc bLoc, @msticket bTic,
	@sl VARCHAR(30), @po varchar(30), @slitem bItem, @poitem bItem, @emgroup bGroup,
	@jbid_msticket bTic, @jbid_sl VARCHAR(30), @jbid_po varchar(30), @jbid_slitem bItem,
	@jbid_poitem bItem, @jbid_emgroup bGroup, @jbid_revcode bRevCode,
	@jcdate bDate, @job bJob, @phase bPhase, @desc bDesc, @um bUM,
	@actualunits bUnits, @actualunitcost bUnitCost, @actualcost bDollar, @seqtype char(1),
	@jctranstype char(2), @jccdbillstatus tinyint, @jccdbillmonth bMonth, @jccdbillnum int,
	-- Added per Issue #18346
	@actualecm bECM, @postedecm bECM, @actualhours bHrs, @postedum bUM, @postdate bDate,
	@ctcategory char(1), @category varchar(10), @sumopt tinyint, @seqsortlevel tinyint,
	@lineseq int, @detailkey varchar(500), @jctempseq int, @jcgroupnum int, @jcline int,
	@jcjbidsource char(2), @jclinekey varchar(100), @sequserates char(1),
	@laborrateopt char(1), @equiprateopt char(1), @laborrate bUnitCost, @laboreffectivedate bDate
    
select @rcode = 0
    
/* To add a JC Transaction, user has already been required to enter a JBID Source */
if @jbidsource is null
	begin
	select @msg = 'User must enter a Source on JB T&&M Bill Line Seq form.', @rcode = 1
	goto bspexit
	end 
if @tempseq is null
	begin
	select @msg = 'Template Sequence is missing from form JB T&&M Bill Lines.  JC Transaction validation may not continue.', @rcode = 1
	goto bspexit
	end
    
/* Issue #18542: If this sequence does not contain related transactions and If the current 
   Total is NOT 0.00, then this sequence is intended for value only and not intended to  
   add JC Transactions into.  (Transactions may only be added to existing sequences with similar
   transactions. */
if Not Exists(select * 
		from bJBID d
		Join bJBIJ j on j.JBCo = d.JBCo and j.BillMonth = d.BillMonth and j.BillNumber = d.BillNumber
			and j.Line = d.Line and j.Seq = d.Seq
		where d.JBCo = @co and d.BillMonth = @billmth and d.BillNumber = @billnum
			and d.Line = @line and d.Seq = @jbidseq)
	and
		(select Total 
		from bJBID d
		where d.JBCo = @co and d.BillMonth = @billmth and d.BillNumber = @billnum
			and d.Line = @line and d.Seq = @jbidseq) <> 0
	begin
	select @msg = 'This Sequence contains a Dollar value without related transactions.  It is not a match for this transaction.'
	select @msg = @msg + char(10) + char(13) + char(10) + char(13)
	select @msg = @msg + 'To Add this transaction, use the Job Cost Detail form accessed from the '
	select @msg = @msg + 'JB T&&M Bill Edit programs File option.  This transaction may not be added here.', @rcode = 1
	goto bspexit
	end
    
/* Get Header info */
select @jbcontract = Contract, @jbbillgroup = BillGroup, @template = Template,
	@restrictbillgroup = RestrictBillGroupYN
from JBIN
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
    
/* Get Template Info */
select @jbtm_lcat = LaborCatYN, @jbtm_ecat = EquipCatYN, @jbtm_mcat = MatlCatYN,
	@temp_sortorder = SortOrder, @laborrateopt = LaborRateOpt, @equiprateopt = EquipRateOpt,
	@laboreffectivedate = LaborEffectiveDate
from JBTM
where JBCo = @co and Template = @template

/* Get Template Seq Info */
select @seqsortlevel = SortLevel, @sumopt = SummaryOpt
from bJBTS
where JBCo = @co and Template = @template and Seq = @tempseq
    
/* Get Line info from Bill */
select @jbil_date = Date, @jbil_job = Job, @jbil_phase = Phase,
	@jbil_phasegroup = PhaseGroup 
from bJBIL 
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
	and Line = @line
    
/* Get JCCD values */
select @jcdate = d.ActualDate, @job = d.Job, @phasegroup = d.PhaseGroup, @phase = d.Phase,
  	@desc = d.Description, 
	@um = d.UM,
	--@um = case d.JCTransType when 'AP' then d.PostedUM else d.UM end, 
	@actualunits = d.PostedUnits,
	--	@actualunits = case d.JCTransType when 'AP' then 
	--		case when d.UM <> d.PostedUM then d.PostedUnits else d.ActualUnits end
	--  	else d.ActualUnits end, 
	@actualunitcost = d.PostedUnitCost,
	--	@actualunitCost = case d.JCTransType when 'AP' then
	--  		case when d.UM <> d.PostedUM then d.PostedUnitCost else d.ActualUnitCost end 
	--	else d.ActualUnitCost end ,
	@actualcost = d.ActualCost, @costtype = d.CostType, @prco = d.PRCo, @employee = d.Employee,
	@craft = d.Craft, @class = d.Class, @earntype = d.EarnType, @liabtype = d.LiabilityType,
	@factor = d.EarnFactor, @shift = d.Shift, @emco = d.EMCo, @emgroup = d.EMGroup,
	@equip = d.EMEquip, @revcode = d.EMRevCode, @apco = d.APCo,
	@vendorgroup = d.VendorGroup, @vendor = d.Vendor, @apref = d.APRef, @inco = d.INCo,
	@matlgroup = d.MatlGroup, @material = d.Material, @loc = d.Loc,
	@msticket = d.MSTicket, @sl = d.SL, @slitem = d.SLItem, @po = d.PO, @poitem = d.POItem,
	@jcjbidsource = left(d.Source,2), 
	@jctranstype = case d.JCTransType when 'CA' then 'JC' 
					when 'IC' then 'JC'
					when 'MI' then 'JC'
					else d.JCTransType end,
	@jccdbillstatus = d.JBBillStatus, @jccdbillmonth = d.JBBillMonth,
	@jccdbillnum = d.JBBillNumber, 
	@actualecm = PostedECM,
	--@actualecm = case when d.Source in ('JC MatUse','MI') then PostedECM else PerECM end,
	@postedecm = PostedECM, @actualhours = ActualHours, @postedum = PostedUM,
	@postdate = PostedDate, @ctcategory = t.JBCostTypeCategory
from bJCCD d
join JCCT t on t.PhaseGroup = d.PhaseGroup and t.CostType = d.CostType
where JCCo = @co and Mth = @jcmonth and CostTrans = @jctrans
if @@rowcount = 0
	begin
	select @msg = 'Invalid JC Transaction.', @rcode = 1
	goto bspexit
	end

/* Check if CostTrans exists already either on this bill or any other. */
if @jccdbillstatus in (1,2)
    begin
	if exists(select 1 from bJBIJ where JBCo = @co and BillMonth = @billmth and
	 		BillNumber = @billnum and JCTrans = @jctrans and JCMonth = @jcmonth and
	 		(Line <> @line or Seq <> @jbidseq) and Line is not null and Seq is not null)
		begin
		select @msg = 'This JC Transaction already exists on another Line/Seq on this bill.', @rcode = 1
		goto bspexit
		end
	else
		begin
		select @msg = 'This JC transaction is associated with another bill - BillMonth '
      		+ isnull(convert(varchar(8),@jccdbillmonth,1),'') + ', BillNumber #'
      		+ isnull(convert(varchar(20),@jccdbillnum),'') + '.', @rcode = 1
		goto bspexit
		end
    end
   
/* Further Adjustments to @jctranstype */
if @jctranstype = 'PR' and @ctcategory = 'E' select @jctranstype = 'EM'
if @jctranstype = 'AP' --set source for SL and Material types
	begin
	if @material is not null select @jctranstype = 'MT' --@source = 'MT'
	if @sl is not null select @jctranstype = 'SL' --source = 'SL'
	end
if @jctranstype = 'MO'
	begin
	if @actualcost = 0 and @actualunits = 0
		begin
		/* Material Order Transaction has committed costs but none yet confirmed.  Do Not show on Bill. */
		--select @msg = 'Material Order Transaction has committed costs but none yet confirmed.', @rcode = 1
		goto bspexit
		end
	else
		begin
		/* Material Order/Item Transaction has been Confirmed.  Place Transaction on Bill. */
		select @jctranstype = 'IN'
		end
	end
   
/* Get SeqUserRates - This is Consistent with bspJBTandMAddJCTrans and bspJBTandMInit */	
select @sequserates = case @jctranstype
	when 'PR' then case @ctcategory when 'L' then @laborrateopt
   		when 'E' then @equiprateopt end
   	when 'EM' then @equiprateopt 
	else 'C' end 
    
/* Get Category info */
if (@jctranstype = 'PR' and @ctcategory ='L' and (@jbtm_lcat = 'Y' or @sequserates='R')) or
		(@jctranstype = 'PR' and @ctcategory ='E' and (@jbtm_ecat = 'Y' or @sequserates in('T','R')) or
		((@jctranstype = 'JC' or @jctranstype = 'MT' or @jctranstype = 'IN' or @jctranstype = 'MS') and @jbtm_mcat = 'Y') or
		(@jctranstype = 'EM' and(@sequserates in('T','R') or @jbtm_ecat = 'Y')))
	begin
	exec @rcode = bspJBTandMGetCategory @co, @prco, @employee, @craft, @class,
		@earntype, @factor, @shift, @emco, @equip, @matlgroup, @material,
		@revcode, @jctranstype, 
		@template, @ctcategory, @category output, @msg output
	if @rcode <> 0 goto bspexit
	end
else
	begin
		select @category = null
	end
    
/* Get Contract Info */
select @jccontract = Contract, @jcjpitem = Item
from JCJP
where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase
if @@rowcount = 0
	begin
   	select @msg = 'Job/Phase missing on this JC Transaction.', @rcode = 1
   	goto bspexit
   	end
    
/* Before assuming that user is entering a transactions that belongs on this JBIL.Line
   and TemplateSeq we need to check.  It may belong on an entirely different JBIL.Line */
exec @rcode = bspJBTandMGetTemplateSeq @co, @template, @category, @jcjbidsource,
	@earntype, @liabtype, @phasegroup, @costtype, @jctempseq output, null,
	null, @jcgroupnum output, null, @jctranstype, @msg output
if @rcode <> 0
	begin
	goto bspexit
	end
else
	begin
	exec @rcode = bspJBTandMGetLineKey @co, @phasegroup, @phase, @job, @jcjpitem,
		@template, @jctempseq, @postdate, @jcdate, @jcgroupnum, 'N',
		@jclinekey output, @msg output
	if @rcode <> 0 or @jclinekey is null
		begin
		select @msg = 'Unable to retrieve this JC Transactions LineKey for evaluation.', @rcode = 1
		goto bspexit
		end
	else
		begin
		select @jcline = Line 
		from bJBIL
		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
			and LineKey = @jclinekey and LineType = 'S'
		if @@rowcount = 0
			begin
			select @msg = 'This JC Transaction does not correspond to an existing Line on this bill.'
			select @msg = @msg + char(10) + char(13) + char(10) + char(13)
			select @msg = @msg + 'To Add this transaction, use the Job Cost Detail form accessed from the '
			select @msg = @msg + 'JB T&&M Bill Edit programs File option.  This transaction may not be added here.', @rcode = 1
			goto bspexit
			end
		end
	end
    
/* Now that we have this JC Transactions JBIL.Line and TemplateSeq we can compare with
   that which the user has selected and is attempting to a this JC transaction to. */
if @line <> @jcline --or @tempseq <> @jctempseq
	begin
	select @msg = 'This JC Transaction belongs on the Bill Line #' + isnull(convert(varchar(6),@jcline),'') + '.'
	select @msg = @msg + char(10) + char(13) + char(10) + char(13)
	select @msg = @msg + 'Return to JB T&&M Bill Line Sequences and select the correct Bill Line.', @rcode = 1
	goto bspexit
	end

if @jctranstype = 'PR' and @ctcategory = 'L'
   	begin
   	if @sequserates = 'R' 	--From the Template (Not 'C'ost)
       	begin
		exec @rcode = bspJBTandMGetLaborRate @co, @template, @category,
           	@prco, @employee, @craft, @class, @shift,
           	@earntype, @factor, @jcdate, @laboreffectivedate, @sequserates output, 
   			@laborrate output, @msg output
   
		if @rcode <> 0
           	begin
         	select @laborrate = null
      		end
		end
 	end
    
/* JBIL.Line and TemplateSeq are correct so, first Get a DetailKey specific to 
   this 'JC Month' and 'JC Trans'. */
exec @rcode = bspJBTandMGetDetailKey @co, @jcmonth, @jctrans, @jctranstype output,
 	@seqsortlevel output, @sumopt output, @category output, @prco output,
   	@employee output, @craft output, @class output, @earntype output,
  	@factor output, @ctcategory output, @shift output, @apco output,
   	@vendorgroup output, @vendor output, @apref output, @inco output,
  	@msticket output, @matlgroup output, @material  output, @loc output,
   	@sl output, @slitem output, @emgroup output, @equip output, @revcode output,
  	@jcdate  output, @liabtype output,@desc output,
   	@emco output, @costtype output, @phasegroup output, @po output,
  	@poitem output, @laborrate, @detailkey output, @postdate output, @msg output
    
if @rcode <> 0 or @detailkey is null
	begin
	select @msg = 'Error determining detail key for this transaction.', @rcode = 1
	goto bspexit
	end
else 
	begin	
	/* With this DetailKey either get an existing Line Seq value or create a new
	   one. */
	exec @rcode = bspJBTandMAddLineSeq @co, @billmth, @billnum, @detailkey,  @line,
		@lineseq output, @msg output
	if @rcode <> 0 or @lineseq is null
		begin
		select @msg = 'Error determining JBID Sequence for this transaction.', @rcode = 1
		goto bspexit
		end
	else
		begin
		/* EVALUATE THE LINESEQ# - Critical to avoid unwanted deletes during bspJCTMAddJCTransToLine. */

		/* Eval #1: Whether adding a transaction to an existing JBID record or adding a new 
		   JBID record, this test will determine if this transaction already exists in bJBIJ
		   under a different line or lineseq.  If so, you may not add it here again. */
		if exists(select 1 from bJBIJ where JBCo = @co and BillMonth = @billmth and
		 		BillNumber = @billnum and JCTrans = @jctrans and JCMonth = @jcmonth and
		 		(Line <> @line or Seq <> @jbidseq) and Line is not null and Seq is not null)
			begin
			select @msg = 'This JC Transaction already exists on another Line/Seq on this bill.', @rcode = 1
			goto bspexit
			end
		/* Now that we know the JC Trans doesn't already exist in bJBIJ, we now need to 
		   determine if this transactions LineSeq# already exists in bJBID and under
		   what conditions. */
		If @jbidseq <> @lineseq
			begin
			/* Eval #2: If this LineSeq# is different than what has been passed in then this
			   JC trans does not belong here.  First test to see if this New LineSeq already exists
			   in JBID.  This test is different than above because the LineSeq# may exist even
			   though this Transaction does not exist in JBIJ. */
			if exists(select 1 from bJBID
					  where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
						and Line = @line and Seq = @lineseq)
				begin
				select @msg = 'This JC transaction must be added into another existing Line/Seq on this bill.'
				select @msg = @msg + char(10) + char(13) + char(10) + char(13)
				select @msg = @msg + 'User should return to JB T&&M Bill Lines and select Line #' + isnull(convert(varchar(6), @line),'')
				select @msg = @msg + ', Seq #' + isnull(convert(varchar(6), @lineseq),'') + ' and re-enter transaction.', @rcode = 1
				goto bspexit
				end
			else
				begin
				/* If this LineSeq# is different than what has been passed in, then this
				   JC transaction does not belong here.  Also, we have determined that there are no other
				   Line/Seqs on this bill to fit this transaction into.  Therefore user must return to the
				   T&M Bill Header form and use the primary JC Detail Transaction entry form. */
				select @msg = 'This JC transaction belongs to a Line/Seq that does not exist, on this bill, at this time.'
				select @msg = @msg + char(10) + char(13) + char(10) + char(13)
				select @msg = @msg + 'To Add this transaction, use the Job Cost Detail form accessed from the '
				select @msg = @msg + 'JB T&&M Bill Edit programs File option.  This transaction may not be added here.', @rcode = 1
				goto bspexit
				end

--			/* Eval #3:  If this LineSeq# is different than what has been passed in then this
--			   JC Trans does not belong here.  If the New LineSeq# for the JC Trans does NOT
--			   already exist in JBID then we must test to see if the LineSeq# passed in by
--			   the user (that which we are sitting on) already contains JC 
--			   Transactions (Valid/Existing LineSeq). If it does we do NOT want to proceed 
--			   from within this LineSeq.  User must be forced to goto a New LineSeq to enter 
--			   this JC transaction. */
--			if exists(select 1 from bJBID d
--					  join bJBIJ j on d.JBCo = j.JBCo and d.BillMonth = j.BillMonth
--						and d.BillNumber = j.BillNumber and d.Line = j.Line and d.Seq = j.Seq
--					  where d.JBCo = @co and d.BillMonth = @billmth and d.BillNumber = @billnum
--						and d.Line = @line and d.Seq = @jbidseq)
--				begin
--				select @msg = 'JC transaction does not belong to this line/seq of this bill.'
--				select @msg = @msg + char(10) + char(13) + char(10) + char(13)
--				select @msg = @msg + 'User should return to JBTMBillLines and add a NEW line/seq.', @rcode = 1
--				goto bspexit
--				end

			end

/* At this point, user has been warned about one of the following:
   1)  JC Transaction belongs on a different Line# altogether.
   2)  JC Transaction belongs on a different Line# altogether but that Line# does not yet exist.
   3)  JC Transaction already exists on this bill in a different Line or LineSeq.
   4)  JC Transaction has not yet been added but belongs to another existing LineSeq. 
   5)  JC Transaction has not yet been added but belongs on another LineSeq that does not yet exist. */
		else
			begin
			/* Eval #4:  This Transaction does not already exist in JBIJ in another line
			   and/or seq.  The user is sitting in a valid LineSeq containing transactions 
			   and we know that this JC Trans being added belongs within this LineSeq group.
			   The only thing left is to determine if this transaction already exists in this
			   LineSeq. */
			if exists(select 1 from bJBIJ
					  where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
					  	and Line = @line and Seq = @lineseq and JCMonth = @jcmonth
						and JCTrans = @jctrans)
				begin
				select @msg = 'This JC Transaction already exists on this Line/Seq on this bill.', @rcode = 1
				goto bspexit	
				end
			end			
		end
	end
    
/* This 'JC Month' and 'JC Trans' is OK to initialize so proceed with more specific validation. */

/* Get JBID values from the First/Previously posted JC Transaction.  Depending upon
   how the template sequence is summarized and the order in which the transactions
   are added, will determine some of these values.  Comparing a JCCD transaction value
   to an existing JBID record may be misleading! */
select @jbid_costtype = CostType, @jbid_prco = PRCo, @jbid_employee = Employee,
	@jbid_earntype = EarnType, @jbid_craft = Craft, @jbid_class = Class,
   	@jbid_factor = Factor, @jbid_shift = Shift, @jbid_liabtype = LiabilityType,
   	@jbid_apco = APCo, @jbid_vendorgroup = VendorGroup, @jbid_vendor = Vendor,
   	@jbid_apref = APRef, @jbid_inco = INCo, @jbid_matlgroup = MatlGroup,
   	@jbid_material = Material, @jbid_loc = Location, @jbid_msticket = MSTicket,
   	@jbid_sl = SL, @jbid_slitem = SLItem, @jbid_po = PO, @jbid_poitem = POItem,
   	@jbid_emco = EMCo, @jbid_emgroup = EMGroup, @jbid_equip = Equipment,
   	@jbid_revcode = RevCode
from bJBID 
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
 	and Line = @line and Seq = @lineseq
    
/* Specific JCCD transaction validation */
if @jbcontract <> @jccontract
   	begin
   	select @msg = 'Cost posted to different contract.', @rcode = 1
   	goto bspexit
   	end

select @billtype = BillType, @jcbillgroup = BillGroup
from JCCI
where JCCo = @co and Contract = @jccontract and Item = @jcjpitem
if @@rowcount = 0
   	begin
   	select @msg = 'Contract item ' + isnull(convert(varchar(16),@jcjpitem),'') + ' not found.', @rcode = 1
   	goto bspexit
   	end

if @billtype not in ('T','B')
   	begin
   	select @msg = 'Contract item ' + isnull(convert(varchar(16),@jcjpitem),'') + ' not flagged as T&&M.', @rcode = 1
   	goto bspexit
   	end

if @jcbillgroup is not null and isnull(@jbbillgroup,'') <> @jcbillgroup and
   	@restrictbillgroup = 'Y'
   	begin
   	select @msg = 'Contract item ' + isnull(convert(varchar(16),@jcjpitem),'') + ' billing group does not match invoice.', @rcode = 1
   	goto bspexit
   	end
    
/* Comparisons between Existing JBID record and the JC Transaction that is to be added to 
   this record. Depending upon how the template sequence is summarized and the order in 
   which the transactions are added, will determine some of the values being compared
   against this JC Transaction.  Comparing a JCCD transaction value to an existing 
   JBID record may be misleading! 

   Issue #18346 adds JBID values that did not exist before.  Because some values in 
   JBID will no longer be NULL, many of these comparisons have the potential for 
   failure based on Template Sequence Summary options and the like.  Therefore many
   have been REM'D pending further review with Kateb. 

   It is important not to allow user to add a JC Transaction to the wrong 'line/seq' and
   that has been accomplished.  Specific validation such as this is nice but not 
   necessary and difficult to accomplish. */
    
/*validate date*/
if @jcdate <> @jbil_date and @temp_sortorder = 'A'  -- ActualDate
	and @jbil_date is not null		-- null if 1st trans added to new JBID record
	begin
	select @msg = 'This JC Transaction Actual Date does not match the date for the line.', @rcode = 1
	goto bspexit
	end 
if @postdate <> @jbil_date and @temp_sortorder = 'D'	-- PostedDate
	and @jbil_date is not null		-- null if 1st trans added to new JBID record
	begin
	select @msg = 'This JC Transaction Posted Date does not match the date for the line.', @rcode = 1
	goto bspexit
	end

/*validate job*/
if @job <> @jbil_job and (@temp_sortorder = 'J')	-- Job/Phase
	and @jbil_job is not null		-- null if 1st trans added to new JBID record
	begin
	select @msg = 'This JC Transaction Job does not match the Job in the line.', @rcode = 1
	goto bspexit
	end

/*validate phasegroup*/
if @phasegroup <> @jbil_phasegroup and (@temp_sortorder = 'J' or @temp_sortorder = 'P')
	and @jbil_phasegroup is not null	-- null if 1st trans added to new JBID record
	begin
	select @msg = 'This JC Transaction Phase Group does not match the Phase Group in the line.',
       	@rcode = 1
	goto bspexit
	end

/*validate phase*/
if @phase <> @jbil_phase and (@temp_sortorder = 'P')	-- Phase
	and @jbil_phase is not null			-- null if 1st trans added to new JBID record
	begin
	select @msg = 'This JC Transaction Job does not match the Phase in the line.', @rcode = 1
	goto bspexit
	end
    
/* From here out, these comparisons are invalid.  This level of Detail determines the DetailKey
   value and in turn, the Seq value.  Previously above, we have already notified the user
   if the JCMonth/JCTrans belongs to another Line or Line/Seq based upon this information
   (ie: GetLineKey, GetDetailKey etc. above.) from the CostTrans.  Therefore there is no need to re-evaluate. */
/*
if @costtype <> @jbid_costtype
	begin
	select @msg = 'JC Transaction costtype does not match the line/seq costtype', @rcode = 1
	goto bspexit
	end 

if @prco <> @jbid_prco and @jbid_prco is not null
	begin
	select @msg = 'JC Transaction PR Company does not match the line/seq PR Company', @rcode = 1
	goto bspexit
	end

if @employee <> @jbid_employee and @jbid_employee is not null
  	begin
	select @msg = 'JC Transaction Employee does not match the line/seq Employee', @rcode = 1
	goto bspexit
	end

if @earntype <> @jbid_earntype and @jbid_earntype is not null
	begin
	select @msg = 'JC Transaction EarnType does not match the line/seq EarnType', @rcode = 1

	goto bspexit
	end

if @craft <> @jbid_craft and @jbid_craft is not null
	begin
	select @msg = 'JC Transaction Craft does not match the line/seq Craft', @rcode = 1
	goto bspexit
	end

if @class <> @jbid_class and @jbid_class is not null
	begin
	select @msg = 'JC Transaction Class does not match the line/seq Class', @rcode = 1
	goto bspexit
	end

if @factor <> @jbid_factor and @jbid_factor is not null
	begin
	select @msg = 'JC Transaction Factor does not match the line/seq Factor', @rcode = 1
	goto bspexit
	end

if @shift <> @jbid_shift and @jbid_shift is not null
	begin
	select @msg = 'JC Transaction Shift does not match the line/seq Shift', @rcode = 1
	goto bspexit
	end

if @liabtype <> @jbid_liabtype and @jbid_liabtype is not null
	begin
	select @msg = 'JC Transaction Liability Type does not match the line/seq Liability Type',
    	@rcode = 1
	goto bspexit
	end

if @apco <> @jbid_apco and @jbid_apco is not null
	begin
	select @msg = 'JC Transaction AP Company does not match the line/seq AP Company', @rcode = 1
	goto bspexit
	end

if @vendorgroup <> @jbid_vendorgroup and @jbid_vendorgroup is not null
	begin
	select @msg = 'JC Transaction Vendor Group does not match the line/seq Vendor Group',
       	@rcode = 1
	goto bspexit
	end

if @vendor <> @jbid_vendor and @jbid_vendor is not null
	begin
	select @msg = 'JC Transaction Vendor does not match the line/seq Vendor', @rcode = 1
	goto bspexit
	end

*/
/*@jbid_apref = APRef, @jbid_inco = INCo, @jbid_matlgroup = MatlGroup*/
/*
if @apref <> @jbid_apref and @jbid_apref is not null
	begin
	select @msg = 'JC Transaction AP Reference # does not match the line/seq AP Reference #',
    	@rcode = 1
	goto bspexit
	end

if @inco <> @jbid_inco and @jbid_inco is not null
	begin
	select @msg = 'JC Transaction IN Company does not match the line/seq IN Company',
       	@rcode = 1
	goto bspexit
	end

if @matlgroup is not null and @matlgroup <> @jbid_matlgroup and @jbid_matlgroup is not null
	begin
	select @msg = 'JC Transaction Material Group does not match the line/seq Material Group', @rcode = 1
	goto bspexit
	end

if @material <> @jbid_material and @jbid_material is not null
	begin
	select @msg = 'JC Transaction Material does not match the line/seq Material', @rcode = 1
	goto bspexit
	end

if @loc <> @jbid_loc and @jbid_loc is not null
	begin
	select @msg = 'JC Transaction Location does not match the line/seq Location', @rcode = 1
	goto bspexit
	end

if @msticket <> @jbid_msticket and @jbid_msticket is not null
	begin
	select @msg = 'JC Transaction MS Ticket does not match the line/seq MS Ticket', @rcode = 1
	goto bspexit
	end

if @sl <> @jbid_sl and @jbid_sl is not null
	begin
	select @msg = 'JC Transaction SL does not match the line/seq SL', @rcode = 1
	goto bspexit
	end

if @slitem <> @jbid_slitem and @jbid_slitem is not null
	begin
	select @msg = 'JC Transaction SL Item does not match the line/seq SL Item', @rcode = 1
	goto bspexit
	end

if @po <> @jbid_po and @jbid_po is not null
	begin
	select @msg = 'JC Transaction PO does not match the line/seq PO', @rcode = 1
	goto bspexit
	end

if @poitem <> @jbid_poitem and @jbid_poitem is not null
	begin
	select @msg = 'JC Transaction PO Item does not match the line/seq PO Item', @rcode = 1
	goto bspexit
	end

if @emgroup <> @jbid_emgroup and @jbid_emgroup is not null
	begin
	select @msg = 'JC Transaction EM Group does not match the line/seq EM Group', @rcode = 1
	goto bspexit
	end

if @emco <> @jbid_emco and @jbid_emco is not null
	begin
	select @msg = 'JC Transaction EM Company does not match the line/seq EM Company', @rcode = 1
	goto bspexit
	end

if @equip <> @jbid_equip and @jbid_equip is not null
	begin
	select @msg = 'JC Transaction Equipment does not match the line/seq Equipment', @rcode = 1
	goto bspexit
	end

if @revcode <> @jbid_revcode and @jbid_revcode is not null
	begin
	select @msg = 'JC Transaction Rev Code does not match the line/seq Rev Code', @rcode = 1
	goto bspexit
	end
*/
    
bspexit:
return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspJBJCCDVal] TO [public]
GO
