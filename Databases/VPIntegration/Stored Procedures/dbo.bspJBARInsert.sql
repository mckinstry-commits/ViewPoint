SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBARInsert]
   
/****************************************************************************
* CREATED BY:      bc 10/21/99
* MODIFIED By : 	bc 06/06/00 - linked the department to the Item instead of the Contract
*  		bc 07/06/00 - removed the case statement for ARLine from the JBAL insert and replaced it with the IsNull statement
*    	bc 07/12/00 - surrounded the insert statements within a transaction
*    	bc 10/10/00 - added discount to JBAL
*   	bc 11/28/00 - corrected the @oldRelRetg select statement
* 		gh 12/19/00 - added subscript code to the JBAL insert for large contract item descriptions.
*	 	tjl 3/6/01 - modified to insert GL Override Acct into JBAL is selected on T&MBill form
*		tjl 4/13/01 - Allow for non-contract bills
*     	kb 11/26/1 - issue #15303
*		TJL 10/17/02 - Issue #18982, Update code for Non-Contract Bills interfacing to AR
*		TJL 11/20/02 - Issue #17278, Allow changes to bills in a closed month.
*		TJL 04/28/03 - Issue #20936, Reverse Release Retainage
*		TJL 07/09/03 - Issue #21784, Do not allow 2 users to interface same bill
*		TJL 08/25/03 - Issue #22232, Correct is TaxAmt is NULL for Non-Contract Bills
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure, remove Item psuedo cursor
*		TJL 10/06/03 - Issue #17897, Corrected MiscDistCode references to datatype char(10) (Consistent w/AR and MS)
*		TJL 02/24/04 - Issue #18917, Only mod was to change @retgtrans TO @crtrans throughout for clarity
*		TJL 05/04/04 - Issue #18944, Add Invoice Description to JBTMBills and JBProgressBillHeader forms
*		TJL 08/03/04 - Issue #25283, If AR Original Line missing for Item on changed bill, generate on the fly
*		TJL 09/02/04 - Issue #22565, Interface Notes from JBIT to ARTL
*		TJL 12/29/04 - Issue #26508, Noticed while working on this issue, correct (select @JBITarline = ARLine) below
*		TJL 01/07/05 - Issue #26155, If RetgPct greater than 99.9999 insert 0 to avoid NULL input error
*		TJL 07/18/08 - Issue #128287, JB International Sales Tax
*		TJL 02/13/09 - Issue #132271, Amount = 0.00, Tax Amount only on Non-Contract billing
*		TJL 04/23/10 - Issue #138961, Change @seq to datatype 'int' to solve Arithmetic Overflow error
*
*
* USAGE: This procedure is called to fill in jb batch tables based on JBIN, JBIT & JBMD records, one bill at a time.
*
* WARNING!!  JBARinsert, JBProgVal and JBProgPost routines are directly dependent on this procedure.
*            	any changes made here must be accounted for in the above programs.
*
*
*  INPUT PARAMETERS
*	@jbco	    = Company
*	@billmth 	= Mth
* 	@batchid    = BatchId
* 	@seq        = BatchSeq
* 	@billnumber = JBIN bill number
*
* OUTPUT PARAMETERS
*   	@msg      error message if error occurs
* RETURN VALUE
*   	0         success
*   	1         Failure
****************************************************************************/
(@jbco bCompany, @batchmth bMonth, @billmth bMonth, @batchid int, @billnumber int, 
@msg varchar(255) output)

as
set nocount on
   
declare @rcode int, @arco bCompany, @artrans bTrans, @item bContractItem, @custgroup bGroup, @code char(10),
   	@batchtranstype char(1), @arline smallint, @crtrans bTrans, @contract bContract, @oldRelRetg bDollar,
   	@seq int, @ar_glco bCompany, @line int, @units bUnits, @revglacct bGLAcct, @rectype tinyint,
   	@totalamt bDollar, @GLoveride bYN, @GLoverideacct bGLAcct, @taxcode bTaxCode,
   	@taxbasis bDollar, @taxamt bDollar, @retainage bDollar, @taxgrp bGroup, @retpct bPct, @discount bDollar,
   	@customer bCustomer, @inusebatchid bBatchID, @inusemth bMonth, @openbJBITcursor int,
	@retgtax bDollar, @oldrelretgtax bDollar, @releasetocurrentAR bYN
   
