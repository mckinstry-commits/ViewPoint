SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBUpdatePrevValues]
/***********************************************************
* CREATED BY: 	TJL - 01/29/03, Issue #17278
* MODIFIED By : TJL - 03/19/03, Issue #17278, Dealt with a problem Updating bJBIN PrevValues
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 12/16/03 - Issue #21076, Call Update Previous ChgOrder Values 
*		TJL 07/30/04 - Issue #25260, Update ChgOrderAdds/Deds by BillGroup
*		TJL 07/28/08 - Issue #128287, JB International Sales Tax
*
* USAGE:
*	Users call this from either JBT&MBill or JBProgBill, File Menu, to
*	Update Previous Amounts using the displayed bill as the starting point
*	and updating all later bills items that are associated with the 
*	displayed bill.
*
* INPUT PARAMETERS
*	@co				JB Company
*	@billmth		Bill Month of Item being inserted, updated or deleted
*	@billnum		Bill Number on which Item is being inserted, updated or deleted
*	@contract		Contract that Item pertains to
*   
*
* OUTPUT PARAMETERS
*   @errmsg      error message if update fail.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
@co bCompany, @billmth bMonth, @billnum int, @contract bContract, 
	@errmsg varchar(255) output
   
as
set nocount on

declare @item bContractItem, @rcode int, @invstatus char(1), @opencursor1 int, @opencursor2 int, 
   	@billgroup bBillingGroup, @invunits bUnits, 
   	@invtotal bDollar, @invretg bDollar, @invretgtax bDollar, @invrelretg bDollar, @invrelretgtax bDollar, @invtax bDollar, 
   	@invdue bDollar, @wc bDollar, @wcunits bUnits, @sm bDollar, @smretg bDollar,
   	@wcretg bDollar, @previnvunits bUnits, @prevamt bDollar, @previnvretg bDollar, @previnvretgtax bDollar,
   	@previnvrelretg bDollar, @previnvrelretgtax bDollar, @previnvtax bDollar, @previnvdue bDollar, @prevwc bDollar, 
   	@prevwcunits bUnits, @prevsm bDollar, @prevsmretg bDollar, @prevwcretg bDollar,
   	@prevupdateyn bYN,
   
   	@newprevunits bUnits, @newprevamt bDollar, @newprevretg bDollar, @newprevretgtax bDollar, 
	@newprevretgrel bDollar, @newprevretgtaxrel bDollar,
   	@newprevtax bDollar, @newprevdue bDollar, @newprevwc bDollar, @newprevwcunits bUnits, 
   	@newprevsm bDollar,	@newprevsmretg bDollar, @newprevwcretg bDollar, 
   
   	@ltrbillmth bMonth, @ltrbillnum int, @ltrinvunits bUnits, 
   	@ltrinvtotal bDollar, @ltrinvretg bDollar, @ltrinvretgtax bDollar, @ltrinvrelretg bDollar, 
	@ltrinvrelretgtax bDollar, @ltrinvtax bDollar, 
   	@ltrinvdue bDollar, @ltrwc bDollar, @ltrwcunits bUnits, @ltrsm bDollar, @ltrsmretg bDollar,
   	@ltrwcretg bDollar
   
select @rcode = 0, @opencursor1 = 0, @opencursor2 = 0
   
if @co is null or @billmth is null or @billnum is null or @contract is null
   	begin
   	select @errmsg = 'Company or BillMonth or BillNumber or Contract may not be Null.', @rcode = 1
   	goto errorinitial
   	end
   
/* Do not allow this manual update procedure to be run if JBCO is set to update automatically.
  Trigger conflicts causing double updates to bJBIN require that this manual update 
  procedure only be run when the trigger update process is disabled. */
select @prevupdateyn = PrevUpdateYN 
from bJBCO with (nolock) 
where JBCo = @co
if @prevupdateyn = 'Y'
   	begin
   	select @errmsg = 'Previous values on future bills are being updated automatically!' + char(10) + char(13)
   	select @errmsg = @errmsg + 'To update manually, you must first turn off the JBCO flag.', @rcode = 1
   	goto errorinitial
   	end

/* Nuisance error because user ignored all others from the form */
select 1
from bJBIN with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
if @@rowcount = 0
   	begin
   	select @errmsg = 'Starting Bill does not exist.', @rcode = 1
   	goto errorinitial
   	end
   
/* This bill may not be marked as (D)eleted in order to begin with valid values. */
select @invstatus = InvStatus, @billgroup = BillGroup
from bJBIN with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
if @invstatus = 'D'
   	begin
   	select @errmsg = 'Starting Bill must not be Status (D) Deleted.', @rcode = 1
   	goto errorinitial
   	end
   
/* First Update Previous ChgOrderAdds/Deds */
exec @rcode = bspJBUpdatePrevChgOrderValues @co, @billmth, @billnum, null, null,
	null, null, @billgroup, @errmsg output
   
if @rcode = 1 goto error2

