SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJBProgressBillItemsInit]

/****************************************************************************
* CREATED BY:     kb 7/16/99
* MODIFIED By :   bc 04/18/00 rounding option
* 		bc 04/19/00 added aco thru date
*  		kb 4/5/00 Issue #6329
*    	bc 05/25/00
*    	kb 5/16/00 - added contract to JBIT
*    	kb 5/22/00 - changed bBillGroup to be bBillingGroup
*    	bc 09/13/00 - changed the autoinit pctcomplete calculation for @unitsbilled and @totalamt
*    	bc 12/21/00 - remmed out the read on JCCI.BillUnitPrice, BillCurrentUnits and BillCurrentUnits
*                  		because they're not being used and can cause confusion
*  		bc 12/08/00 - changed auto init calculation of pct complete when jcci um <> LS
*    	bc 04/23/01 - @itemamtdue was being rounded incorrectly.  it should only be calculated
*                 		when autoinit = 'Y'.
*    	bc 06/04/01 - do not retrict previous amount calculations based on ProcessGroup
*    	kb 7/3/1 - issue #13115
*     	kb 9/12/1 - issue #14168
*     	kb 9/26/1 - issue #14680
*		kb 10/23/1 - issue #14971
*     	kb 2/19/2 - issue #16147
*   	kb 5/21/2 - issue #17265
*		TJL 11/05/02 - Issue #19211, Allow Releasing Retainage on True T&M Bills with Contracts
*		TJL 02/07/3 - Issue #17278, Update bJBIT.AuditYN to 'Y' after initial insert
*		TJL 06/27/03 - Issue #21628, Problem w/#19211 above, reverse 19211 mods
*		TJL 07/24/03 - Issue #19017, Change JCCi.Description field to 60 char
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 04/18/05 - Issue #28358, Reset @lastprojmth variable for each CostType
*		TJL 09/29/05 - Issue #29638, Only Items in BillGroup should be initialized in Progress Bill when initializing by SeparateInv or BillGroup
*		TJL 09/19/06 - Issue #122338 (5x - #121333), remove (upper from upper(@jccium) = 'LS') to correct calculations for 'Ls' unit of measure
*		TJL 03/13/08 - Issue #127452, Trigger error (Invalid TaxCode) being reported incorrectly.  
*		TJL 07/24/08 - Issue #128287, JB International Sales Tax
*		TJL 12/29/08 - Issue #129896, Update JBIT UnitsClaimed and AmtClaimed
*		TJL 01/05/09 - Issue #120173, Combine Progress and T&M Auto-Initialization
*		TJL 02/10/09 - Issue #132225, JBIT.RetgBilled not set when ContractItem TaxCode is NULL and bill Auto-Initialized
*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*		TJL 06/29/09 - Issue #134596 - Cannot insert NULL into JBIT.RetgBilled error 
*		TJL 07/01/09 - Issue #119759 - Calc Discount on Rounded/Not Rounded @totalamt basis.  Consistent with form calculations.
*		TJL 09/25/09 - Issue #134590 - %Complete incorrect on form because Negative Item got billed a countering Positive Amount.
*		TJL 10/15/09 - Issue #135776 - When InitOpt = B, and missing JCCD for "B"oth Items, Initialize same Items into Bill as 0.00 value.
*		TJL 11/20/09 - Issue #24362 - Include Change Orders on current Bill in Progress calculations.
*		TJL 12/16/09 - Issue #129894/137089, Max Retainage Enhancement
*
* USAGE:
*
*
*  INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
****************************************************************************/
(@co bCompany,@mth bMonth, @contract bContract, @itembillgroup bBillingGroup = null, @invdate bDate,
   	@fromdate bDate = null, @thrudate bDate = null, @procgroup varchar(10), @billnum int, @discrate bPct,
	@acothrudate bDate, @autoinititemget bYN = null, @billinitopt char(1), @msg varchar(255) output)
as

set nocount on

