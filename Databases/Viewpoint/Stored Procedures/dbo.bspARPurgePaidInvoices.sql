SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARPurgePaidInvoices    Script Date: 8/28/99 9:34:14 AM ******/
CREATE  proc [dbo].[bspARPurgePaidInvoices]
/******************************************************
* CREATED: CJW 09/10/97
* MODIFIED: bc  08/26/99
*			GR  01/17/00 - corrected the where clause to get all the months less than or equal to through month
*                             		- corrected to LastMthSubClsd instead of LastMthGlClsd, corrected some more checks
*			TJL  08/29/01 - Issue #13931
*				Corrected improper Contract Comparison, that resulted in no Transactions being returned to delete.  Now they are Returned!
*				Corrected to utilize JCCo when deleting Contract Invoices.  Previously it was not even considered.
*				Also modified to use the ARCM.SelPurge flag correctly and other minor adjustments.
*				Added the option to remove Inactive Customers.
*				Added rollback feature on error.
*				Added code to delete 'On Account' Payments.
*				Added code to correctly update bARTL 'PurgeFlag' field to avoid updating bARMT upon purge.
*				Added code to update bARTH 'EditTrans' flag on Payment transaction for invoices being deleted.
*			TJL  08/30/01 - Issue #13931and related to Issue #13942
*				Added the option to remove Temporary Customers here, ARPURGEPAIDINV, rather than from  ARPURGEMISC 
*			TJL  10/19/01 - Issue #14984, Remove redundent/inefficient temporary table #PaymentLines and replace with cursor.
*			TJL  11/27/01 - Issue #14984 Rejection, Check JCCM before deleting Temporary or Inactive Customer.
*			TJL  07/21/04 - Issue #25098, Through Month must include Payment (Applied transactions), add NoLocks, remove psuedos
*			TJL  03/22/05 - Issue #27271, Correct problem purging inactive customers
*			GG 02/25/08 - #120107 - separate sub ledger close - use AR close month
*				
*
* USAGE:
*
*
* INPUT PARAMETERS
*   ARCo
*   Purge through month
*   begin customer
*   end customer
*   begin contract
*   end contract
*   exclude contracts from being purged.   if 'Y' then only purge invoices that do not have contracts on them.
*                                          		if 'N', purge contracts within the range.
*   Purge Temp Customers.	if 'Y' then purge those Temporary customers who have no transactions remaining after
*					purging invoice/transactions up to and including through date.  This includes:
*					a)  Remove all monthly total transactions for this temporary customer from ARMT.
*					b)  If this customer is NOT shared with other companies, then remove customer from ARCM.
*  Purge InactiveCustomers	Works same as for Temp Customers above.
*
* OUTPUT PARAMETERS
*   @invdeleted		Number of Invoices deleted
*   @errmsg
*
* RETURN VALUE
*   returns - not sure yet
*
*****************************************************/
   
   (@arco bCompany=null, @ThroughMth bMonth=null,  @BeginningCustomer bCustomer = null, @EndingCustomer bCustomer = null,
    @jcco bCompany=null, @BeginningContract bContract = null, @EndingContract bContract = null, @excontracts bYN = null, 
    @deletetmpcust bYN, @deleteinactivecust bYN, @invdeleted int output, @errmsg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @Mth bMonth, @ARTrans bTrans, @CustGroup bGroup, @Customer bCustomer, @ARLine smallint, @ApplyMth bMonth,
   	@CustContFlag int, @sum int, @MaxApplyMth bMonth, @MaxMth bMonth, @LastClosedMth bMonth, @TempCo bCompany,
   	@InactiveCo bCompany, @MultCompanyFlag int, @recnum int, @topurge int, @topurge2 int, @deleted int, @deleted2 int,
   	@delPsopencursor tinyint, @partrans bTrans, @pmth bMonth, @pcount int, @delheaderPs tinyint,
   	@invopencursor tinyint, @onacctopencursor tinyint, @custopencursor tinyint
   
   if @arco is null
   	begin
   	select @rcode = 1, @errmsg='AR Company is missing.'
   	goto error
   	end
   if @ThroughMth is null
   	begin
   	select @rcode = 1, @errmsg='AR Month is missing.'
   	goto error
   	end
   
   /* Get last closed mth from GLCo, CustGroup from HQCo. */
   select @LastClosedMth = g.LastMthARClsd, @CustGroup = h.CustGroup -- #120107 use AR close month
   from bARCO a with (nolock)
   join bGLCO g with (nolock) on g.GLCo = a.GLCo
   join bHQCO h with (nolock) on h.HQCo = a.ARCo 
   where a.ARCo = @arco
   if @ThroughMth > @LastClosedMth
   	begin
   	select @rcode = 1, @errmsg = 'Purge Through Month must be Closed.'
   	goto error
   	end
   
   select @rcode = 0, @invdeleted = 0, @MultCompanyFlag = 0, @recnum = 0, @topurge = 0, @topurge2 = 0, 
   	@deleted = 0, @deleted2 = 0, @delPsopencursor = 0, @invopencursor = 0, @onacctopencursor = 0,
   	@custopencursor = 0
   
   if @excontracts is null select @excontracts = 'N'
   
   /* Paid Invoice Purge */
   if @excontracts = 'N'
   	Begin	/* Begin get ALL invoice list */
   	declare bcinv cursor local fast_forward for
     	select h.Mth, h.ARTrans
   	from bARTH h with (nolock)
   	join bARCM m with (nolock) on h.CustGroup = m.CustGroup and h.Customer = m.Customer
   	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.ApplyMth = h.Mth and l.ApplyTrans = h.ARTrans
   	where h.ARCo = @arco
   		-- If Beginning and Ending Customer are the same and NOT NULL, then ignore ARCM.SelPurge flag 
   		and m.SelPurge = case when (isnull(@BeginningCustomer,-1) = isnull(@EndingCustomer,1999999999) and isnull(@BeginningCustomer,-1) <> -1)
   			then m.SelPurge else 'N' end
   		and m.StmtType = 'O'
   		and h.ARTransType in ('I','F','R')
   		and h.Mth = isnull(h.AppliedMth, '2079-06-06') and h.ARTrans = isnull(h.AppliedTrans, 0)	--Orig Trans only
   		and h.Customer >= isnull(@BeginningCustomer,-1)					--Customer Range 
   		and h.Customer <= isnull(@EndingCustomer,1999999999)
   		and isnull(h.Contract, '') >= isnull(@BeginningContract,'')		--Contract Range
   		and isnull(h.Contract, '') <= isnull(@EndingContract,'~')
   		and isnull(h.JCCo, 0) = case when isnull(@jcco, 0) = 0 then isnull(h.JCCo, 0) else @jcco end
   			and h.Mth <= @ThroughMth						--Up to and including this Through Mth	
   	group by h.Mth, h.ARTrans								--Create Distinct List of Orig Transactions, elimate effect of ARTL JOIN
   	having max(l.Mth) <= @ThroughMth and sum(l.Amount) = 0	--Orig Transaction's applied transactions must not exceed thru date or sum > 0												
   	order by h.Mth, h.ARTrans
   	End
   Else
    	Begin	/* Begin get Non-Contract invoice list */
   	declare bcinv cursor local fast_forward for
   	select h.Mth, h.ARTrans
   	from bARTH h with (nolock)
   	join bARCM m with (nolock) on h.CustGroup = m.CustGroup and h.Customer = m.Customer
   	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.ApplyMth = h.Mth and l.ApplyTrans = h.ARTrans
   	where h.ARCo = @arco
   		-- If Beginning and Ending Customer are the same and NOT NULL, then ignore ARCM.SelPurge flag 
   		and m.SelPurge = case when (isnull(@BeginningCustomer,-1) = isnull(@EndingCustomer,1999999999) and isnull(@BeginningCustomer,-1) <> -1)
   			then m.SelPurge else 'N' end
   		and m.StmtType = 'O'
   		and h.ARTransType in ('I','F','R')
   		and h.Mth = isnull(h.AppliedMth, '2079-06-06') and h.ARTrans = isnull(h.AppliedTrans, 0)	--Orig Trans only
   		and h.Customer >= isnull(@BeginningCustomer,-1)					--Customer Range
   		and h.Customer <= isnull(@EndingCustomer,1999999999)
   		and h.Contract is null											--Non-Contract
   			and h.Mth <= @ThroughMth						--Up to and including this Through Mth
   	group by h.Mth, h.ARTrans								--Create Distinct List of Orig Transactions, elimate effect of ARTL JOIN
   	having max(l.Mth) <= @ThroughMth and sum(l.Amount) = 0	--Orig Transaction's applied transactions must not exceed thru date	or sum > 0											
   	order by h.Mth, h.ARTrans
   	End	
   
   open bcinv
   select @invopencursor = 1
   
   fetch next from bcinv into @Mth, @ARTrans
   while @@fetch_status = 0
    	/* Spin through Transaction list */
   	begin
   	select @topurge = 0, @topurge2 = 0, @deleted = 0, @deleted2 = 0
   
   	/* Get count of Lines to be removed for this transaction */
   	select @topurge = count(*)
   	from bARTL l with (nolock)
   	where l.ARCo = @arco and l.ApplyMth = @Mth and l.ApplyTrans = @ARTrans
   
   	begin transaction
   	/* Set PurgeFlag.  Triggers should not update anything as a result of purging. */
   	update bARTH
   	set PurgeFlag = 'Y'
   	where ARCo = @arco and Mth = @Mth and ARTrans = @ARTrans
   
   	update bARTL
   	set PurgeFlag = 'Y'
   	where ARCo = @arco and ApplyMth = @Mth and ApplyTrans = @ARTrans 
   
   	/*  Set EditTrans flag on ALL Payment transactions or Release Retainage transactions relative to this Invoice transaction.
   	    Remember, multiple invoices may be paid or released in the same batch seq therefore containing the same ARTrans.
   	    We do not want a customer allowed to change a Payment or Release Retainage transaction that one or more invoices 
   	    have been deleted from. */
   	update bARTH 
   	set bARTH.EditTrans = 'N'
   	from bARTH h with (nolock)
   	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
   	where l.ARCo = @arco and l.ApplyMth = @Mth and l.ApplyTrans = @ARTrans 
   		and h.ARTransType in ('P', 'R')
   
   	/* Payment Header Evaluation/Delete Process:
   	   Before deleting this ARTrans lets find all related Payment lines for use later during the delete process. 
   	   STATIC is required to maintain the original list even after deleting individual transations and lines. */
   	declare bcDelHeaderPmt cursor STATIC for
   	select distinct h.Mth, h.ARTrans 
   	from bARTH h with (nolock)
   	join bARTL l with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
   	Where l.ARCo = @arco and l.ApplyMth = @Mth and l.ApplyTrans = @ARTrans
   		and isnull(h.Mth, '2079-06-06') <> isnull(h.AppliedMth, '2079-06-06')
   		and isnull(h.ARTrans, 0) <> isnull(h.AppliedTrans, 0)
   		and h.ARTransType in ('P', 'R')
   	order by h.Mth, h.ARTrans
   
   	select @delheaderPs = 0
   	open bcDelHeaderPmt
   	select @delPsopencursor = 1
   		
   	/* Delete all transactions lines that apply to this transaction */
   	delete bARTL 
   	where ARCo = @arco and ApplyMth = @Mth and ApplyTrans = @ARTrans
   	select @deleted = @@rowcount
   
   	/* Get count of Headers to be removed for this transaction */
   	select @topurge2 = count(*)
   	from bARTH with (nolock)
   	where ARCo = @arco and Mth = @Mth and ARTrans = @ARTrans
   
   	/*  This delete will remove header entries for original 'I', 'F', and 'R' Invoices as well as header records
   	    representing 'F', 'A', 'C', 'W' ARTransTypes that were applied to the original Invoices referred to above. 
   	    It will NOT remove 'P' or 'R records representing lines applied to an original Invoice since this single
   	    header 'P' or 'R' entry may represent lines applied to multiple invoices at once.  These 'P' and 'R' header
   	    entries will get removed next. */
   	delete bARTH 
   	where ARCo = @arco and Mth = @Mth and ARTrans = @ARTrans
   	select @deleted2 = @@rowcount
   
   	/* Delete Payment or Release Retainage transactions from bARTH only if no lines still exists that are still associated with it.
   	   Another words delete a 'P' or 'R' Header records only if all associated invoices have been purged. */
   	fetch next from bcDelHeaderPmt into @pmth, @partrans 
   	while @@fetch_status = 0
   		begin
   		/* Look for remaining lines for the Payment/Retainage Header */
   		select @pcount = count(*) 
   		from bARTL l with (nolock)
   		where l.ARCo = @arco and l.Mth = @pmth and l.ARTrans = @partrans
   
   		if @pcount = 0
   			/* All related invoices have been removed.  Go ahead and remove Payment/Retainage header */	
   			begin
   			update bARTH
   			set PurgeFlag = 'Y'
   			where ARCo = @arco and Mth = @pmth and ARTrans = @partrans and ARTransType in ('P', 'R')
   
   			delete bARTH
   			where ARCo = @arco and Mth = @pmth and ARTrans = @partrans and ARTransType in ('P', 'R')
   			if @@rowcount <> 1		-- If this fails, we now have a header record without detail
   				begin
   				select @delheaderPs = 1
   				end
   			end
   
   		fetch next from bcDelHeaderPmt into @pmth, @partrans 
   		end
   
  
   	if @delPsopencursor = 1
   		begin
   		close bcDelHeaderPmt
   		deallocate bcDelHeaderPmt
   		select @delPsopencursor = 0
   		end
   
   	/* We have deleted this Invoice/Detail as well as Payment/Retainage Headers if possible.
   	   Do one final check to see if something has failed and a rollback is required. */
   	if (@topurge <> @deleted) or (@topurge2 <> @deleted2) or (@delheaderPs <> 0)
   		begin
   		rollback transaction
   		select @errmsg = 'An error has occurred! Transaction #' + isnull(convert(varchar(10), @ARTrans),'') + ':	Month,	' + isnull(convert(varchar(12),@Mth),'') 
   		select @errmsg = @errmsg + ':  Correct Invoice and begin again.'
   		select @rcode = 1
   		goto error
   		end				
   
   	commit transaction
   	select @invdeleted = @invdeleted + 1
   
   getNextTrans:
   	fetch next from bcinv into @Mth, @ARTrans
   	end		/* End Spin through Transaction list */
   
   if @invopencursor = 1
   	begin
   	close bcinv
   	deallocate bcinv
   	select @invopencursor = 0
   	end
   
   /* ABOUT 'On Account' payments:  Most customers should be APPLYING a reversing payment to 'On Account' payments at the
       cash receipts grid just like any other invoice, before applying the payment to the actual invoice (Thus creating a transaction applied
       to the original 'On Account' transaction).  If done correctly, then purging paid invoices will remove these 'On Account' payments as well.  
       On the other hand, if a user incorrectly reverses the 'On Account' payment by going into the 'On Account' form, then a separate transaction
       gets generated.  Though the Acct will balance to 0.00, it has been decided that this is incorrect procedure and therefore these seemingly
       independent transactions will NOT be purged. Instead, user will need to acknowledge these transactions, then apply reversing entries
       to each and then purge again. */
   
   /* Payment on Account Purge */
   declare bconacct cursor local fast_forward for
   select h.Mth, h.ARTrans
   from bARTH h with (nolock)
   join bARCM m with (nolock) on h.CustGroup = m.CustGroup and h.Customer = m.Customer
   join bARTL l with (nolock) on l.ARCo = h.ARCo and l.ApplyMth = h.Mth and l.ApplyTrans = h.ARTrans
   where h.ARCo = @arco
   	-- If Beginning and Ending Customer are the same and NOT NULL, then ignore ARCM.SelPurge flag 
   	and m.SelPurge = case when (isnull(@BeginningCustomer,-1) = isnull(@EndingCustomer,1999999999) and isnull(@BeginningCustomer,-1) <> -1)
   		then m.SelPurge else 'N' end
   	and m.StmtType = 'O'
   	and h.ARTransType in ('P')			-- Only Payment on Account applied Transactions. Both original and applied
   	and h.Customer >= isnull(@BeginningCustomer,-1)					-- Customer Range 
   	and h.Customer <= isnull(@EndingCustomer,1999999999)
   	and isnull(h.Contract, '') >= isnull(@BeginningContract,'')		-- NA - Contract Range 
   	and isnull(h.Contract, '') <= isnull(@EndingContract,'~')
   	and isnull(h.JCCo, 0) = case when isnull(@jcco, 0) = 0 then isnull(h.JCCo, 0) else @jcco end
   	and h.Mth <= @ThroughMth								--Up to and including this Through Mth
   group by h.Mth, h.ARTrans									--Create Distinct List of Orig Payment Transactions, elimate effect of ARTL JOIN		
   having max(l.Mth) <= @ThroughMth and sum(l.Amount) = 0		--Orig Payment Transaction's applied transactions must not exceed thru date or sum > 0
   order by h.Mth, h.ARTrans
   
   open bconacct
   select @onacctopencursor = 1
   
   fetch next from bconacct into @Mth, @ARTrans
   while @@fetch_status = 0
   	/* Spin through 'On Account' Transactions list */
   	begin		
   	select @topurge = 0, @topurge2 = 0, @deleted = 0, @deleted2 = 0
   
   	/* Get count of Lines to be removed for this transaction */
   	select @topurge = count(*)
   	from bARTL l with (nolock)
   	where l.ARCo = @arco and l.ApplyMth = @Mth and l.ApplyTrans = @ARTrans
   
   	begin transaction
   	/* Set PurgeFlag.  Triggers should not update anything as a result of purging. 
   	   Not required here.  The header potentially being deleted is a Payment header.
   	   It will be Updated/Deleted during the Payment header evaluation process later. */
   	--update bARTH
   	--set PurgeFlag = 'Y'
   	--where ARCo = @arco and Mth = @Mth and ARTrans = @ARTrans
   
   	update bARTL
   	set PurgeFlag = 'Y'
   	where ARCo = @arco and ApplyMth = @Mth and ApplyTrans = @ARTrans 
   
   	/*  Set EditTrans flag on ALL Payment transactions relative to this transaction.
   	    Remember, Zeroing an Account Payment usually is accompanied by applying that same money to an invoice
   	    in the same batch seq therefore containing the same ARTrans for both.  We do not want a customer allowed 
   	    to change a Payment transaction that an 'On Account' Payment has been deleted from. */
   	update bARTH 
   	set bARTH.EditTrans = 'N'
   	from bARTH h with (nolock)
   	join bARTL l with (nolock) on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
   	where l.ARCo = @arco and l.ApplyMth = @Mth and l.ApplyTrans = @ARTrans 
   		and h.ARTransType in ('P')
   
   	/* Payment Header Evaluation/Delete Process:  (Unlike during Invoice purge, the original Payment On Account
   	   transaction will be part of this list and therefore does not have to be deleted separately. )
   	   Before deleting this ARTrans lets find all related Payment lines for use later during the delete process. 
   	   STATIC is required to maintain the original list even after deleting individual transations and lines. */
   	declare bcDelHeaderPmt cursor STATIC for
   	select distinct h.Mth, h.ARTrans 
   	from bARTH h with (nolock)
   	join bARTL l with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
   	where l.ARCo = @arco and l.ApplyMth = @Mth and l.ApplyTrans = @ARTrans
   		and isnull(h.Mth, '2079-06-06') <> isnull(h.AppliedMth, '2079-06-06')
   		and isnull(h.ARTrans, 0) <> isnull(h.AppliedTrans, 0)
   		and h.ARTransType in ('P')
   	order by h.Mth, h.ARTrans
   
   	select @delheaderPs = 0
   	open bcDelHeaderPmt
   	select @delPsopencursor = 1
   
   	/* Delete all payment transactions lines that apply against this payment On Account transaction */
   	delete bARTL 
   	where ARCo = @arco and ApplyMth = @Mth and ApplyTrans = @ARTrans
   	select @deleted = @@rowcount
   
   	/* Not required.  Unlike when deleting Invoices, this transaction header will show up in the
   	   bcDelHeaderPmt cursor list that follows and will be deleted at that time. */
   -- 	if not exists(select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @Mth
   -- 				and ARTrans = @ARTrans)
   -- 		begin
   -- 		select @topurge2 = count(*)
   -- 		from bARTH with (nolock)
   -- 		where ARCo = @arco and Mth = @Mth and ARTrans = @ARTrans
   -- 
   -- 		delete bARTH 
   -- 		where ARCo = @arco and Mth = @Mth and ARTrans = @ARTrans
   -- 		select @deleted2 = @@rowcount
   -- 		end
   
   	/* Delete Payment transactions from bARTH only if no lines still exists that are still associated with it.
   	   Another words delete a 'P' Header record only if all associated invoices/account transactions have been purged. */
   	fetch next from bcDelHeaderPmt into @pmth, @partrans 
   	while @@fetch_status = 0
   		begin
   		select @pcount = count(*) 
   		from bARTL l
   		where l.ARCo = @arco and l.Mth = @pmth and l.ARTrans = @partrans
   
   		if @pcount = 0
   			begin
   			update bARTH
   			set PurgeFlag = 'Y'
   			where ARCo = @arco and Mth = @pmth and ARTrans = @partrans and ARTransType in ('P')
   
   			delete bARTH
   			where ARCo = @arco and Mth = @pmth and ARTrans = @partrans and ARTransType in ('P')
   			if @@rowcount <> 1		-- Now we have a header record without detail
   				begin
   				select @delheaderPs = 1
   				end
   			end
   
   		fetch next from bcDelHeaderPmt into @pmth, @partrans 
   		end
   
   	if @delPsopencursor = 1
   		begin
   		close bcDelHeaderPmt
   		deallocate bcDelHeaderPmt
   		select @delPsopencursor = 0
   		end
   
   	/* Check to see if something has failed and a rollback is required. */
   	if @topurge <> @deleted or @delheaderPs <> 0
   		begin
   		rollback transaction
   		select @errmsg = 'An error has occurred! Transaction #' + isnull(convert(varchar(10), @ARTrans),'') + ':	Month,	' + isnull(convert(varchar(12),@Mth),'') 
   		select @errmsg = @errmsg + ':  Correct Invoice and begin again.'
   		select @rcode = 1
   		goto error
   		end				
   
   	commit transaction
   	select @invdeleted = @invdeleted + 1
   
   getNextAcctTrans:
   	fetch next from bconacct into @Mth, @ARTrans
   	end		/* End Spin through 'On Account' Transactions list */
   
   if @onacctopencursor = 1
   	begin
   	close bconacct
   	deallocate bconacct
   	select @onacctopencursor = 0
   	end
   
   
   /* After Purging by Transaction, purge Temporary Customers, if flag has been set to do so.
       The benefit of doing so here is that 'Through Mth' and 'BegCust and EndCust' have already been established. */
   
   /* Temporary Customers Purge */
   if @deletetmpcust = 'Y'			
   	begin	/* Begin Delete Tmp Cust Loop */
   	declare bccust cursor local fast_forward for
   	select m.Customer
   	from bARCM m with (nolock)
   	where m.Customer >= isnull(@BeginningCustomer,-1) and m.Customer <= isnull(@EndingCustomer,1999999999)
   		and m.CustGroup = @CustGroup 
   		and m.SelPurge = case when (isnull(@BeginningCustomer,-1) = isnull(@EndingCustomer,1999999999) and isnull(@BeginningCustomer,-1) <> -1)
   			then m.SelPurge else 'N' end
   		and m.TempYN = 'Y'
   	order by m.Customer
   
   	open bccust
   	select @custopencursor = 1
   
   	fetch next from bccust into @Customer 
   	while @@fetch_status = 0
   		begin	/* Begin Temporary Customer Loop */
   		select @MultCompanyFlag = 0		
   		/* Spin through all companies:
   		   We use ARMT here because, using this to test for companies that share this CustGroup and Temporary Customer
   		   is reliable since a record always gets inserted when an invoice is created.  Also its more reliable than ARTH (Which
   		   also has the Co, CustGrp, Cust relationship) because it is conceivable that invoice transactions in ARTH
   		   may have been purged without purging information in ARMT. */
   		select @TempCo = min(t.ARCo)
   		from bARMT t with (nolock)
   		where t.CustGroup = @CustGroup and t.Customer = @Customer
   		while @TempCo is not null
   			begin	/* Begin Temporary Company Loop */
   			if @TempCo <> @arco
   				/* We do NOT want to delete ARMT for other Companies if they share this customer
   				   nor do we want to delete this customer from ARCM. */
   				begin
   				/* This Customer is shared by another Company, do nothing */
   				select @MultCompanyFlag = @MultCompanyFlag + 1
   				goto GetNextTempCo
   				end
   			else
   				begin
   				select @recnum = 0
   				/* For this Temporary Customer in this ARCo, check to see if any AR Lines still exists.
   				   These lines could be after the 'Through Date' (if previous transactions were deleted),
   				   and would indicate that Customer is still valid.  */
   				select @recnum = count(*)
   				from bARTL l with (nolock)
   				join bARTH h with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
   				where l.ARCo = @TempCo and h.CustGroup = @CustGroup and h.Customer = @Customer
   				/* @recnum = 0 then this would indicate that no lines exist now since user purged this customers
   				   transactions for this ARCo.  If lines do not exist, we may purge monthly totals for this ARCo/Customer. */
   				if @recnum = 0
   					begin
   					begin transaction
   					select @topurge = 0, @topurge2 = 0, @deleted = 0, @deleted2 = 0
   
   					select @topurge = count(*)
   					from bARMT with (nolock)
   					where ARCo = @TempCo and CustGroup = @CustGroup and Customer = @Customer
   
   					/* Start deleting Monthly totals for this ARCo/Customer. This is all or nothing deletion. 
   					   If this ARCo/temp customer does not have any ARTL Line records, then delete all records in ARMT.
   					   Users should use PURGE MISC prog to purge this customers monthly totals if a total delete not desired. */
   					delete bARMT
   					where ARCo = @TempCo and CustGroup = @CustGroup and Customer = @Customer
   					select @deleted = @@rowcount
   
   					select @topurge2 = count(*)
   					from bARTH with (nolock)
   					where ARCo = @TempCo and CustGroup = @CustGroup and Customer = @Customer
   
   					/* Now remove any stray 'P', 'R' type header records. A stray 'P'ayment header could get
   					   get left behind if all Invoices that were paid on by this record were to be Deleted
   					   instead of Purged.  The Delete invoice process doesn't know to check the associated
   					   payment records and to deleted them when empty.  */
   					delete bARTH
   					where ARCo = @TempCo and CustGroup = @CustGroup and Customer = @Customer
   					select @deleted2 = @@rowcount
   
   					if @topurge <> @deleted or @topurge2 <> @deleted2
   						begin
   						rollback transaction
   						select @errmsg = 'An error has occurred with Temporary Customer #' + convert(varchar(10),@Customer)
   						select @errmsg = @errmsg + ', and has not been purged! Begin again.'
   						select @rcode = 1
   						goto error
   						end
   					
   					commit transaction	
   					end	-- END DELETE ARMT FOR THIS ARCO
   				else
   					begin
   					/*  ARTL detail records still exist for this Temporary Customer.  Do Nothing */ 
   					select @MultCompanyFlag = @MultCompanyFlag + 1
   					goto GetNextTempCo
   					end
   				end
   	
   			GetNextTempCo:
   				select @TempCo = min(t.ARCo)
   				from bARMT t with (nolock)
   				where t.CustGroup = @CustGroup and t.Customer = @Customer and t.ARCo > @TempCo
   			end		/* End Temporary Company Loop */
   
   		/* Delete Temporary Customer from ARCM only if this customer is not used by other companies
   		   and if this ARCo/Customer no longer has records in bARTL or bJCCM */
   		if @MultCompanyFlag = 0
   			begin
   			select @recnum = 0		-- reset flag
   			select @recnum = count(*)
   			from bJCCM with (nolock)
   			where bJCCM.CustGroup = @CustGroup and bJCCM.Customer = @Customer
   			/* @recnum = 0 then this would indicate that no lines exist now in JC Contract Master for this Customer.
   			   If lines do not exist, we may now remove this Temporary Customer. */
   			if @recnum = 0
   				begin
   				delete bARCM 
   				where CustGroup = @CustGroup and Customer = @Customer
   				end
   			end
   
   	GetNextTempCustomer:
   		fetch next from bccust into @Customer
   		end		/* End Temporary Customer Loop */
   
   	if @custopencursor = 1
   		begin
   		close bccust
   		deallocate bccust
   		select @custopencursor = 0
   		end
   	end		/* End Delete Tmp Cust Loop */
   
   /* After Purging by Transaction, purge Inactive Customers, if flag has been set to do so.
       The benefit of doing so here is that 'Through Mth' and 'BegCust and EndCust' have already been established. */
   
   /* InActive Customer Purge */
   if @deleteinactivecust = 'Y'
   	begin	/* Begin Delete InActive Cust Loop */
   	declare bccust cursor local fast_forward for
   	select m.Customer
   	from bARCM m with (nolock)
   	where m.Customer >= isnull(@BeginningCustomer,-1) and m.Customer <= isnull(@EndingCustomer,1999999999)
   		and m.CustGroup = @CustGroup 
   		and m.SelPurge = case when (isnull(@BeginningCustomer,-1) = isnull(@EndingCustomer,1999999999) and isnull(@BeginningCustomer,-1) <> -1)
   			then m.SelPurge else 'N' end
   		and m.Status = 'I'
   	order by m.Customer
   
   	open bccust
   	select @custopencursor = 1
   
   	fetch next from bccust into @Customer 
   	while @@fetch_status = 0
   		begin	/* Begin InActive Customer Loop */
   		select @MultCompanyFlag = 0		
   		/* Spin through all companies:
   		   We use ARMT here because, using this to test for companies that share this CustGroup and Temporary Customer
   		   is reliable since a record always gets inserted when an invoice is created.  Also its more reliable than ARTH (Which
   		   also has the Co, CustGrp, Cust relationship) because it is conceivable that invoice transactions in ARTH
   		   may have been purged without purging information in ARMT. */
   		select @InactiveCo = min(t.ARCo)
   		from bARMT t with (nolock)
   		where t.CustGroup = @CustGroup and t.Customer = @Customer
   		while @InactiveCo is not null
   			begin	/* Begin InActive Company Loop */
   			if @InactiveCo <> @arco
   				/* We do NOT want to delete ARMT for other Companies if they share this customer
   				   nor do we want to delete this customer from ARCM. */
   				begin
   				/* This Customer is shared by another Company, do nothing */
   				select @MultCompanyFlag = @MultCompanyFlag + 1
   				goto GetNextInactiveCo
   				end
   			else
   				begin
   				select @recnum = 0
   				/* For this Inactive Customer in this ARCo, check to see if any AR Lines still exists.
   				   These lines could be after the 'Through Date' (if previous transactions were deleted),
   				   and would indicate that Customer is still valid. */
   				select @recnum = count(*)
   				from bARTL l with (nolock)
   				join bARTH h with (nolock) on h.ARCo = l.ARCo and h.Mth = l.Mth and h.ARTrans = l.ARTrans
   				where l.ARCo = @InactiveCo and h.CustGroup = @CustGroup and h.Customer = @Customer
   				/* @recnum = 0 then this would indicate that no lines exist now since user purged this customers
   				   transactions for this ARCo.  If lines do not exist, we may purge monthly totals for this ARCo/Customer. */
   				if @recnum = 0
   					begin
   					begin transaction
   					select @topurge = 0, @topurge2 = 0, @deleted = 0, @deleted2 = 0
   
   					select @topurge = count(*)
   					from bARMT with (nolock)	
   					where ARCo = @InactiveCo and CustGroup = @CustGroup and Customer = @Customer
   
   					/* Start deleting Monthly totals for this ARCo/Customer. This is all or nothing deletion. 
   					   If this ARCo/Inactive customer does not have any ARTL Line records, then delete all records in ARMT.
   					   Users should use PURGE MISC prog to purge this customers monthly totals if a total delete not desired. */
   					delete bARMT
   					where ARCo = @InactiveCo and CustGroup = @CustGroup and Customer = @Customer
   					select @deleted = @@rowcount
   
   					select @topurge2 = count(*)
   					from bARTH with (nolock)
   					where ARCo = @InactiveCo and CustGroup = @CustGroup and Customer = @Customer
   
   					/* Now remove any stray 'P', 'R' type header records. A stray 'P'ayment header could get
   					   get left behind if all Invoices that were paid on by this record were to be Deleted
   					   instead of Purged.  The Delete invoice process doesn't know to check the associated
   					   payment records and to deleted them when empty.  */
   					delete bARTH
   					where ARCo = @InactiveCo and CustGroup = @CustGroup and Customer = @Customer
   					select @deleted2 = @@rowcount
   
   					if @topurge <> @deleted or @topurge2 <> @deleted2
   						begin
   						rollback transaction
   						select @errmsg = 'An error has occurred with Inactive Customer #' + isnull(convert(varchar(10),@Customer),'')
   						select @errmsg = @errmsg + ', and has not been purged! Begin again.'
   						select @rcode = 1
   						goto error
   						end
   
   					commit transaction
   					end		-- END DELETE ARMT FOR THIS ARCO
   				else
   					begin
   					/*  ARTL detail records still exist for this Temporary Customer.  Do Nothing */
   					select @MultCompanyFlag = @MultCompanyFlag + 1
   					goto GetNextInactiveCo
   					end
   				end
   
   		GetNextInactiveCo:
   			select @InactiveCo = min(t.ARCo)
   			from bARMT t with (nolock)
   			where t.CustGroup = @CustGroup and t.Customer = @Customer and t.ARCo > @InactiveCo
   			end		/* End InActive Company Loop */
   
   		/* Delete Inactive Customer from ARCM only if this customer is not used by other companies
   		   and if this ARCo/Customer no longer has records in bARTL */
   		if @MultCompanyFlag = 0
   			begin
   			select @recnum = 0		-- reset flag
   			select @recnum = count(*)
   			from bJCCM with (nolock)
   			where bJCCM.CustGroup = @CustGroup and bJCCM.Customer = @Customer
   			/* @recnum = 0 then this would indicate that no lines exist now in JC Contract Master for this Customer.
   			   If lines do not exist, we may now remove this InActive Customer. */
   			if @recnum = 0
   				begin
   				delete bARCM where CustGroup = @CustGroup and Customer = @Customer
   				end
   			end
   
   	GetNextInactiveCustomer:
   		fetch next from bccust into @Customer 	
   		end		/* End InActive Customer Loop */
   
   	if @custopencursor = 1
   		begin
   		close bccust
   		deallocate bccust
   		select @custopencursor = 0
   		end
   	end		/* End Delete InActive Cust Loop */
   
   bspexit:
   
   -- Do Something
   
   error:
   
   if @delPsopencursor = 1
   	begin
   	close bcDelHeaderPmt
   	deallocate bcDelHeaderPmt
   	select @delPsopencursor = 0
   	end
   if @invopencursor = 1
   	begin
   	close bcinv
   	deallocate bcinv
   	select @invopencursor = 0
   	end
   if @onacctopencursor = 1
   	begin
   	close bconacct
   	deallocate bconacct
   	select @onacctopencursor = 0
   	end
   if @custopencursor = 1
   	begin
   	close bccust
   	deallocate bccust
   	select @custopencursor = 0
   	end
   
   if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspARPurgePaidInvoices]'
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARPurgePaidInvoices] TO [public]
GO
