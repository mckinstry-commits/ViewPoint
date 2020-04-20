SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBProgItemDflts    Script Date: 8/28/99 9:36:19 AM ******/
CREATE  proc [dbo].[bspJBProgItemDflts]

/****************************************************************************
* CREATED BY: bc 10/05/99
* MODIFIED By : kb 3/27/00 - added billtype restriction
*		kb 5/22/00 - changed bBillGroup to be bBillingGroup
*		danf corrected convert(float(6,4)... to convert(decimal(6,4),...
*		TJL 02/23/06 - Issue #28051, 6x recode. Return ThisItemChgOrderAmt and ThisItemChgOrderUnits
*		TJL 07/18/08 - Issue #128287, JB International Sales Tax
*		TJL 10/30/08 - Issue #129895, Add JCCI.BillGroup to JBProgressBillItems grid for display only
*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*
* USAGE:
* defaults the previous Item Total values for a new item entered in JBIT
* item* variables represent the values that are to be returned to the current grid fields
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
(@jbco bCompany, @billmth bMonth, @billnum int, @jbcontract bContract, @jbcontractitem bContractItem,
/* outputs */
	@desc bDesc = null output,
	@jccium bUM output,
	@sicode bContractItem = null output,
	@taxrate bRate output,
	@prevunitsbilled bUnits output,
	@prevamtbilled bDollar output,
	@prevretgbilled bDollar output,
	@previtemrelretg bDollar output,
	@previtemtax bDollar output,
	@previtemdue bDollar output,
	@taxcode bTaxCode output,
	@currcontractamt bDollar output,
	@currcontractunits bUnits output,
	@prevwc bDollar output,
	@prevwcunits bUnits output,
	@prevsm bDollar output,
	@prevsmretg bDollar output,
	@prevwcretg bDollar output,
	@unitprice bUnitCost output,
	@retgpct bPct output,
	@thisitemchgordamt bDollar output,
	@thisitemchgordunits bUnits output,
	@previtemretgtax bDollar output,
	@previtemrelretgtax bDollar output,
	@jccibillgroup bBillingGroup output,
	@sicodedesc bItemDesc output,
	@billgroupdesc bDesc output,
	@msg varchar(255) output)
as

set nocount on

/*generic declares */
declare @rcode int, @errmsg varchar(255)
   
declare @itembillgroup bBillingGroup, @invdate bDate, @thrudate bDate, @procgroup varchar(10),  @discrate bPct,
	@prevbillnum int, @prevflag bYN, @acothrudate bDate, @taxgroup bGroup,
	@billunitprice bUnitCost, @billorigunits bUnits, @billorigamt bDollar, @billcurunits bUnits, @billcuramt bDollar,
	@previtemflag bYN, @prevchgorder bDollar,
	@prevbillforitem_month bMonth, @prevbillforitem int, @acoitem bACOItem, @aco bACO, @job bJob,
	@JCOIchgorderunits bUnits, @JCOIchgorderamt bDollar,  
	@phasegroup bGroup, @phase bPhase, @jbcosttype bJCCType, @billflag char(1), @lastprojdate bDate, @um bUM,
	@lastprojmth bMonth, @monthconvert varchar(20), @totalestunits bUnits, @totalestamt bDollar,
	@estunits bUnits, @estamt bDollar, @actamt bDollar, @actunits bUnits, @totalactunits bUnits,
	@totalactamt bDollar, @pctcomplete  float, @prevchgordamt bDollar, @prevchgordunits bUnits,
	@taxphase bPhase, @taxjcctype bJCCType, @prevbillmonth bMonth
   
select @rcode=0

/* get info from jbin */
select @procgroup = ProcessGroup, @itembillgroup = BillGroup,  @invdate = InvDate, @thrudate = ToDate
from bJBIN with (nolock)
where JBCo = @jbco and BillNumber = @billnum

/* prevflag notes whether a previous bill was found for this contract/process group*/
select @prevflag='Y',@acothrudate = @thrudate

/*see if there was a previous bill for this contract*/
select @prevbillmonth = max(BillMonth)
from bJBIN with (nolock)
where JBCo = @jbco and Contract = @jbcontract and InvStatus <>'D' and InvDate <= @invdate and
	((BillNumber <> @billnum) or (BillNumber = @billnum and BillMonth <> @billmth))	and
	((ProcessGroup = @procgroup) or (@procgroup is null)) and
	((BillGroup = @itembillgroup) or (@itembillgroup is null))
   