/* Next Update Previous Billed amounts. 
  Decided to let this update complete or rollback on error before allowing further 
  changes to existing bills. */
Begin Transaction
   
/* Get The values from the Starting Bill for which the user is currently showing in 
  the form. This bill may contain items left unbilled however if Item BillGroups have
  been utilized, this bill will ONLY contain those items specified by the BillGroup.
  It is OK to then update all Items on this bill and forward without affecting bills
  generated using a different BillGroup. */
declare bcThisBillItem cursor local fast_forward for
select Item
from bJBIT with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
order by Item
   
open bcThisBillItem
select @opencursor1 = 1

fetch next from bcThisBillItem into @item
while @@fetch_status = 0
   	begin	/* Begin Item Loop */
   
   	/* Get billed and Previous values for this item of this bill.  These will be our
      	   beginning values for the update process. */
   	select @invunits = UnitsBilled, @invtotal = AmtBilled, @invretg = RetgBilled, @invretgtax = RetgTax,
   		@invrelretg = RetgRel, @invrelretgtax = RetgTaxRel, @invtax = TaxAmount, @invdue = AmountDue, @wc = WC, 
   		@wcunits = WCUnits, @sm = SM, @smretg = SMRetg, @wcretg = WCRetg, 
   		@previnvunits = PrevUnits, @prevamt = PrevAmt, @previnvretg = PrevRetg, @previnvretgtax = PrevRetgTax,
   		@previnvrelretg = PrevRetgReleased, @previnvrelretgtax = PrevRetgTaxRel, @previnvtax = PrevTax, @previnvdue = PrevDue, 
   		@prevwc = PrevWC, @prevwcunits = PrevWCUnits, @prevsm = PrevSM, 
   		@prevsmretg = PrevSMRetg, @prevwcretg = PrevWCRetg
   	from bJBIT with (nolock)
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   
   	/* This bills Previous values combined with its current billed amounts makes up
   	   the previous values for the next bill. */
   	select @newprevunits = @invunits + @previnvunits, 
		@newprevamt = @invtotal + @prevamt, 
   		@newprevretg = @invretg + @previnvretg, 
		@newprevretgtax = @invretgtax + @previnvretgtax, 
		@newprevretgrel = @invrelretg + @previnvrelretg,
		@newprevretgtaxrel = @invrelretgtax + @previnvrelretgtax,
   		@newprevtax = @invtax + @previnvtax, 
		@newprevdue = @invdue + @previnvdue, 
   		@newprevwc = @wc + @prevwc, @newprevwcunits = @wcunits + @prevwcunits, 
   		@newprevsm = @sm + @prevsm, 
		@newprevsmretg = @smretg + @prevsmretg, 
   		@newprevwcretg = @wcretg + @prevwcretg 
   
   	/* Begin update only if Later bills exist with this Item having been billed */
	if exists (select 1
   		from bJBIT t with (nolock)
   		join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   		where t.JBCo = @co and t.Contract = @contract and n.InvStatus <> 'D'
   			and t.Item = @item 
   			and ((t.BillMonth > @billmth) or (t.BillMonth = @billmth and t.BillNumber > @billnum)))
   		begin
   
   		/* We will only spin through those Later Bills containing this Item. */
   		declare bcLaterBills cursor local fast_forward for
   		select t.BillMonth, t.BillNumber, t.UnitsBilled, t.AmtBilled, t.RetgBilled, t.RetgTax, t.RetgRel, t.RetgTaxRel,
			t.TaxAmount, t.AmountDue, t.WC, t.WCUnits, t.SM, t.SMRetg, t.WCRetg
   		from bJBIT t with (nolock)
   		join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   		where t.JBCo = @co and t.Contract = @contract and n.InvStatus <> 'D'
   			and t.Item = @item 
   			and ((t.BillMonth > @billmth) or (t.BillMonth = @billmth and t.BillNumber > @billnum))
   		order by t.BillMonth, t.BillNumber
   		
   		open bcLaterBills
   		select @opencursor2 = 1
   		
   		fetch next from bcLaterBills into @ltrbillmth, @ltrbillnum, @ltrinvunits, @ltrinvtotal, 
   			@ltrinvretg, @ltrinvretgtax, @ltrinvrelretg, @ltrinvrelretgtax, @ltrinvtax, @ltrinvdue, 
			@ltrwc, @ltrwcunits, @ltrsm, @ltrsmretg, @ltrwcretg
   		while @@fetch_status = 0
   			begin	/* Begin Bill Update Loop for one Item */
   			/* Update Bill Item Previous amounts. */
   			update bJBIT
   			set PrevUnits = @newprevunits, PrevAmt = @newprevamt, 
				PrevRetg = @newprevretg, PrevRetgTax = @newprevretgtax,
   				PrevRetgReleased = @newprevretgrel, PrevRetgTaxRel = @newprevretgtaxrel,
				PrevTax = @newprevtax, PrevDue = @newprevdue,
   				PrevWC = @newprevwc, PrevWCUnits = @newprevwcunits, PrevSM = @newprevsm,
   				PrevSMRetg = @newprevsmretg, PrevWCRetg = @newprevwcretg
   			where JBCo = @co and BillMonth = @ltrbillmth and BillNumber = @ltrbillnum
   				and Item = @item
   			if @@rowcount = 0 or @@error <> 0
   				begin
   				select @errmsg = 'Error updating:'
   				select @errmsg = @errmsg + char(13) + char(10)
   				select @errmsg = @errmsg + 'BillMonth = ' + convert(varchar(12), @ltrbillmth) 
   				select @errmsg = @errmsg + char(13)
   				select @errmsg = @errmsg + 'BillNumber = ' + convert(varchar(10), @ltrbillnum)
   				select @errmsg = @errmsg + char(13)
   				select @errmsg = @errmsg + 'Bill Item = ' + convert(varchar(20), @item)  
   				select @rcode = 1
   				/* Exit immediately and rollback. */
   				goto error
   				end
   		
   			/* Add updated bill's previous amounts to its own billed amounts in preparation for
   			   updating the next bills previous amounts.  Keep doing so until the most recent
   			   bill has been updated. */
   			select @newprevunits = @ltrinvunits + @newprevunits, @newprevamt = @ltrinvtotal + @newprevamt,
   				@newprevretg = @ltrinvretg + @newprevretg, @newprevretgtax = @ltrinvretgtax + @newprevretgtax, 
				@newprevretgrel = @ltrinvrelretg + @newprevretgrel, @newprevretgtaxrel = @ltrinvrelretgtax + @newprevretgtaxrel,
   				@newprevtax = @ltrinvtax + @newprevtax, @newprevdue = @ltrinvdue + @newprevdue, 
   				@newprevwc = @ltrwc + @newprevwc, @newprevwcunits = @ltrwcunits + @newprevwcunits, 
   				@newprevsm = @ltrsm + @newprevsm, @newprevsmretg = @ltrsmretg + @newprevsmretg, 
   				@newprevwcretg = @ltrwcretg + @newprevwcretg
   		
   			/* Ready to process the next Later Bill, having reset the previous amounts to include
   			   the preceeding bills billed amounts, the next bill in line containing this item
   			   will get the New Previous Amount values. */
   			fetch next from bcLaterBills into @ltrbillmth, @ltrbillnum, @ltrinvunits, @ltrinvtotal, 
   			@ltrinvretg, @ltrinvretgtax, @ltrinvrelretg, @ltrinvrelretgtax, @ltrinvtax, @ltrinvdue, 
			@ltrwc, @ltrwcunits, @ltrsm, @ltrsmretg, @ltrwcretg
   		
   			end		/* End Bill Update Loop for one Item */
   
		/* Close for now.  With open again with next Item */
		if @opencursor2 = 1
			begin
			close bcLaterBills
			deallocate bcLaterBills
			select @opencursor2 = 0
			end
   		end