/*generic declares */
declare @rcode int, @errmsg varchar(255), @prevbillnum int, @prevflag bYN,
   	@contractitem bContractItem, @jccium bUM, @taxgroup bGroup, @taxcode bTaxCode, @retgpct bPct,
   	@billorigunits bUnits, @billorigamt bDollar,
   	--@billcurunits bUnits, @billcuramt bDollar, @billunitprice bUnitCost,
   	@previtemunits bUnits, @previtemamt bDollar, @previtemretg bDollar,
   	@previtemrelretg bDollar, @previtemtax bDollar, @previtemdue bDollar, @previtemflag bYN,
   	@prevwc bDollar, @prevwcunits bUnits, @wc bDollar, @wcunits bUnits, @wcretg bDollar, @prevwcretg bDollar, @prevsm bDollar,
   	@prevsmretg bDollar, @prevchgorder bDollar,
   	@prevbillforitem int, @acoitem bACOItem, @aco bACO, @job bJob, @JCOIchgorderunits bUnits,
   	@JCOIchgorderunitprice bUnitCost, @JCOIchgorderamt bDollar, @phase bPhase,
   	@phasegroup bGroup, @costtype bJCCType, @billflag char(1), @lastprojdate bDate, @um bUM,
   	@lastprojmth bMonth, @monthconvert varchar(20), @totalestunits bUnits, @totalestamt bDollar,
   	@estunits bUnits, @estamt bDollar, @actamt bDollar, @actunits bUnits, @totalactunits bUnits,
   	@totalactamt bDollar, @pctcomplete numeric(12,6) /*bPct*/, @prevchgordamt bDollar, @prevchgordunits bUnits,
   	@currcontractunits bUnits, @currcontractamt bDollar, 
   	@unitsbilled bUnits, @totalamt bDollar,
   	@itemretg bDollar,  @itemretgrel bDollar, @itemdisc bDollar, @itemtaxbasis  bDollar, @itemtaxamt bDollar,
   	@itemamtdue  bDollar, @taxrate bRate, @taxphase bPhase, @taxjcctype bJCCType, @prevbillmonth bMonth,
   	@description bItemDesc, @prevbillforitem_month bMonth, @jccpmth bMonth, @restrictbyYN bYN, @roundopt char(1),
   	@jcoi_count int, @jbcx_count int, @unitprice bUnitCost, @jbcousecertifiedyn bYN, @itembilltype char(1), @iteminitaszero bYN,
	@billtype1forproginit char(1), @billtype2forproginit char(1), @autoinit bYN, 
	@maxretgopt char(1), @maxretglimitmet bYN, @maxretgamt bDollar, @billwcretg bDollar, @billsmretg bDollar,
	--International Sales Tax
	@itemretgtax bDollar, @itemretgtaxrel bDollar, @previtemretgtax bDollar, @previtemrelretgtax bDollar,
	@arco bCompany, @arcoinvoicetaxyn bYN, @arcotaxretgyn bYN, @arcosepretgtaxyn bYN

-- Issue #24362
declare @billedcontractunits bUnits, @billedcontractamt bDollar, @billedchgordamt bDollar, @billedchgordunits bUnits
 
select @rcode=0, @autoinit = @autoinititemget, @maxretglimitmet = 'N'

/* Limits Item cursor to specific item billtypes.  Bill Initialization Options will be P, X, or B. 
   This determines what Items will be placed into JBIT.  Whether or not these Items have value is 
   determined later, on an Item by Item basis. "AutoInitYN" has a special meaning at this point:
		@autoinititemget = Y:  Means this process has been initiated by Auto-Initialization.  
		@autoinititemget = N:  Means this process has been initiated by Manual Entry directly from the forms. */
if @billinitopt = 'P'
	begin
	/* Insert P Items only - Values initialized from JCCP (Auto-Initialize) else set to 0.00 (Progress Manual Bill entry). */
	select @billtype1forproginit = 'P', @billtype2forproginit = ''
	end