if @prevbillmonth is not null
	begin
	select @prevbillnum = max(BillNumber)
	from bJBIN with (nolock)
	where JBCo = @jbco and Contract = @jbcontract and InvStatus <>'D' and InvDate <= @invdate and
		((ProcessGroup = @procgroup) or (@procgroup is null)) and
		((BillGroup = @itembillgroup) or (@itembillgroup is null)) and
		BillMonth = @prevbillmonth and ((BillNumber <> @billnum) or (BillNumber = @billnum and BillMonth <> @billmth))
	if @prevbillnum is null select @prevflag = 'N'
	end
else
	begin
	select @prevflag = 'N'
	end

select @desc = case when i.BillDescription is null then i.Description else i.BillDescription end,
	@jccium = i.UM, @taxgroup = i.TaxGroup, @taxcode = i.TaxCode, @retgpct = i.RetainPCT, @unitprice = i.UnitPrice,
	@billorigunits = i.BillOriginalUnits, @billorigamt = i.BillOriginalAmt,
	@billcurunits = i.BillCurrentUnits, @billcuramt = i.BillCurrentAmt, @billunitprice = i.BillUnitPrice,
	@sicode = i.SICode, @jccibillgroup = i.BillGroup, @sicodedesc = s.Description, @billgroupdesc = b.Description
from bJCCI i with (nolock)
left join bJBBG b with (nolock) on b.JBCo = i.JCCo and b.Contract = i.Contract and b.BillGroup = i.BillGroup
left join bJCSI s with (nolock) on s.SIRegion = i.SIRegion and s.SICode = i.SICode
where i.JCCo = @jbco and i.Contract = @jbcontract and i.Item = @jbcontractitem
   
if @@rowcount = 0
	begin
	select @msg = 'Contract Item not in JC Contract Items.', @rcode = 1
	goto bspexit
	end
   
/*get tax rate*/
if @taxcode is not null
	begin
	exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output, @taxphase output,
	   @taxjcctype output, @errmsg output
	if @rcode <> 0
		begin
		select @msg = @msg + @errmsg, @rcode = 1
		goto bspexit
		end
	end
   
/* if todate is passed in as null then the implication is that it equals the most current date available in JCOH */
if @acothrudate is null select @acothrudate = max(ApprovalDate) from JCOH where JCCo = @jbco and Contract = @jbcontract

select @JCOIchgorderunits = 0, @JCOIchgorderamt = 0

/*link change orders*/
select @job = min(Job)
from bJCOH with (nolock)
where JCCo = @jbco and Contract = @jbcontract and ApprovalDate <= @acothrudate
   
while @job is not null
	begin
	select @aco = min(h.ACO)
	from bJCOH h with (nolock)
	join bJCOI i with (nolock) on h.JCCo = i.JCCo and h.Job = i.Job and h.ACO = i.ACO  --TJL: Why is this necessary ???
	where h.JCCo = @jbco and h.Contract = @jbcontract and i.Item = @jbcontractitem and h.ApprovalDate <= @acothrudate and
		((h.BillGroup = @itembillgroup) or (h.BillGroup is null and @itembillgroup is null)) and h.Job = @job
	while @aco is not null
        begin
        select @acoitem = min(ACOItem)
        from bJCOI o with (nolock)
        join bJCCI i  with (nolock) on i.JCCo = o.JCCo and i.Contract = o.Contract and i.Contract = o.Contract
        where o.JCCo = @jbco and o.Job = @job and o.Contract = @jbcontract and
			o.Item = @jbcontractitem and o.ACO = @aco and
			((o.BillGroup = @itembillgroup) or (o.BillGroup is  null and @itembillgroup is null))
			and o.ApprovedMonth <= @billmth and (i.BillType = 'P' or i.BillType = 'B')
   
        while @acoitem is not null
			Begin
			select @JCOIchgorderunits = @JCOIchgorderunits + ContractUnits,
				@JCOIchgorderamt = @JCOIchgorderamt + ContractAmt
			from bJCOI with (nolock)
			where JCCo = @jbco and Job = @job and ACO = @aco and ACOItem = @acoitem and Contract = @jbcontract

			/*if change order header (JBCC) does not exist it gets added in the JBCX insert trigger*/

			/*get next aco item*/
			select @acoitem = min(ACOItem)
			from bJCOI o with (nolock)
			join bJCCI i  with (nolock) on i.JCCo = o.JCCo and i.Contract = o.Contract and i.Contract = o.Contract
			where o.JCCo = @jbco and o.Job = @job and o.Contract = @jbcontract and
				o.Item = @jbcontractitem and o.ACO = @aco and
				((o.BillGroup = @itembillgroup) or (o.BillGroup is  null and @itembillgroup is null))
				and o.ApprovedMonth <= @billmth and (i.BillType = 'P' or i.BillType = 'B')
				and ACOItem> @acoitem
   
			if @@rowcount = 0 select @acoitem = null
			End
   
        /*get next aco*/
        select @aco = min(h.ACO)
        from bJCOH h with (nolock)
		join bJCOI i with (nolock) on h.JCCo = i.JCCo and h.Job = i.Job and h.ACO = i.ACO
        where h.JCCo = @jbco and h.Contract = @jbcontract and i.Item = @jbcontractitem and ((h.BillGroup = @itembillgroup) or
			(h.BillGroup is null and @itembillgroup is null)) and h.Job = @job and h.ACO > @aco
   
		if @@rowcount = 0 select @aco = null
		end
   
	select @job = min(Job)
	from bJCOH with (nolock)
	where JCCo = @jbco and Contract = @jbcontract and Job > @job
	if @@rowcount = 0 select @job = null
	end
   
