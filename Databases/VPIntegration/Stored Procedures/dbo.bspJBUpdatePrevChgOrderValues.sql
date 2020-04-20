SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBUpdatePrevChgOrderValues]
   /******************************************************************************
   * CREATED BY: 	TJL 12/16/03 - Issue #21076, Update Previous ChgOrderAdds/Deds
   * MODIFIED By : TJL 07/30/04 - Issue #25260, Update ChgOrderAdds/Deds by BillGroup
   *		TJL 08/27/04 - Issue #25434, Add isnull() relative to BillGroup
   *		TJL 08/30/04 - Issue #25431, Accumulate Adds/Deds by BillGroup not by Item
   *		TJL 09/20/04 - Issue #25399, Fix 25431 above. Accumulate Adds/Deds relative to 
   *						the current Bills Items only. (Not by JBIN BillGroup only)
   *		TJL 01/26/05 - Issue #26941, Related to #21076.  Fix PrevChgOrderAdds/PrevChgOrderDeds doubling in value 
   *
   *
   * USAGE:
   *	Users calls this from either JBT&MBill or JBProgBill, File Menu, to
   *	"Update Prev Amts, ChgOrder Adds/Deds" using the displayed bill as the starting point
   *	and updating all later bill's Change Order Adds/Deds that are associated with the 
   *	displayed bill.  This does not get called directly from the menu, rather it
   *   is called from bspJBUpdatePrevValues (Which is call directly from the Menu option).
   *
   *	User may also allow this to update automatically when flag is set to do so in JBCO.
   *	In this case, the JBIN update trigger will call this routine anytime that the 
   *	'ChgOrderAmt' gets updated on a bill and the bill's 'InvStatus' is not 'D'.  Also
   *	this will get invoked by JBIN delete trigger when a single bill gets physically
   *	deleted from JB Prog Bill Header form.
   *
   * INPUT PARAMETERS
   *	@co				JB Company
   *	@billmth		Bill Month 
   *	@billnum		Bill Number 
   *	@invcustgroup	Passed in by btJBINu when JBCo 'Update Previous ...' flag is set
   *	@invcustomer	Passed in by btJBINu when JBCo 'Update Previous ...' flag is set
   *	@invcontract	Passed in by btJBINu when JBCo 'Update Previous ...' flag is set
   *	@invchgorderamt	Passed in by btJBINu when JBCo 'Update Previous ...' flag is set
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
   	@invcontract bContract = null, @invchgorderamt bDollar = null, @billgroup bBillingGroup,
   	@errmsg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int, @invstatus char(1), @opencursor1 int,
   	@openPrevBillcursor int, @openPrevACOcursor int,									
   	@prevchgorderadds bDollar, @prevchgorderdeds bDollar, @prevchgorderamt bDollar,	
   	@prevbillmth bMonth, @prevbillnumber int, @prevaco bACO,						
   	@ltrbillmth bMonth, @ltrbillnum int, @ltrbillbillgrp bBillingGroup, @updateprevYN bYN
   
   select @rcode = 0, @opencursor1 = 0, @openPrevBillcursor = 0, @openPrevACOcursor = 0
   
   /* Determine if this is an Automatic update or a Manual update. */
   select @updateprevYN = PrevUpdateYN
   from bJBCO with (nolock)
   where JBCo = @co
   
   /* Decided to let this update complete or rollback on error before allowing further changes 
      to existing bills. */
   Begin Transaction
   
   /* If this procedure has been called, manually from the 'File' menu option, then we
      need to retrieve the selected bill's required values. */
   if @invcustgroup is null and @invcustomer is null and @invcontract is null and @invchgorderamt is null
   	begin
   	select @invstatus = InvStatus, @invcustgroup = CustGroup, @invcustomer = Customer,
   		@invcontract = Contract, @invchgorderamt = isnull(ChgOrderAmt,0),
   		@billgroup = BillGroup
   	from bJBIN with (nolock)
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   	end
   
   /* Begin update PrevChgOrderAdds/Deds and CurrentContractAmt on later bills. */
   if exists (select 1
   	from bJBIN n with (nolock)
   	where n.JBCo = @co 	--and n.CustGroup = @invcustgroup and n.Customer = @invcustomer 
   		and n.Contract = @invcontract and n.InvStatus <> 'D'
   		and ((n.BillMonth > @billmth) or (n.BillMonth = @billmth and n.BillNumber > @billnum)))
   
   	begin
   	/* We will spin through only Later Bills. */
   	declare bcLaterBills cursor local fast_forward for
   	select n.BillMonth, n.BillNumber, n.BillGroup		--Keep n.BillGroup here for future
   	from bJBIN n with (nolock)
   	where n.JBCo = @co --and n.CustGroup = @invcustgroup and n.Customer = @invcustomer  
   		and n.Contract = @invcontract and n.InvStatus <> 'D'
   		and ((n.BillMonth > @billmth) or (n.BillMonth = @billmth and n.BillNumber > @billnum))
   	order by n.BillMonth, n.BillNumber
   	
   	open bcLaterBills
   	select @opencursor1 = 1
   	
   	fetch next from bcLaterBills into @ltrbillmth, @ltrbillnum, @ltrbillbillgrp
   	while @@fetch_status = 0
   		begin	/* Begin Bill Update Loop. */
   		select @prevchgorderadds = 0, @prevchgorderdeds = 0, @prevchgorderamt = 0	
   
   		/* Update PrevChgOrderAdds and PrevChgOrderDeds for bills later than this one.
   		   For each Later Bill, retrieve a list of earlier Bills to accumulate totals from. This may not
   		   be the fasted way to accomplish this (If this bill is old and many later bills exist) but it is 
   		   accurate and consistent with the btJBINi trigger doing the same thing upon bill creation. */
   		declare bcPrevJBIN cursor local fast_forward for
   		select BillMonth, BillNumber
   		from bJBIN with (nolock)
   		where JBCo = @co and Contract = @invcontract 
   			and ((BillMonth < @ltrbillmth) or (BillMonth = @ltrbillmth and BillNumber < @ltrbillnum))
   			and InvStatus <> 'D'
   		order by BillMonth, BillNumber
   		
   		open bcPrevJBIN
   		select @openPrevBillcursor = 1
   		
   		fetch next from bcPrevJBIN into @prevbillmth, @prevbillnumber
   		while @@fetch_status = 0
   			begin	/* Begin Previous Bill Loop for this Later Bill */
   			declare bcPrevACO cursor local fast_forward for
   		 	select distinct(ACO)
   		 	from bJBCC with (nolock)
   		 	where JBCo = @co and BillMonth = @prevbillmth and BillNumber = @prevbillnumber
   			order by ACO
   		
   			open bcPrevACO
   			select @openPrevACOcursor = 1
   			
   			fetch next from bcPrevACO into @prevaco
   			while @@fetch_status = 0
   				begin	
   		 		select @prevchgorderamt = isnull(sum(ChgOrderAmt),0)
   				from bJBCX x with (nolock)
   				join bJCOI i with (nolock) on i.JCCo = x.JBCo and i.Job = x.Job and i.ACO = x.ACO and i.ACOItem = x.ACOItem
   				-- join JBIT for current bill (NOT prev bills) to accumulate totals relative to only those Items on this bill.  
   				join bJBIT t with (nolock) on t.JBCo = @co and t.BillMonth = @ltrbillmth and t.BillNumber = @ltrbillnum and t.Item = i.Item
   				where x.JBCo = @co and x.BillMonth = @prevbillmth and x.BillNumber = @prevbillnumber and x.ACO = @prevaco
   				if @prevchgorderamt > 0 select @prevchgorderadds = @prevchgorderadds + @prevchgorderamt
   				if @prevchgorderamt < 0 select @prevchgorderdeds = @prevchgorderdeds + @prevchgorderamt
   		
   				fetch next from bcPrevACO into @prevaco
   				end
   			
   			if @openPrevACOcursor = 1
   				begin
   				close bcPrevACO
   				deallocate bcPrevACO
   				select @openPrevACOcursor = 0
   				end
   		
   			fetch next from bcPrevJBIN into @prevbillmth, @prevbillnumber
   			end		/* End Previous Bill Loop for this Later Bill */
   
   		/* We now have PrevChgOrderAdds/Deds totals relative to this one Later Bill. Time to Update */
   		if @openPrevBillcursor = 1
   			begin
   			close bcPrevJBIN
   			deallocate bcPrevJBIN
   			select @openPrevBillcursor = 0
   			end
   
   		/* Update bJBIN Bill PrevChgOrderAdds/Deds values for this Later Bill. */
   		update bJBIN
   		set PrevChgOrderAdds = @prevchgorderadds, PrevChgOrderDeds = @prevchgorderdeds
   		where JBCo = @co and BillMonth = @ltrbillmth and BillNumber = @ltrbillnum
   		if @@rowcount = 0 or @@error <> 0
   			begin
   			select @errmsg = 'Error updating:'
   			select @errmsg = @errmsg + char(13) + char(10)
   			select @errmsg = @errmsg + 'BillMonth = ' + convert(varchar(12), @ltrbillmth) 
   			select @errmsg = @errmsg + char(13)
   			select @errmsg = @errmsg + 'BillNumber = ' + convert(varchar(10), @ltrbillnum)
   			select @rcode = 1
   			/* Exit immediately and rollback. */
   			goto error
   			end
   
   		/* Update Current Contract amounts on Later Bills. Again Later Bills may contain same Items
   		   even when the Later Bill is not using the same BillGroup  (ie: Null BillGroup on Bill creation)
   		   Therefore we must look at all Later Bills. */
   		if @updateprevYN = 'N'
   			begin
   			exec @rcode = bspJBUpdatePrevContractValues @co, @billmth, @billnum, @invcustgroup, @invcustomer,
   				@invcontract, null, @ltrbillmth, @ltrbillnum, @updateprevYN, @errmsg output
   			if @rcode = 1 goto error
   			end
   
   		/* Ready to process the next Later Bill. */
   		fetch next from bcLaterBills into @ltrbillmth, @ltrbillnum, @ltrbillbillgrp
   		
   		end		/* End Bill Update Loop */
   
   	if @opencursor1 = 1
   		begin
   		close bcLaterBills
   		deallocate bcLaterBills
   		select @opencursor1 = 0
   		end
   	end
   
   /* PrevChgOrder values relative to this Bill have successfully been updated on Later Bills. OK to Commit. */
   Commit Transaction
   
   if @opencursor1 = 1
   	begin
   	close bcLaterBills
   	deallocate bcLaterBills
   	select @opencursor1 = 0
   	end
   if @openPrevBillcursor = 1
   	begin
   	close bcPrevJBIN
   	deallocate bcPrevJBIN
   	select @openPrevBillcursor = 0
   	end
   if @openPrevACOcursor = 1
   	begin
   	close bcPrevACO
   	deallocate bcPrevACO
   	select @openPrevACOcursor = 0
   	end
   
   error:
   if @rcode = 1
   	begin
   	select @errmsg = 'PrevChgOrder values have not been updated - ' + isnull(@errmsg,'')
   	rollback Transaction
   
   	if @opencursor1 = 1
   		begin
   		close bcLaterBills
   		deallocate bcLaterBills
   		select @opencursor1 = 0
   		end
   	if @openPrevBillcursor = 1
   		begin
   		close bcPrevJBIN
   		deallocate bcPrevJBIN
   		select @openPrevBillcursor = 0
   		end
   	if @openPrevACOcursor = 1
   		begin
   		close bcPrevACO
   		deallocate bcPrevACO
   		select @openPrevACOcursor = 0
   		end
   	end
   
   return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBUpdatePrevChgOrderValues] TO [public]
GO