if @billinitopt = 'X'
	begin
	/* Insert P and B Items - Values initialized from JCCP (Auto-Initialize) else set to 0.00 (Progress Manual Bill entry). */
	select @billtype1forproginit = 'P', @billtype2forproginit = 'B'
	end
if @billinitopt = 'B' and @autoinititemget = 'Y'
	begin
	/* Insert P and B Items - P Items initalized from JCCP, B Items set to 0.00 (Auto-Initialize only). */
	select @billtype1forproginit = 'P', @billtype2forproginit = 'B'
	end
if @billinitopt = 'B' and @autoinititemget = 'N'
	begin
	/* Insert B Items only - B Items set to 0.00 (T&M Manual Bill Entry only). */
	select @billtype1forproginit = '', @billtype2forproginit = 'B'
	end

/*get info for contract*/
select @prevflag='N' /*this flag notes whether a previous bill was found for this contract/process group*/

select @restrictbyYN = RestrictBillGroupYN
from bJBIN with (nolock)
where JBCo = @co and BillMonth = @mth and BillNumber = @billnum

select @roundopt = RoundOpt, @maxretgopt = MaxRetgOpt
from bJCCM with (nolock)
where JCCo = @co and Contract = @contract

/* When used, we need to determine if maximum retainage limits have been met.  This will determine the
   bill item retainage percent defaults and will be used later to decide if maximum limits have been
   exceeded as a result of creating this bill.  */
if @maxretgopt in ('P', 'A')
	begin
	exec @rcode = vspJBMaxRetgCheck @co, @mth, @billnum, @contract, 0, 0, 'JBProgBillItemsInit', @maxretgamt output, @maxretglimitmet output, @msg output
	end
   		
/* Get misc information */
select @arco = j.ARCo, @taxgroup = h.TaxGroup, @jbcousecertifiedyn = b.UseCertified,
	@arcoinvoicetaxyn = a.InvoiceTax, @arcotaxretgyn = a.TaxRetg, @arcosepretgtaxyn = a.SeparateRetgTax
from bJCCO j with (nolock)
join bHQCO h with (nolock) on h.HQCo = j.JCCo
join bARCO a with (nolock) on a.ARCo = j.ARCo
join bJBCO b with (nolock) on b.JBCo = j.JCCo
where j.JCCo = @co
 
/*see if there was a previous bill for this contract*/
select @prevbillmonth = max(BillMonth)
from bJBIN with (nolock)
where JBCo = @co and Contract = @contract and InvStatus <>'D' and
	((BillMonth < @mth ) or (BillMonth = @mth and BillNumber < @billnum))
	--and ((ProcessGroup = @procgroup) or (@procgroup is null))

if @prevbillmonth is not null
   	begin
   	select @prevbillnum = max(BillNumber)
   	from bJBIN with (nolock)
   	where JBCo = @co and Contract = @contract and InvStatus <>'D' and
       	BillMonth = @prevbillmonth and ((BillMonth < @mth) or (BillMonth = @mth and BillNumber < @billnum))
		--and ((ProcessGroup = @procgroup) or (@procgroup is null))
   
	if @prevbillnum is not null select @prevflag = 'Y'
	end
   
/*cycle through items in JCCI*/
select @contractitem = min(Item)
from bJCCI with (nolock)
where JCCo = @co and Contract = @contract 
	and BillType in (@billtype1forproginit,@billtype2forproginit)
	and (isnull(BillGroup, '') = case when @restrictbyYN = 'Y' then isnull(@itembillgroup, '') else isnull(BillGroup, '') end)
   