NextItem:
   	/* Get Next Item on bill selected by user for Starting bill.  We have to do all Items.
   	   Remember this is not necessarily all Items on the contract.  It may be a limited 
   	   set of Items dictated by Item BillGroup. */
   	fetch next from bcThisBillItem into @item
   
   	end		/* End Item Loop */
   
/* Previous Amounts relative to this Bills JBIT Item record set have successfully been 
   updated on Later Bills. OK to Commit. */
Commit Transaction
   
if @opencursor1 = 1
   	begin
   	close bcThisBillItem
   	deallocate bcThisBillItem
   	select @opencursor1 = 0
   	end
if @opencursor2 = 1
   	begin
   	close bcLaterBills
   	deallocate bcLaterBills
   	select @opencursor2 = 0
   	end
   
error:	/* Update Prev Billed Amounts was run. @rcode = 0 or @rcode = 1 here. */
if @rcode = 1
   	begin
   	select @errmsg = 'Previous Billed values not updated - ' + isnull(@errmsg,'')
   	rollback Transaction
   
   	if @opencursor1 = 1
   		begin
   		close bcThisBillItem
   		deallocate bcThisBillItem
   		select @opencursor1 = 0
   		end
   	if @opencursor2 = 1
   		begin
   		close bcLaterBills
   		deallocate bcLaterBills
   		select @opencursor2 = 0
   		end
   	end
   
return @rcode	/* Normal update Prev Billed Operation. error2 and errorinitial are ignored. */
   
error2:		/* Update Prev ChgOrder operation failed. Update Prev Billed was skipped altogether. */
if @rcode = 1
   	begin
   	return @rcode	/* Correct @errmsg has already been established.  errorinitial is ignored. */
   	end
   	
errorinitial:	/* Initial error encountered.  Both Update Prev processes were skipped altogether. */
if @rcode = 1
   	begin
   	select @errmsg = 'Previous Billed values not updated - ' + isnull(@errmsg,'')
   	return @rcode
   	end

GO
GRANT EXECUTE ON  [dbo].[bspJBUpdatePrevValues] TO [public]
GO