/*loop thru JCJP*/
/*reset Estimated Buckets*/
select @totalestunits = 0, @totalestamt = 0, @totalactamt = 0, @totalactunits = 0
/*get info from previous billings for this item*/
select @prevunitsbilled = 0, @prevamtbilled = 0, @prevretgbilled  = 0,
	@previtemrelretg = 0, @previtemtax = 0, @previtemdue = 0,
	@prevwc = 0, @prevwcunits = 0, @prevsm = 0, @prevsmretg = 0, @prevwcretg = 0,
	@prevchgordunits = 0, @prevchgordamt = 0, @prevwc = 0, @prevwcunits = 0,
	@previtemretgtax = 0, @previtemrelretgtax = 0
   
if @prevflag ='Y'
	begin
	select @previtemflag = 'Y'
	select @prevbillforitem_month = max(t.BillMonth)
	from bJBIT t with (nolock)
	join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth
	where t.JBCo = @jbco and n.Contract = @jbcontract and Item = @jbcontractitem and InvStatus <>'D' and InvDate <= @invdate and
		((ProcessGroup  = @procgroup) or (@procgroup is null and ProcessGroup is null)) and
		((t.BillGroup = @itembillgroup) or (@itembillgroup is null and t.BillGroup is null)) and
		((t.BillNumber <> @billnum) or (t.BillNumber = @billnum and t.BillMonth <> @billmth))
   
	if @prevbillforitem_month is not null
		begin
		select @prevbillforitem = max(t.BillNumber)
		from bJBIT t with (nolock)
		join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth
		where t.JBCo = @jbco and n.Contract = @jbcontract  and Item = @jbcontractitem and InvStatus <> 'D' and InvDate <= @invdate  and
			((ProcessGroup  = @procgroup) or (@procgroup is null and ProcessGroup is null)) and
			((t.BillGroup = @itembillgroup) or (@itembillgroup is null and t.BillGroup is null)) and
				t.BillMonth = @prevbillforitem_month and
			((t.BillNumber <> @billnum) or (t.BillNumber = @billnum and t.BillMonth <> @billmth))
   
    	if @prevbillforitem is null select @previtemflag = 'N'
    	end
	else
        begin
    	select @previtemflag = 'N'
    	end
   
	if @previtemflag='Y'
        begin
        select @prevunitsbilled = PrevUnits + UnitsBilled, @prevamtbilled = PrevAmt + AmtBilled,
			@prevretgbilled  = PrevRetg + RetgBilled, 	@previtemrelretg = PrevRetgReleased + RetgRel,
			@previtemtax = PrevTax + TaxAmount, @previtemdue = PrevDue + AmountDue,
			@prevwc = PrevWC + WC, @prevwcunits = PrevWCUnits + WCUnits, @prevsm = SM,
			@prevsmretg = SMRetg, @prevwcretg = PrevWCRetg + WCRetg,
			@previtemretgtax = PrevRetgTax + RetgTax, @previtemrelretgtax = PrevRetgTaxRel + RetgTaxRel
        from bJBIT with (nolock)
        where JBCo = @jbco and BillMonth = @prevbillforitem_month and BillNumber = @prevbillforitem and Item = @jbcontractitem
        end
	end
   
    select @job = min(Job)
    from bJCJP with (nolock)
    where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractitem
    while @job is not null
		begin
		select @phasegroup = min(PhaseGroup)
		from bJCJP with (nolock)
		where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractitem and Job = @job
		while @phasegroup is not null
			begin
			select @phase = min(Phase)
			from bJCJP with (nolock)
			where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractitem and Job = @job and PhaseGroup = @phasegroup
			while @phase is not null
				begin
				select @jbcosttype = min(CostType)
				from bJCCH with (nolock)
				where JCCo = @jbco and Job = @job and PhaseGroup = @phasegroup and Phase = @phase
				while @jbcosttype is not null
					begin
					select @um = UM, @billflag = BillFlag, @lastprojdate = LastProjDate
					from bJCCH with (nolock)
					where JCCo = @jbco and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and CostType = @jbcosttype

					/*get estimates from JCCP*/
					if @lastprojdate is not null
						begin
						select @monthconvert = convert(varchar(20),datepart(mm,@lastprojdate) ) + '/1/' +	convert(varchar(20),datepart(yy,@lastprojdate))
						select @lastprojmth = @monthconvert
						end

					select @estunits = Case @billflag when 'Y' then Case when @lastprojmth = @billmth then sum(ProjUnits) else sum(CurrEstUnits) end else 0 end,
						   @estamt = Case when @billflag = 'Y' or @billflag = 'C' then Case when @lastprojmth = @billmth then sum(ProjCost) else sum(CurrEstCost) end else 0 end,
						   @actamt = Case when @billflag = 'Y' or @billflag = 'C' then sum(ActualCost) else 0 end,
						   @actunits = Case @billflag when 'Y' then sum(ActualUnits) else 0 end
					from bJCCP with (nolock)
					where JCCo = @jbco and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and CostType = @jbcosttype

					select @totalestamt = @totalestamt + @estamt, @totalestunits = isnull(@totalestunits,0) + isnull(@estunits,0),
						   @totalactamt = @totalactamt + @actamt, @totalactunits = @totalactunits + @actunits

					select @jbcosttype = min(CostType)
					from bJCCH with (nolock)
					where JCCo = @jbco and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and CostType > @jbcosttype
					if @@rowcount = 0 select @jbcosttype = null
					end				

				select @phase = min(Phase)
				from bJCJP with (nolock)
				where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractitem and Job = @job and
					PhaseGroup = @phasegroup and Phase > @phase
				end

			select @phasegroup = min(PhaseGroup)
			from bJCJP with (nolock)
			where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractitem and Job = @job and PhaseGroup > @phasegroup
			end

		select @job = min(Job)
		from bJCJP with (nolock)
		where JCCo = @jbco and Contract = @jbcontract and Item = @jbcontractitem and Job > @job
		end

	select @pctcomplete = Case @jccium when 'LS' then Case when @totalestamt=0 then 0 else
		convert(decimal(6,4),@totalactamt/@totalestamt) end else
		Case when @totalestunits=0 then 0 else convert(decimal(6,4),(@totalactunits/@totalestunits)) end
    end
   
select @thisitemchgordunits = isnull(sum(x.ChgOrderUnits),0), @thisitemchgordamt = isnull(sum(x.ChgOrderAmt),0)
from JBIN n with (nolock)
join bJBCC c with (nolock)on c.JBCo = n.JBCo and c.BillMonth = n.BillMonth and c.BillNumber = n.BillNumber
join bJBCX x with (nolock) on x.JBCo = c.JBCo and x.BillMonth = c.BillMonth and x.BillNumber = c.BillNumber and x.ACO = c.ACO and
	x.Job = c.Job and x.ACOItem = @jbcontractitem
where c.JBCo = @jbco and n.Contract = @jbcontract and n.InvDate <= @invdate and
	((n.BillNumber <> @billnum) or (n.BillNumber = @billnum and n.BillMonth <> @billmth))
   
   
select @currcontractunits = @billorigunits +  (isnull(@JCOIchgorderunits,0) - isnull(@thisitemchgordunits,0)),
	@currcontractamt = @billorigamt + (isnull(@JCOIchgorderamt,0) - isnull(@thisitemchgordamt,0))
   
bspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBProgItemDflts] TO [public]
GO