while @contractitem is not null
   	begin
	/* Initialize all variables to 0 */
   	/* Reset Totals buckets*/
   	select @totalestunits = 0, @totalestamt = 0, @totalactamt = 0, @totalactunits = 0
	/* Reset Previous buckets */
  	select @previtemunits = 0, @previtemamt = 0, @previtemretg  = 0, @previtemretgtax  = 0,
		@previtemrelretg = 0, @previtemrelretgtax = 0, @previtemtax = 0, @previtemdue = 0, @previtemflag = 'N',
	 	@prevwc = 0, @prevwcunits = 0, @prevsm = 0, @prevsmretg = 0, @prevwcretg = 0,
    	@prevchgordunits = 0, @prevchgordamt = 0
	/* Reset Item buckets */
  	select @itemretg=0, @itemretgtax=0, @itemretgrel=0, @itemretgtaxrel=0, @itemdisc=0, @itemtaxbasis=0, 
		@itemtaxamt=0, @itemamtdue=0, @unitsbilled=0, @totalamt=0, @wc = 0, @wcunits = 0, @wcretg = 0,
		@currcontractunits = 0, @currcontractamt = 0, @billedcontractunits = 0, @billedcontractamt = 0,	--#24362
		@billedchgordamt = 0, @billedchgordunits = 0

  	select @description = case when BillDescription is null then Description else BillDescription end,
  		@jccium = UM, @taxcode = TaxCode, 
  		@retgpct = case when (@maxretglimitmet = 'Y' and @autoinititemget = 'N') then 0 else RetainPCT end, --0% only when MaxRetg Limit is met and Manual Bill entry.
  		@unitprice = UnitPrice,	@billorigunits = BillOriginalUnits, @billorigamt = BillOriginalAmt, 
		@itembilltype = BillType, @iteminitaszero = InitAsZero
	 	--@billcurunits = BillCurrentUnits, @billcuramt = BillCurrentAmt, @billunitprice = BillUnitPrice
  	from bJCCI with (nolock)
  	where JCCo = @co and Contract = @contract and Item = @contractitem

	/* Special Consideration */
   	if @billinitopt = 'B' and @autoinititemget = 'Y'
   		begin
   		/* This billing is being Auto-Initialized using Initialize Option "B".  This means that both 'P' and 'B' Items get placed 
   		   into JBIT but only the 'P' Items are initialized with values from JCCP (Cost by Period).  'B' Items are placed onto the bill
   		   at 0.00 value and might later be updated by the T&M process. */
   		select @autoinit = case when @itembilltype = 'P' then 'Y' else 'N' end
   		end

  	/*get tax rate*/
  	if @taxcode is not null
    	begin
		exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output, @taxphase output,
	     	@taxjcctype output, @msg output
		if @rcode <> 0 goto bspexit
		end

   	/*link change orders*/
   	exec @rcode = bspJBChangeOrderAdd @co, @mth, @billnum, @contract, @acothrudate, @contractitem, @msg output
  
  	/*get info from previous billings for this item*/
  	if @prevflag ='Y'
    	begin
    	select @prevbillforitem_month = max(t.BillMonth)
    	from bJBIT t with (nolock)
    	join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth
		where t.JBCo = @co and n.Contract = @contract and Item = @contractitem and InvStatus <>'D' and
       		((t.BillMonth < @mth) or (t.BillMonth = @mth and t.BillNumber < @billnum))
         	--and ((ProcessGroup  = @procgroup) or (@procgroup is null and ProcessGroup is null))
   
    	if @prevbillforitem_month is not null
	  		begin
      		select @prevbillforitem = max(t.BillNumber)
	  		from bJBIT t with (nolock)
      		join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth
	  		where t.JBCo = @co and n.Contract = @contract  and Item = @contractitem and InvStatus <> 'D' and
				t.BillMonth = @prevbillforitem_month and ((t.BillMonth < @mth) or (t.BillMonth = @mth and t.BillNumber < @billnum))
            	--((ProcessGroup  = @procgroup) or (@procgroup is null and ProcessGroup is null))
   
      		if @prevbillforitem is not null
        		begin
           		select @previtemflag = 'Y'
	    		select @previtemunits = PrevWCUnits + WCUnits,
	           		@previtemamt = PrevWC + WC + PrevSM + SM,
	           		@previtemretg  = PrevWCRetg + WCRetg + PrevSMRetg + SMRetg + PrevRetgTax + RetgTax,
					@previtemretgtax = PrevRetgTax + RetgTax,
               		@previtemrelretg = PrevRetgReleased + RetgRel,
					@previtemrelretgtax = PrevRetgTaxRel + RetgTaxRel,
	           		@previtemtax = PrevTax + TaxAmount, @previtemdue = PrevDue + AmountDue,
	           		@prevwc = PrevWC + WC, @prevwcunits = PrevWCUnits + WCUnits, @prevsm = PrevSM + SM,
	           		@prevsmretg = PrevSMRetg + SMRetg, @prevwcretg = PrevWCRetg + WCRetg
	    		from bJBIT with (nolock)
        		where JBCo = @co and BillMonth = @prevbillforitem_month and BillNumber = @prevbillforitem and Item = @contractitem
    			end
      		end
    	end
   
   	if @autoinit = 'Y' and @iteminitaszero = 'N'
    	begin
		/* For this item, determine Estimated/Actual Amts/Units to calculate PctComplete. */
    	select @job = min(Job)
    	from bJCJP with (nolock)
    	where JCCo = @co and Contract = @contract and Item = @contractitem
    	while @job is not null
      		begin
      		select @phasegroup = min(PhaseGroup)
      		from bJCJP with (nolock)
      		where JCCo = @co and Contract = @contract and Item = @contractitem and Job = @job
      		while @phasegroup is not null
        		begin
       			select @phase = min(Phase)
        		from bJCJP with (nolock)
        		where JCCo = @co and Contract = @contract and Item = @contractitem and Job = @job and PhaseGroup = @phasegroup
        		while @phase is not null
          			begin
          			select @costtype = min(CostType)
          			from bJCCH with (nolock)
          			where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase
          			while @costtype is not null
            			begin
						select @lastprojmth = null	--clear out for each new CostType
   
               			select @um = UM, @billflag = BillFlag, @lastprojdate = LastProjDate
           				from JCCH with (nolock)
                		where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and CostType = @costtype
   
						/*get estimates from JCCP*/
						if @lastprojdate is not null
			  				begin
			  				select @monthconvert = convert(varchar(20),datepart(mm,@lastprojdate) ) + '/1/' +
   	                     	convert(varchar(20),datepart(yy,@lastprojdate))
			  				select @lastprojmth = @monthconvert
              				end
   
            			select @jccpmth = min(Mth)
            			from bJCCP with (nolock)
            			where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and CostType = @costtype and Mth <= @mth
   
            			while @jccpmth is not null
              				begin
              				select @estunits = Case @billflag when 'Y' then
                               		Case when isnull(@lastprojmth, '') = isnull(@mth, '') then sum(ProjUnits) else sum(CurrEstUnits) end
									else 0 end,
			         			@estamt = Case when @billflag = 'Y' or @billflag = 'C' then
                                 	Case when isnull(@lastprojmth, '') = isnull(@mth, '') then sum(ProjCost) else sum(CurrEstCost) end
                               		else 0 end,
     			     			@actamt = Case when @billflag = 'Y' or @billflag = 'C' then sum(ActualCost) else 0 end,
   	                 			@actunits = Case @billflag when 'Y' then sum(ActualUnits) else 0 end
              				from bJCCP with (nolock)
              				where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and CostType = @costtype and Mth = @jccpmth
   
              				select @totalestamt = @totalestamt + isnull(@estamt,0),
                     			@totalestunits = isnull(@totalestunits,0) + isnull(@estunits,0),
                     			@totalactamt = @totalactamt + isnull(@actamt,0),
                     			@totalactunits = @totalactunits + isnull(@actunits,0)
   
              				select @jccpmth = min(Mth)
              				from bJCCP with (nolock)
              				where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and
                    			CostType = @costtype and Mth > @jccpmth and Mth <= @mth
              				if @@rowcount = 0 select @jccpmth = null
              				end
   
						select @costtype = min(CostType)
            			from bJCCH with (nolock)
            			where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and CostType > @costtype
						if @@rowcount = 0 select @costtype = null
						end

          			select @phase = min(Phase)
          			from bJCJP with (nolock)
          			where JCCo = @co and Contract = @contract and Item = @contractitem and Job = @job and PhaseGroup = @phasegroup and Phase > @phase
          			end

        		select @phasegroup = min(PhaseGroup)
        		from bJCJP with (nolock)
        		where JCCo = @co and Contract = @contract and Item = @contractitem and Job = @job and PhaseGroup > @phasegroup
        		end
   
      		select @job = min(Job)
      		from bJCJP with (nolock)
      		where JCCo = @co and Contract = @contract and Item = @contractitem and Job > @job
      		end
   
    	if @jccium = 'LS'
      		begin
      		/*issue #17265 - don't exceed 100% on LS items*/
      		select @pctcomplete = Case @totalestamt when 0 then 0 else
      			case when @totalactamt/@totalestamt > 1 then 1 else
      				@totalactamt/@totalestamt end end
      		end
    	else
      		begin
      		select @pctcomplete = Case @totalestunits when 0 then 0 else
      			@totalactunits/@totalestunits end
      		end
    	end
   
	-- do not include this bill's change order amount in the Current Contract amount until the next bill.
  	-- AIA and other reports are written based upon this.  (Do Not change)
  	select  @prevchgordunits =isnull(sum(s.ChgOrderUnits),0), @prevchgordamt =isnull(sum(s.ChgOrderAmt),0)
  	from bJBIS s with (nolock)
	join bJBIN n with (nolock) on s.JBCo = n.JBCo and s.BillMonth = n.BillMonth and  s.BillNumber = n.BillNumber
  	where  s.JBCo = @co and	((s.BillMonth < @mth) or (s.BillMonth = @mth and s.BillNumber < @billnum)) and
   		s.Item = @contractitem and n.Contract = @contract

	-- Issue #24362 (Billed Change Order amounts)
	select  @billedchgordunits =isnull(sum(s.ChgOrderUnits),0), @billedchgordamt =isnull(sum(s.ChgOrderAmt),0)
	from bJBIS s with (nolock)
	join bJBIN n with (nolock) on s.JBCo = n.JBCo and s.BillMonth = n.BillMonth and  s.BillNumber = n.BillNumber
	where  s.JBCo = @co and	((s.BillMonth < @mth) or (s.BillMonth = @mth and s.BillNumber <= @billnum)) and	
	s.Item = @contractitem and n.Contract = @contract
	----
	  		
  	select @currcontractunits = @billorigunits + @prevchgordunits,
   		@currcontractamt = @billorigamt + @prevchgordamt

	-- Issue #24362 (Billed Change Order values) 
	select @billedcontractunits = @billorigunits + @billedchgordunits,
		@billedcontractamt = @billorigamt + @billedchgordamt
   	----
   		
   	if @autoinit = 'Y' and @iteminitaszero = 'N'
    	begin
		/* For this item, calculate the various amounts. */
		if @pctcomplete <> 0
			begin	

			-- For Issue #24362, I replaced @currcontractamt and @currcontractunits with @billedcontractamt and @billedcontractamt BELOW
			-- 5 occurances immediately below and NO OTHERS throughout rest of procedure.
			
			/* @pctcomplete comes from Cost by Period (JCCP).  If there are no Costs (or no estimated costs) then there can
			   be no percent complete.  If nothing is complete, do not bill.  Skip the following code. */
   			select @unitsbilled = (@billedcontractunits * @pctcomplete) - @previtemunits,
 				@totalamt = case upper(@jccium) when 'LS' then
 				(@billedcontractamt * @pctcomplete) - @previtemamt else
 				(@billedcontractunits * @unitprice * @pctcomplete) - (@previtemunits * @unitprice) end

    		if @unitsbilled < 0 select @unitsbilled = 0			--if more units have previously been bill than actually completed, no units billed this bill.
    		if @totalamt < 0 and @billedcontractamt > 0 select @totalamt = 0	--(Positive Item) If item has previously been overbilled, do not back out the amount.
    		if @totalamt > 0 and @billedcontractamt < 0 select @totalamt = 0	--(Negative Item) If item has previously been overbilled, do not back out the amount.
			end					
			
    	select @wc = @totalamt, @wcunits = @unitsbilled, @wcretg = @totalamt * isnull(@retgpct,0)
		--	@itemdisc = @totalamt * isnull(@discrate,0)		

		if @taxcode is null or @arcoinvoicetaxyn = 'N'
			begin
			/* Either No TaxCode on this Item or AR Company is set to No Tax on Invoice/Bills */
			select @itemtaxbasis = 0, @itemtaxamt = 0, @itemretgtax = 0, @itemretg = @wcretg 
			end
		else 
			begin 
			/* TaxCode does exist and AR Company is set for Tax on Invoice/Bills */
			if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'
				begin
				/* Standard US */
				select @itemtaxbasis = @totalamt				--@totalamt same as @wc
				select @itemtaxamt = @itemtaxbasis * @taxrate	
				select @itemretgtax = 0
				select @itemretg = @wcretg
				end
			if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
				begin
				/* International with RetgTax */
				select @itemtaxbasis = @totalamt - @wcretg		--@totalamt same as @wc
				select @itemtaxamt = @itemtaxbasis * @taxrate
				select @itemretgtax = @wcretg * @taxrate	
				select @itemretg = @wcretg + @itemretgtax
				end
			if @arcotaxretgyn = 'N'
				begin
				/* International no RetgTax */
				select @itemtaxbasis = @totalamt - @wcretg		--@totalamt same as @wc
				select @itemtaxamt = @itemtaxbasis * @taxrate
				select @itemretgtax = 0
				select @itemretg = @wcretg
				end			
			end

    	select @itemamtdue = @totalamt + @itemtaxamt - @wcretg		
    	end
   
	/*insert JBIT record*/
	if not exists(select 1 from bJBIT with (nolock) where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @contractitem)
		begin
		if @roundopt <> 'N'
  			begin
  			select @totalamt = round(@totalamt,0), @itemtaxbasis = round(@itemtaxbasis,0),
         		@itemtaxamt = round(@itemtaxamt,0), @wc = round(@wc,0)
  			if @roundopt = 'R'
    			begin
    			select @wcretg = round(@wcretg,0), @itemretg = round(@itemretg,0),
					@itemretgtax = round(@itemretgtax,0)
    			end

  			if @autoinit = 'Y' select @itemamtdue = @totalamt + @itemtaxamt - @wcretg	
  			end
   
		/* Calculate Discount at last moment.  The @totalamt basis might be 0, or rounded, or not rounded.
		   In any case, the calculated discount value will be consistent with manual form entry and similar calcs. */
		select @itemdisc = @totalamt * isnull(@discrate,0)
		   
		insert into bJBIT (JBCo, BillMonth, BillNumber, Item, Description, UnitsBilled, AmtBilled,
			RetgBilled, RetgTax, RetgRel, RetgTaxRel, Discount, TaxBasis, TaxAmount, AmountDue,
			PrevUnits, PrevAmt, PrevRetg, PrevRetgTax, PrevRetgReleased, PrevRetgTaxRel,
			PrevTax, PrevDue, ARLine, ARRelRetgLine, ARRelRetgCrLine, TaxGroup, TaxCode,
			CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, WCUnits, WCRetg,
			PrevSM, Installed, Purchased, SM, SMRetg, PrevSMRetg, PrevWCRetg,
			BillGroup, Contract, WCRetPct, AuditYN, UnitsClaimed, AmtClaimed)
		values (@co, @mth, @billnum, @contractitem, @description, @unitsbilled, @totalamt,
			@itemretg, @itemretgtax, @itemretgrel, @itemretgtaxrel, @itemdisc, @itemtaxbasis, @itemtaxamt, @itemamtdue,
			@previtemunits, @previtemamt, @previtemretg, @previtemretgtax, @previtemrelretg, @previtemrelretgtax,
			@previtemtax, @previtemdue, null, null, null, @taxgroup, @taxcode,
			@currcontractamt,  @currcontractunits, @prevwc, @prevwcunits, @wc, @wcunits, @wcretg,
			@prevsm, 0, 0, 0, 0, @prevsmretg, @prevwcretg,
			@itembillgroup, @contract, @retgpct,'N', 
			case when @jbcousecertifiedyn = 'N' then 0 else @wcunits end, 
			case when @jbcousecertifiedyn = 'N' then 0 else @totalamt end)		--@totalamt same as @wc	
   
		update bJBIT
		set AuditYN = 'Y'
		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @contractitem
		end

   	/*get next contract item*/
   	select @contractitem = min(Item)
   	from bJCCI with (nolock)
   	where JCCo = @co and Contract = @contract 
   		and BillType in (@billtype1forproginit,@billtype2forproginit)
   		and (isnull(BillGroup, '') = case when @restrictbyYN = 'Y' then isnull(@itembillgroup, '') else isnull(BillGroup, '') end)
   		and Item > @contractitem
   	end