declare @adjust_trans bTrans, @adjust_mth bMonth, @JBITarline smallint, @Aarline smallint
   
select @rcode=0, @openbJBITcursor = 0
   
/* Collect info relative to this entire bill */
select @artrans = n.ARTrans, @arco = o.ARCo, @crtrans = n.ARRelRetgCrTran /*Released, New Retg Invoice trans*/, 
	@contract = n.Contract, @GLoveride = n.OverrideGLRevAcctYN,
	@GLoverideacct = n.OverrideGLRevAcct, @customer = n.Customer,
	@custgroup = n.CustGroup, @ar_glco = n.ARGLCo, @batchtranstype = n.InvStatus,
	@rectype = n.RecType, @inusebatchid = n.InUseBatchId, @inusemth = n.InUseMth,
	@releasetocurrentAR = a.RelRetainOpt
from bJBIN n with (nolock)
join bJCCO o with (nolock) on n.JBCo = o.JCCo
join bARCO a with (nolock) on a.ARCo = o.ARCo
where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber = @billnumber
   
/* Do not allow the same Bill to be interfaced by two users simultaneously */
if (@inusebatchid is not null and @inusemth is not null) or @batchtranstype not in ('A', 'C', 'D')
   	begin
   	select @msg = 'This Bill has been selected or Interfaced by another user. '
   	select @msg = @msg + char(13) + char(10)
   	select @msg = @msg + '     BillMonth: ' + right(convert(varchar(8), @billmth, 3), 5) + ' - BillNumber: ' + Convert(varchar(12), @billnumber)
   	select @msg = @msg + char(13) + char(10)
   	select @msg = @msg + 'It has not been added to this Batch for interfacing.'
   	select @rcode = 5	--STDBTK_GENERAL_FAILURE, do not abort process totally, just give warning
   	goto bspexit
   	end
   
select @seq = isnull(max(BatchSeq),0) + 1
from bJBAR with (nolock)
where Co = @jbco and Mth = @batchmth /*@billmth*/ and BatchId = @batchid	
   
begin transaction
   
/* add record to JBAR based on JBIN */
insert into bJBAR (Co, Mth, BatchId, BatchSeq, BillNumber, BatchTransType, Invoice, Contract, CustGroup, Customer, RecType,
	Description, ARTrans, TransDate, PayTerms, DueDate, DiscDate, BillMonth, RevRelRetgYN, Notes)
select JBCo, @batchmth /*BillMonth*/, @batchid, @seq, BillNumber, InvStatus, Invoice, Contract, CustGroup, Customer, RecType,
	InvDescription, ARTrans, InvDate, PayTerms,
	DueDate, DiscDate, BillMonth, RevRelRetgYN, Notes
from bJBIN with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber 
   
if @@rowcount <> 1
	begin
 	select @msg = 'Error inserting JBAR record', @rcode = 1
 	goto Error
 	end
   
/* initialize the ar line variable */
if @contract is not null
   	begin
   	select @arline = isnull(max(ARLine),0) + 1
   	from JBIT with (nolock)
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber
   	end
else
   	begin
	select @arline = 1
   	end
   
