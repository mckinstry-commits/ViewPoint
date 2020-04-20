SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBUpdatePrevContractValues]
   /***********************************************************
   * CREATED BY: 	TJL - 01/05/04, Issue #21076, Update Current Contract, ContractUnits
   * MODIFIED By : 
   *
   *
   * USAGE:
   *	Users calls this from either JBT&MBill or JBProgBill, File Menu, to
   *	"Update Prev Amts, ChgOrder Adds/Deds" using the displayed bill as the starting point
   *	and updating all later bill's Contract Amount and Contract Units. This does not get
   *	called directly from the menu, rather it is called from bspJBUpdatePrevChgOrderValues
   *   (Which is called from bspJBUpdatePrevValues, which is call directly from the Menu option).
   *
   *	User may also allow this to update automatically when flag is set to do so in JBCO.
   *	In this case, the JBIS insert, update, delete triggers will call this routine anytime 
   *	JBIS.CurrContract or JBIS.ContractUnits get updated due to a change to a Change Order
   *	on a bill and the bill's 'InvStatus' is not 'D'.  
   *
   *
   * INPUT PARAMETERS
   *	@co				JB Company
   *	@billmth		Bill Month 
   *	@billnum		Bill Number 
   *	@invcustgroup	Passed in by bspJBUpdatePrevChgOrderValues when updating Manually
   *	@invcustomer	Passed in by bspJBUpdatePrevChgOrderValues when updating Manually
   *	@invcontract	Passed in by bspJBUpdatePrevChgOrderValues and btJBIS triggers
   *	@contractitem	Passed in by btJBIS triggers when JBCo 'Update Previous ...' flag is set to Automatic
   *	@ltrbillmth		Passed in by bspJBUpdatePrevChgOrderValues when updating Manually
   *	@ltrbillnum		Passed in by bspJBUpdatePrevChgOrderValues when updating Manually
   *	@updateprevYN	'Y' during Automatic, 'N' during Manual updates
   *   
   *
   * OUTPUT PARAMETERS
   *   @errmsg      error message if update fail.
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   @co bCompany, @billmth bMonth, @billnum int, @invcustgroup bGroup = null, @invcustomer bCustomer = null,
   	@invcontract bContract = null, @contractitem bContractItem, 
   	@ltrbillmth bMonth, @ltrbillnum int, @updateprevYN bYN = 'N',
   	@errmsg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int, @invstatus char(1), @openbillitemcursor int, @openltrbillcursor int,
   	@prevchgordunits bUnits, @currcontractunits bUnits, @billorigunits bUnits,
   	@prevchgordamt bDollar, @currcontractamt bDollar, @billorigamt bDollar
   
   select @rcode = 0, @openbillitemcursor = 0, @openltrbillcursor = 0
   
   /* MANUAL: Passed in @ltrbillnum (from bspJBUpdatePrevChgOrderValues), need only to cycle thru Contract Items. */
   if @ltrbillmth is not null and @ltrbillnum is not null and @contractitem is null and @updateprevYN = 'N'
   	begin	/* Begin Processing Contract Items Loop */
   	declare bcItems cursor local fast_forward for
   	select t.Item
   	from bJBIT t with (nolock)
   	where t.JBCo = @co and t.BillMonth = @ltrbillmth and t.BillNumber = @ltrbillnum
   	order by t.Item
   	
   	open bcItems
   	select @openbillitemcursor = 1
   
   	fetch next from bcItems into @contractitem
   	while @@fetch_status = 0
   		begin	/* Begin Item Loop this Later Bill */
   		/* Do not include this bill's change order amount in the Current Contract amount until the next bill.
   	   	   Conforms with AIA */
   	   	select  @prevchgordunits =isnull(sum(s.ChgOrderUnits),0), @prevchgordamt =isnull(sum(s.ChgOrderAmt),0)
   	   	from bJBIS s with (nolock)
   		join bJBIN n with (nolock) on s.JBCo = n.JBCo and s.BillMonth = n.BillMonth and  s.BillNumber = n.BillNumber
   	   	where  s.JBCo = @co and	((s.BillMonth < @ltrbillmth) or (s.BillMonth = @ltrbillmth and s.BillNumber < @ltrbillnum))
   			--and n.CustGroup = @invcustgroup and n.Customer = @invcustomer
   	    	and n.Contract = @invcontract and s.Item = @contractitem 
   			and n.InvStatus <> 'D'
   
   	   	select @billorigunits = BillOriginalUnits, @billorigamt = BillOriginalAmt
   	  	from bJCCI with (nolock)
   	   	where JCCo = @co and Contract = @invcontract and Item = @contractitem
   
   	   	select @currcontractunits = @billorigunits + @prevchgordunits,
   	    	@currcontractamt = @billorigamt + @prevchgordamt
   
   		/* Update bJBIT.CurrContract and bJBIT.ContractUnits, whos trigger will then update bJBIN.CurrContract
   		   on this Later Bill with new Contract Values. */
   		update bJBIT
   		set CurrContract = @currcontractamt, ContractUnits = @currcontractunits
   		where JBCo = @co and BillMonth = @ltrbillmth and BillNumber = @ltrbillnum and Item = @contractitem
   		if @@rowcount = 0 or @@error <> 0
   			begin
   			select @errmsg = 'Error updating:'
   			select @errmsg = @errmsg + char(13) + char(10)
   			select @errmsg = @errmsg + 'BillMonth = ' + convert(varchar(12), @ltrbillmth) 
   			select @errmsg = @errmsg + char(13)
   			select @errmsg = @errmsg + 'BillNumber = ' + convert(varchar(10), @ltrbillnum) + ': '
   			select @errmsg = @errmsg + 'Item = ' + convert(varchar(16), @contractitem)
   			select @rcode = 1
   			/* Exit immediately and rollback. */
   			goto error
   			end
   
   		/* Get Contract Item and Start the process over until All Items have been updated for
   		   this Later Bill. */
   		fetch next from bcItems into @contractitem
   		end 	/* End Item Loop this Later Bill */
   	end		/* End Processing Contract Items Loop */
   
   /* AUTOMATIC:  Passed in @contractitem from bJBIS triggers, need only to cycle thru Later Bills. */
   if @ltrbillmth is null and @ltrbillnum is null and @contractitem is not null and @updateprevYN = 'Y'
   	begin	/* Begin Processing Later Bills Loop */
   	/* Begin update only if Later bills exist with this Item having been billed */
    	if exists (select 1
   		from bJBIT t with (nolock)
   		join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   		where t.JBCo = @co and t.Contract = @invcontract and n.InvStatus <> 'D'
   			and t.Item = @contractitem 
   			and ((t.BillMonth > @billmth) or (t.BillMonth = @billmth and t.BillNumber > @billnum)))
   		begin	/* Begin Later Bills Loop */
   
   		/* We will only spin through those Later Bills containing this Item. */
   		declare bcLaterBills cursor local fast_forward for
   		select t.BillMonth, t.BillNumber 
   		from bJBIT t with (nolock)
   		join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   		where t.JBCo = @co and t.Contract = @invcontract and n.InvStatus <> 'D'
   			and t.Item = @contractitem 
   			and ((t.BillMonth > @billmth) or (t.BillMonth = @billmth and t.BillNumber > @billnum))
   		order by t.BillMonth, t.BillNumber
   		
   		open bcLaterBills
   		select @openltrbillcursor = 1
   		
   		fetch next from bcLaterBills into @ltrbillmth, @ltrbillnum
   		while @@fetch_status = 0
   			begin	/* Begin Bill Update Loop for one Item */
   
   			/* Do not include this bill's change order amount in the Current Contract amount until the next bill.
   		   	   Conforms with AIA */
   		   	select  @prevchgordunits = isnull(sum(s.ChgOrderUnits),0), @prevchgordamt =isnull(sum(s.ChgOrderAmt),0)
   		   	from bJBIS s with (nolock)
   			join bJBIN n with (nolock) on s.JBCo = n.JBCo and s.BillMonth = n.BillMonth and  s.BillNumber = n.BillNumber
   		   	where  s.JBCo = @co and	((s.BillMonth < @ltrbillmth) or (s.BillMonth = @ltrbillmth and s.BillNumber < @ltrbillnum))	--#24362:  s.BillNumber <= @ltrbillnum
   		    	and n.Contract = @invcontract and s.Item = @contractitem 
   				and InvStatus <> 'D'
   		
   		   	select @billorigunits = BillOriginalUnits, @billorigamt = BillOriginalAmt
   		  	from bJCCI with (nolock)
   		   	where JCCo = @co and Contract = @invcontract and Item = @contractitem
   		
   		   	select @currcontractunits = @billorigunits + @prevchgordunits,
   		    	@currcontractamt = @billorigamt + @prevchgordamt
   
   			/* Update bJBIT.CurrContract and bJBIT.ContractUnits, whos trigger will then update bJBIN.CurrContract
   			   on this Later Bill with new Contract Values. */
   			update bJBIT
   			set CurrContract = @currcontractamt, ContractUnits = @currcontractunits
   			where JBCo = @co and BillMonth = @ltrbillmth and BillNumber = @ltrbillnum and Item = @contractitem
   			if @@rowcount = 0 or @@error <> 0
   				begin
   				select @errmsg = 'Error updating:'
   				select @errmsg = @errmsg + char(13) + char(10)
   				select @errmsg = @errmsg + 'BillMonth = ' + convert(varchar(12), @ltrbillmth) 
   				select @errmsg = @errmsg + char(13)
   				select @errmsg = @errmsg + 'BillNumber = ' + convert(varchar(10), @ltrbillnum) + ': '
   				select @errmsg = @errmsg + 'Item = ' + convert(varchar(16), @contractitem)
   				select @rcode = 1
   				/* Exit immediately and rollback. */
   				goto error
   				end
   
   			/* Get next Later Bill and Start the process over until All Later bills have been updated for
   			   Contract Item. */
   			fetch next from bcLaterBills into @ltrbillmth, @ltrbillnum
   
   			end		/* End Bill Update Loop for one Item */
   		end		/* End  Later Bills Loop */
   	end		/* End Processing Later Bills Loop */
   
   if @openltrbillcursor = 1
   	begin
   	close bcLaterBills
   	deallocate bcLaterBills
   	select @openltrbillcursor = 0
   	end
   
   if @openbillitemcursor = 1
   	begin
   	close bcItems
   	deallocate bcItems
   	select @openbillitemcursor = 0
   	end
   
   error:
   if @rcode = 1
   	begin
   	select @errmsg = 'Contract values have not been updated - ' + isnull(@errmsg,'')
   
   	if @openltrbillcursor = 1
   		begin
   		close bcLaterBills
   		deallocate bcLaterBills
   		select @openltrbillcursor = 0
   		end
   
   	if @openbillitemcursor = 1
   		begin
   		close bcItems
   		deallocate bcItems
   		select @openbillitemcursor = 0
   		end
   
   	end
   
   return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBUpdatePrevContractValues] TO [public]
GO