/* If the Contract is set to enforce Maximum Retainage limits and if the Billing has been Auto-Initialized,
   we now need to do the appropriate Maximum Retainage checks and updates as needed. This is NOT necessary for:
   a)  Contracts not set to use the Maximum Retainage feature.
   b)  Bills being created manually since the Bill Item Retainage % default was established earlier in the procedure. */   		
if @maxretgopt in ('P', 'A') and @autoinititemget = 'Y'
	begin
	/* Bill has been Auto Initialized so JBIT Retainage % is still set to the value from JCCI. */
	select @billwcretg = isnull(sum(t.WCRetg), 0)		--, @billsmretg = isnull(sum(t.SMRetg), 0)
	from bJBIT t with (nolock)
	where t.JBCo = @co and t.BillMonth = @mth and t.BillNumber = @billnum 
		and t.WCRetPct <> 0
		
	if @maxretglimitmet = 'Y' and @billwcretg = 0
		begin
		/* Maximum Retainage Limit was reached on an earlier Billing and this bill has no Negative
		   Change Orders (Negative Items) that would reduce the overall retainage amount below the
		   maximum limit.  Therefore update JBIT Retainage % to be 0% now. */
		update bJBIT
		set WCRetPct = 0
		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
		end
	else
		begin
		/* Bill has initialized automatically.  Regardless of Maximum Retainage Limit flag before initialization
		   we must now do a Max Retainage Check and Update, if it is required to correct the new billing. */
		exec @rcode = vspJBMaxRetgCheck @co, @mth, @billnum, @contract, 0, 0, 'JBProgBillItemsInit', @maxretgamt output, @maxretglimitmet output, @msg output
		if @rcode = 1
			begin
			select @msg = 'Maximum Retainage checks failed. - ' + @msg
			goto bspexit
			end
		if @rcode = 7 
			begin
			exec @rcode = vspJBMaxRetgUpdate @co, @mth, @billnum, @contract, @maxretgamt, 'N', 'N', 0, 0, 0, 0,
				'N', 'JBProgBillItemsInit', @msg output
			
			if @rcode = 1
				begin
				select @msg = ' Maximum Retainage update has failed. - ' + @msg
				goto bspexit
				end
			end
		end
	end
   		   
bspexit:
return @rcode





GO
GRANT EXECUTE ON  [dbo].[bspJBProgressBillItemsInit] TO [public]
GO