/* Begin the non-contract type bills */
if @contract is null
   	begin
   /* Check if any lines exist for this bill */
	select 1
 	from bJBIL with (nolock)
 	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber
	if @@rowcount = 0
		begin
		select @msg = 'There are no lines for T&M Bill: ' + convert(varchar(15), @billnumber), @rcode = 1
		goto Error
		end
   
   	/* Get GL Revenue Acct */
   	if @GLoveride = 'N'
   		begin
   		select @revglacct = GLRevAcct 
   		from bARRT with (nolock) 
   		where ARCo = @ar_glco and RecType = @rectype
   		end
	else
   		begin
		select @revglacct = @GLoverideacct
   		end
   
	/* Get TaxGroup and TaxCode for Non-Contract */
	select @taxgrp = TaxGroup, @taxcode = TaxCode
	from bARCM with (nolock)
	where CustGroup = @custgroup and Customer = @customer	--This from bJBIN
   	
	/* Get required values to insert for this T&M bill */
	/* For Non-Contract, all totals are sum'd for a SINGLE line entry into JBAL and then into ARTL */
   
   	/* Get Tax Totals */
   	select @taxbasis = sum(Basis), @taxamt = sum(Total) 
   	from bJBIL with (nolock)
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber
   		and MarkupOpt = 'T'

   	/* Get Retainage Tax Totals */
   	select @retgtax = sum(Total) 
   	from bJBIL with (nolock)
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber
   		and MarkupOpt = 'X'

   	/* Get BillTotal, Retainage and Discount Totals. */
	select @retainage = sum(Retainage) + isnull(@retgtax,0), @discount = sum(Discount), 
		@totalamt = sum(Total) - (isnull(@taxamt,0) + isnull(@retgtax,0))
   	from bJBIL with (nolock)
	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber

   	---- select @totalamt = isnull(@totalamt, 0) - isnull(@taxamt, 0)  --Removed during International mods
   
   	/* Get Retainage PCT on this Bill */
	select @retpct = (select distinct MarkupRate from bJBIL with (nolock)
	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and MarkupOpt = 'R')
   
	/* Now use these values to insert a SINGLE line into JBAL */
	insert  bJBAL (Co, Mth, BatchId, BatchSeq,  Item, ARLine, BatchTransType, GLCo, 
		GLAcct, Description, TaxGroup, TaxCode, UM, Amount, Units, 
   		TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax,
   		RetgRel, RetgTaxRel, Notes, Discount)
   	select @jbco, @batchmth /*@billmth*/, @batchid, @seq, null, @arline, @batchtranstype, @ar_glco,
       	@revglacct,	'JB T&M', @taxgrp, @taxcode, 'LS', isnull(@totalamt, 0), 0, 
   		isnull(@taxbasis, 0), isnull(@taxamt, 0), isnull(@retpct, 0), isnull(@retainage, 0), isnull(@retgtax, 0),
   		0, 0, null, isnull(@discount, 0)
   
   	if @@rowcount = 0
		begin
		select @msg =  'Error inserting JBAL record for T&M Bill: ' + convert(varchar(15), @billnumber), @rcode = 1
		goto Error
		end
   
   	/* At this time 10/17/02, I am not certain if oldretg will come into play for Non-Contract
   	   T&M Bills as it does with Contract T&M Bills.  Will address if it becomes an issue. */
   
	end  -- end the non-contract type bills
 
/* Begin the contract type bills */
if @contract is not null
   	begin
       /* spin through all the items in JBIT for this bill and insert values into JBAL */
   	declare bJBIT_item cursor local fast_forward for
   	select Item
   	from bJBIT with (nolock)
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber
   	
   	open bJBIT_item
   	select @openbJBITcursor = 1
   	
   	fetch next from bJBIT_item into @item
   	while @@fetch_status = 0
		begin	/* Begin Item loop */
   
   		/* Getting ARLine in the cursor above causes problems during some conditions.
   		   Leave this statement in place. */  
   		select @JBITarline = ARLine
   		from bJBIT with (nolock)
   		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber
   			and Item = @item
   
 		insert into bJBAL (Co, Mth, BatchId, BatchSeq, Item, 
			ARLine, 
			BatchTransType, GLCo, GLAcct, Description,
       		TaxGroup, TaxCode, UM, Amount, Units, TaxBasis, TaxAmount, RetgPct, Retainage, RetgTax, RetgRel, RetgTaxRel,
         	Notes, Discount)
 		select t.JBCo, @batchmth /*t.BillMonth*/, @batchid, @seq, t.Item, 
			case when @batchtranstype in ('C', 'D') then t.ARLine else isnull(t.ARLine,@arline) end, 
			n.InvStatus, n.JCGLCo,
        	case @GLoveride when 'Y' then @GLoverideacct else case m.ContractStatus when 3 then d.ClosedRevAcct else d.OpenRevAcct end end,
        	case n.BillType when 'T' then 'JB T&M' else 'App# ' + convert(varchar(5),n.Application) + ' ' + substring(t.Description,1,19) end,
        	t.TaxGroup, t.TaxCode, i.UM, t.AmtBilled, t.UnitsBilled, t.TaxBasis, t.TaxAmount,
			case when (select case t.AmtBilled when 0 then 0 else (t.RetgBilled - t.RetgTax)/t.AmtBilled end) > 99.9999 then 0 
				else (select case t.AmtBilled when 0 then 0 else (t.RetgBilled - t.RetgTax)/t.AmtBilled end) end,
			t.RetgBilled, t.RetgTax, -(t.RetgRel), -(t.RetgTaxRel),
        	t.Notes, t.Discount
 		from bJBIT t with (nolock)
 		join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth
 		join bJCCI i with (nolock) on n.JBCo = i.JCCo and n.Contract = i.Contract and t.Item = i.Item
 		join bJCCM m with (nolock) on n.JBCo = m.JCCo and n.Contract = m.Contract
 		join bJCDM d with (nolock) on n.JBCo = d.JCCo and i.Department = d.Department and n.JCGLCo = d.GLCo
 		where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber and t.Item = @item
   
		if @@rowcount = 0
       		begin
       		select @msg = 'Error inserting JBAL record for contract item : ' + convert(varchar(20),@item) +
                     			' from bill number: ' + convert(varchar(15),@billnumber), @rcode = 1
       		goto Error
       		end
   
		/********** Special Conversion AR consideration when changing/deleting an interfaced bill *********/
		If @batchtranstype in ('C', 'D')
			begin	
			/* Conversion Issue:  Look at Original AR 'I'nvoice transaction.  Add Item if it does not already exist. 
			   We make an assumption that if the Original AR transaction line is missing then the JBIT.ARLine
			   will be NULL since where would if have gotten it from?  */
			if @item is not null and @JBITarline is null
				begin	/* Begin Add Item to Original AR Transaction */
		 		if not exists(select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @billmth and ARTrans = @artrans and
		 	             JCCo = @jbco and Contract = @contract and Item = @item)
					begin	/* Begin Adding Item to original Invoice record in ARTL */
	
					/* Typically ApplyLine and ARLine on the original transaction are the same.
					   If we generate an ARLine that is already in use on the original transaction 
					   then increment it by one and check again.  */
				CheckNextARLine:
					if exists(select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @billmth
							and ARTrans = @artrans and ARLine = @arline)
						begin
						select @arline = @arline + 1
						goto CheckNextARLine
						end
   	
   					/* Insert a AR line into the original invoice for this Item */
   					insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType,
   						Description,
   						GLCo, GLAcct, TaxGroup, TaxCode, TaxBasis, TaxAmount,
   						UM, Amount, RetgPct, Retainage, RetgTax, DiscOffered, MatlUnits, ContractUnits,
   						JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
   					select @arco, t.BillMonth, @artrans, @arline, n.RecType, 'C',
   						case n.BillType when 'T' then 'JB T&M' else 'App# ' + convert(varchar(5),n.Application) + ' ' + t.Description end,
   						n.JCGLCo, case m.ContractStatus when 3 then d.ClosedRevAcct else d.OpenRevAcct end,
   						t.TaxGroup, t.TaxCode, 0, 0,
   						i.UM, 0, 0, 0, 0, 0, 0, 0,
   						@jbco, @contract, @item, @billmth, @artrans, @arline
   					from bJBIT t with (nolock)
   					join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth
   					join bJCCI i with (nolock) on n.JBCo = i.JCCo and n.Contract = i.Contract and t.Item = i.Item
   					join bJCCM m with (nolock) on n.JBCo = m.JCCo and n.Contract = m.Contract
   					join bJCDM d with (nolock) on n.JBCo = d.JCCo and i.Department = d.Department and n.JCGLCo = d.GLCo
   					where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber and t.Item = @item
   	 		
   			 		update bJBIT
   			 		set ARLine = @arline, AuditYN = 'N'
   			 		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @item
   			
   			 		update bJBIT
   			 		set AuditYN = 'Y'
   			 		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @item
   
   					/* This line is no longer missing in AR. Update JBAL with AR Line Number */	
   					update bJBAL
   					set ARLine = @arline
   			 		where Co = @jbco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @seq
   						and Item = @item and ARLine is null
   
   					/* Increment next ARLine number since we used this one to correct missing AR Lines */
   					select @arline = @arline + 1 
    				end
    			end		/* End Add Item to Original AR Transaction */
   
   	 		/* Insert a line into the most recent adjustment, applied to the original invoice, if one exists 
   			   This will make Old Value available later in this procedure. */
   	 		select @adjust_trans = null
   	
   			/* Get Adjustment Latest Month and Latest Transaction for that Month. */
   	 		select @adjust_mth = max(Mth)
   	 		from bARTH with (nolock) 
   	 		where ARCo = @arco and AppliedMth = @billmth and AppliedTrans = isnull(@artrans, 0) and ARTransType = 'A' and Source = 'JB'
   			if @adjust_mth is not null
   				begin			
   	 			select @adjust_trans = max(ARTrans)
   	 			from bARTH with (nolock) 
   	 			where ARCo = @arco and AppliedMth = @billmth and AppliedTrans = isnull(@artrans, 0) and ARTransType = 'A' and Source = 'JB'
   					and Mth = @adjust_mth
   				end
   	
   	 		/* If we have a Max Adjustment transaction, check for the existence of this Item. If missing, insert. */
   	  		if @adjust_trans is not null
   	    		begin	/* Begin Adding Item to latest Adjustment record in ARTL */
   	 			/* Look at Latest Adjustment transaction.  Add Item if it does not already exist. */
   	  			if not exists(select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @adjust_mth and ARTrans = @adjust_trans and
   	  	             JCCo = @jbco and Contract = @contract and Item = @item)
   	 				begin
   					/* We need to retrieve the value from the Original Invoice Transaction to assure that the ApplyLine
   					   value is correct.  (Do not want an Adjustment line applied to the wrong original line!) */
   					select @Aarline = ARLine
   					from bARTL with (nolock)
   					where ARCo = @arco and Mth = @billmth and ARTrans = @artrans
   						and JCCo = @jbco and Contract = @contract and Item = @item
   					if @Aarline is null
   						begin
   						select @msg = 'Old Adjustment Transaction for this Item could not be added', @rcode = 1
   						goto Error
   						end
   
   					/* Typically ApplyLine and ARLine on an Adjustment transaction are the same.
   					   However, if we encounter an Adjustment transaction where this isn't the case
   					   then our new ARLine may already be in use.  If so this needs to be reviewed
   					   and repaired manually. (I don't know if this condition will occur. */
   					if exists(select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @adjust_mth
   							and ARTrans = @adjust_trans and ARLine = @Aarline)
   						begin
   						select @msg = 'Original and Adjustment ARLine numbers are out of sync in AR. Contact Bidtek!', @rcode = 1
   						goto Error
   						end
   
   		   			insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType,
   		            	Description,
   		              	GLCo, GLAcct, TaxGroup, TaxCode, TaxBasis, TaxAmount,
   		              	UM, Amount, RetgPct, Retainage, RetgTax, DiscOffered, MatlUnits, ContractUnits,
   		              	JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
   		   			select @arco, @adjust_mth, @adjust_trans, @Aarline, n.RecType, 'C',
   		          		case n.BillType when 'T' then 'JB T&M' else 'App# ' + convert(varchar(5),n.Application) + ' ' + t.Description end,
   		          		n.JCGLCo, case m.ContractStatus when 3 then d.ClosedRevAcct else d.OpenRevAcct end,
   		          		t.TaxGroup, t.TaxCode, 0, 0,
   		          		i.UM, 0, 0, 0, 0, 0, 0, 0,
   		          		@jbco, @contract, @item, @billmth, @artrans, @Aarline
   		   			from bJBIT t
   		   			join bJBIN n with (nolock) on t.JBCo = n.JBCo  and t.BillMonth = n.BillMonth and t.BillNumber = n.BillNumber
   		   			join bJCCI i with (nolock) on n.JBCo = i.JCCo and n.Contract = i.Contract and t.Item = i.Item
   		   			join bJCCM m with (nolock) on n.JBCo = m.JCCo and n.Contract = m.Contract
   		   			join bJCDM d with (nolock) on n.JBCo = d.JCCo and i.Department = d.Department and n.JCGLCo = d.GLCo
   		   			where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber and t.Item = @item
   
   			 		update bJBIT
   			 		set ARLine = @Aarline, AuditYN = 'N'
   			 		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @item
   			
   			 		update bJBIT
   			 		set AuditYN = 'Y'
   			 		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @item
   
   					/* This line is no longer missing in AR. Update JBAL with AR Line Number */	
   					update bJBAL
   					set ARLine = @Aarline
   			 		where Co = @jbco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @seq
   						and Item = @item and ARLine is null
   
					end
	 	 		end 	/* End Adding Item to latest Adjustment record in ARTL */
			end		
		/********** End Special Conversion AR consideration when changing/deleteing an interfaced bill *********/
   
   		/* (@crtrans = JBIN.ARRelRetgCrTrans)
   		   Representing the (Released) or (Reverse Released) transaction) when acquiring old release retainage 
   		   values.  This transaction contains a single line in ARTL if (Released) or multiple lines
   		   in ARTL if (Reverse Released). */
		if @crtrans is not null
           	begin
   			/* If here, we are re-interfacing a Bill that was used to Release retainage.
   			   If this is a Closed Mth Bill, then the BatchMth and BillMth will be
   			   different.  We still want Old RelRetg values from the this Bills, 
   			   BillMth and BillNumber. */
           	select @oldRelRetg = case when @releasetocurrentAR = 'Y' then isnull(sum(-Amount),0)
					else isnull(sum(-Retainage),0) end,
				@oldrelretgtax = case when @releasetocurrentAR = 'Y' then isnull(sum(-TaxAmount),0) 
					else isnull(sum(-RetgTax),0) end
           	from bARTL with (nolock)
           	where ARCo = @arco and ARTrans = @crtrans and Mth = @billmth and LineType in ('R','V') and
               	JCCo = @jbco and Contract = @contract and Item = @item
 
 
   			/* What we are doing here is:  For each Item on this Bill being interfaced, we are
   			   inserting new values into JBAL batch table from JBIT.  However, we get
   			   Old Release Retg values from ARTL (Per above) and update JBAL separately
   			   with these values since they do not exist in JBIT. */ 
			update bJBAL
           	set oldRetgRel = @oldRelRetg, oldRetgTaxRel = @oldrelretgtax
           	where Co = @jbco and Mth = @batchmth /*@billmth*/ and BatchId = @batchid and BatchSeq = @seq and BatchTransType in ('C','D') and
               	Item = @item
       	 	end
   
    	/* increment the ar line, but only when the column in JBIT has yet to be set for this item */
 		if exists (select 1	from JBIT with (nolock)
			where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and Item = @item and ARLine is null)

  		select @arline = @arline + 1
   
   		fetch next from bJBIT_item into @item
		end		/* End Item loop */
	end -- end for contract type bills
 
/* get the customer group for the spin through JBMD */
-- We get this initially above
--select @custgroup = CustGroup, @batchtranstype = InvStatus
--from bJBIN with (nolock)
--where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber
   
/* spin through all the records in JBMD and insert info into JBBM */
select @code = min(MiscDistCode)
from bJBMD with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and CustGroup = @custgroup
while @code is not null
   	begin
 	insert into bJBBM (JBCo, Mth, BatchId, CustGroup, MiscDistCode, BatchSeq, BatchTransType, DistDate, Description, Amount)
  	select JBCo, @batchmth /*@billmth*/, @batchid, @custgroup, @code, @seq, @batchtranstype, DistDate, Description, Amt
  	from bJBMD with (nolock)
  	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and CustGroup = @custgroup and MiscDistCode = @code
   
 	select @code = min(MiscDistCode)
 	from bJBMD with (nolock)
 	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and CustGroup = @custgroup and MiscDistCode > @code
 	end
   
/* update old values in JBAR/JBAL if the InvStatus = 'C' or 'D' with info from AR based on transaction and line */
if not exists (select 1 from bJBAR with (nolock) where Co = @jbco and Mth = @batchmth /*@billmth*/ and BillNumber = @billnumber and BatchTransType in ('C','D'))
 	begin
 	/* If nothing in this batch is marked for 'C'hange or 'D'elete, then no need
	   to get old values from AR. */
 	goto Finished
	end
   
/**************
* Old Values *
*************/
   
/* Because we now allow changes to Bills in a closed month, we can no longer assume that
   BatchMth is the same as BillMth.  Therefore it is now necessary to get the maximum
   transaction from the maximum month.

   This creates another potential problem.  User may enter one change in 2002-11-01 and
   interface and then attempt to enter a 2nd change in 2002-10-01.  If allowed to do this,
   the latest change would not be the Maximum Month and old Values would be incorrect.
   Customers want the flexibility to select a desired open month, therefore this situation
   will be looked for in batch validation and IF an 'A' transaction for this Bill already
   exists for a later batch month in ARTH, an error will occur and user will need to clear
   the batch and select a Batch Month equal to or later than the Maximum month.

   The idea of doing a sum(Amounts) to avoid this also fails because the value changed may
   not be an amount at all.  In which case how would we identify the latest change if not
   by Maximum month. */
   
select @adjust_mth = max(Mth)
from bARTH with (nolock)
where ARCo = @arco and AppliedMth = @billmth and AppliedTrans = isnull(@artrans, 0) and ARTransType = 'A' and Source = 'JB'
if @adjust_mth is not null
   	begin	/* Begin Adjust Mth */
   	select @adjust_trans = max(ARTrans)
   	from bARTH with (nolock)
   	where ARCo = @arco and AppliedMth = @billmth and AppliedTrans = isnull(@artrans, 0) and ARTransType = 'A' 
   		and Source = 'JB' and Mth = @adjust_mth
   	if @adjust_trans is not null
   	  	begin
   	  	/* Get the old amount from the last adjustment that was made */
   	  	update bJBAR
   	  	set oldInvoice = a.Invoice, oldContract = a.Contract, oldCustomer = a.Customer, oldRecType = a.RecType, oldDescription = a.Description,
   	    	oldTransDate = a.TransDate, oldDueDate = a.DueDate, oldDiscDate = a.DiscDate, oldPayTerms = a.PayTerms
   	  	from bJBAR r with (nolock)
   	  	join bARTH a with (nolock) on  a.ARCo = @arco and a.Mth = @adjust_mth /*@billmth*/ and a.ARTrans = @adjust_trans
   	  	where r.Co = @jbco and r.Mth = @batchmth /*@billmth*/ and r.BatchId = @batchid and r.BatchSeq = @seq and r.BatchTransType in ('C','D')
   
   		/* The Old Bill Header Notes are always associated with Original AR Invoice Header, Not from the Adjustments
   		   that have occured. */
   	  	update bJBAR
   	  	set oldNotes = a.Notes
   	  	from bJBAR r with (nolock)
   	  	join bARTH a with (nolock) on a.ARCo = @arco and a.Mth = @billmth /*r.Mth*/ and a.ARTrans = r.ARTrans
   	  	where r.Co = @jbco and r.Mth = @batchmth /*@billmth*/ and r.BatchId = @batchid and r.BatchSeq = @seq and r.BatchTransType in ('C','D')
   	
   	  	update bJBAL
   	  	set oldLineType = a.LineType, oldDescription = a.Description,
   	    	oldAmount = isnull(a.Amount,0) - (isnull(a.TaxAmount,0) + isnull(a.RetgTax,0)),
   	    	oldUnits = a.ContractUnits, oldTaxCode = a.TaxCode, oldTaxBasis = a.TaxBasis,
   	    	oldTaxAmount = a.TaxAmount, oldRetgPct = a.RetgPct, oldRetainage = a.Retainage, oldRetgTax = a.RetgTax,
   			oldDiscount = a.DiscOffered, oldNotes = a.Notes
   	  	from bJBAL l with (nolock)
   	  	join bARTL a with (nolock) on a.ARCo = @arco and a.Mth = @adjust_mth /*@billmth*/ and a.ARTrans = @adjust_trans and l.ARLine = a.ARLine
   	  	where l.Co = @jbco and l.Mth = @batchmth /*@billmth*/ and l.BatchId = @batchid and l.BatchSeq = @seq and l.BatchTransType in ('C','D')
   	  	end
	end		/* End Adjust Mth */	
   
if @adjust_mth is null
 	begin
 	/* Get the old amounts from the original invoice */
 	update bJBAR
 	set oldInvoice = a.Invoice, oldContract = a.Contract, oldCustomer = a.Customer, oldRecType = a.RecType, oldDescription = a.Description,
   		oldTransDate = a.TransDate, oldDueDate = a.DueDate, oldDiscDate = a.DiscDate, oldPayTerms = a.PayTerms,
		oldNotes = a.Notes
 	from bJBAR r with (nolock)
 	join bARTH a with (nolock) on a.ARCo = @arco and a.Mth = @billmth /*r.Mth*/ and a.ARTrans = r.ARTrans
 	where r.Co = @jbco and r.Mth = @batchmth /*@billmth*/ and r.BatchId = @batchid and r.BatchSeq = @seq and r.BatchTransType in ('C','D')

 	update bJBAL
 	set oldLineType = a.LineType, oldDescription = a.Description,
   		oldAmount = isnull(a.Amount,0) - (isnull(a.TaxAmount,0) + isnull(a.RetgTax,0)),
   	oldUnits = a.ContractUnits, oldTaxCode = a.TaxCode, oldTaxBasis = a.TaxBasis,
   	oldTaxAmount = a.TaxAmount, oldRetgPct = a.RetgPct, oldRetainage = a.Retainage, oldRetgTax = a.RetgTax,
	oldDiscount = a.DiscOffered, oldNotes = a.Notes
 	from bJBAL l with (nolock)
 	join bARTL a with (nolock) on a.ARCo = @arco and a.Mth = @billmth /*l.Mth*/ and a.ARTrans = @artrans  and a.ARLine = l.ARLine
 	where l.Co = @jbco and l.Mth = @batchmth /*@billmth*/ and l.BatchId = @batchid and l.BatchSeq = @seq and l.BatchTransType in ('C','D')
 	end
   
/* get the old misc dist values based on the original artrans */
update bJBBM
set oldDistDate = a.DistDate, oldDescription = a.Description, oldAmount = a.Amount
from bJBBM m with (nolock)
join bARMD a with (nolock) on a.ARCo = @arco and a.Mth = @billmth /*m.Mth*/ and a.ARTrans = @artrans  and a.CustGroup = m.CustGroup and a.MiscDistCode = m.MiscDistCode
where m.JBCo = @jbco and m.Mth = @batchmth /*@billmth*/ and m.BatchId = @batchid and m.BatchSeq = @seq and m.BatchTransType in ('C','D')

Finished:
commit transaction
goto bspexit
   
Error:
if @openbJBITcursor = 1
   	begin
   	close bJBIT_item
   	deallocate bJBIT_item
   	select @openbJBITcursor = 0
   	end

rollback transaction

update bHQBC
set Status = 0, InUseBy = null
where Co = @jbco and Mth = @batchmth and BatchId = @batchid
   
bspexit:
if @openbJBITcursor = 1
   	begin
   	close bJBIT_item
   	deallocate bJBIT_item
   	select @openbJBITcursor = 0
   	end
   
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBARInsert] TO [public]
GO
