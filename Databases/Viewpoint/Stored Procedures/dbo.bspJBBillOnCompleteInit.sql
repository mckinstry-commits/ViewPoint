SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBBillOnCompleteInit]
   
/****************************************************************************
* CREATED BY:   bc 10/29/99
* MODIFIED By : bc 04/11/00
* 		kb 7/23/01 - issue #13444
*		kb 9/24/01 - issue #14440
*		kb 11/15/01 - issue #15240
*		kb 12/5/01 - issue #15240
*		TJL 04/28/05 - Issue #28551, Correct retrieval of BillAddress info from Contract or Customer 
*		TJL 04/27/06 - Issue #28184, Removed (begin transaction, rollback transaction, commit transaction)
*		TJL 11/29/07 - Issue #126321, TaxAmount not getting calculated correctly on each item
*		TJL 11/30/07 - Issue #29193, Address Defaults JCCM vs ARCM returned on single field basis
*		TJL 01/16/08 - Issue #126711, TaxAmount on Items incorrect when Previous Bills exist.
*		TJL 03/06/08 - Issue #127077, International Addresses
*		TJL 07/24/08 - Issue #128287, JB International Sales Tax
*		TJL 10/16/09 - Issue #136148, Bill On Complete fails.  InitOpt value needed and missing since combining T&M and Prog Init (Issue #120173)
*		TJL 12/08/09 - Issue #136938, Add CreatedBy, CreatedDate to JBIN when Completed bill gets initialized
*
* USAGE: This procedure is called to initialize JB Progress Bills that are marked to be billed on completion.
*
*
*  INPUT PARAMETERS
*	@jbco	= Company
*	@billmth 	= BillMonth
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*   3         no errors, no update
****************************************************************************/
(@jbco bCompany, @billmth bMonth, @contracterrors tinyint output, @msg varchar(255) output)
as

set nocount on
   
/*generic declares */
declare @rcode int, @errmsg varchar(255), @opencursor tinyint, @update bYN,
	@contract bContract, @item bContractItem, @invdate bDate, @invflag char(1), @custgroup bGroup, @customer bCustomer, 
	@taxgroup bGroup, @taxcode bTaxCode, @payterms bPayTerms, 
	@billaddress varchar(60), @billaddress2 varchar(60), @billcity varchar(30), @billstate varchar(4), @billzip bZip,
	@billcountry char(2), @discdate bDate, @duedate bDate, @taxrate bRate, @discrate bPct, @rectype tinyint, @invtot bDollar,
	@application smallint, @billnum int, @invoice varchar(10), @invoice_num bigint, @arglco bCompany,
	@jcglco bCompany, @ARrectype tinyint, @ARlastinv bigint, @arco bCompany,
	@errornumber int, @errordesc varchar(255), @contractRecType tinyint,
	@custbilladdress varchar(60), @custbilladdr2 varchar(60), @custbillcity varchar(30), @custbillstate varchar(4),
	@custbillzip bZip, @custbillcountry char(2), @custpayterms bPayTerms, @custrectype tinyint, @openitemcursor tinyint,
	--International Sales Tax
	@arcoinvoicetaxyn bYN, @arcotaxretgyn bYN, @arcosepretgtaxyn bYN,
	@amtbilled bDollar, @wc bDollar, @installed bDollar, @wcretg bDollar, @taxbasis bDollar, @taxamount bDollar,
	@retg bDollar, @retgbilled bDollar, @retgtax bDollar, @amountdue bDollar, @unitsbilled bUnits, @wcunits bUnits

select @rcode = 0, @update = 'N', @contracterrors = 0, @openitemcursor = 0

/* extract the month, date and year values from getdate and insert into invdate to ensure that the time is defaulted to 12:00 am on all bills */
select @invdate = convert(varchar(2),datepart(mm,getdate())) + '/' + convert(varchar(2),datepart(dd,getdate())) + '/' + convert(varchar(4),datepart(yy,getdate()))

/* Get additional information */
select @invflag = b.InvoiceOpt, @jcglco = c.GLCo, @arco = c.ARCo,
	@arglco = a.GLCo, @ARrectype = a.RecType, @ARlastinv = a.InvLastNum,
	@arcoinvoicetaxyn = a.InvoiceTax, @arcotaxretgyn = a.TaxRetg, 
	@arcosepretgtaxyn = a.SeparateRetgTax, @taxgroup = h.TaxGroup
from bJBCO b with (nolock)
join bJCCO c with (nolock) on c.JCCo = b.JBCo
join bARCO a with (nolock) on a.ARCo = c.ARCo
join bHQCO h with (nolock) on h.HQCo = b.JBCo
where b.JBCo = @jbco

/* declare cursor on JCCM */
declare bcJCCM cursor for
select Contract,CustGroup,Customer,PayTerms,BillAddress,BillCity,BillState,BillZip,
	BillCountry, BillAddress2, ContractAmt, RecType
from bJCCM with (nolock)
where JCCo = @jbco and BillOnCompletionYN = 'Y' and CompleteYN = 'Y' and ContractStatus = 1 and
	(DefaultBillType = 'P' or DefaultBillType = 'B') and
	not exists(select * from bJBIN where JBCo = @jbco and bJBIN.Contract = bJCCM.Contract and bJBIN.BillOnCompleteYN = 'Y')
order by Contract
   
/* open cursor */
open bcJCCM
select @opencursor = 1

fetch next from bcJCCM into @contract, @custgroup, @customer, @payterms, @billaddress, @billcity, @billstate, @billzip,
	@billcountry, @billaddress2, @invtot, @contractRecType

while @@fetch_status = 0
	begin	/* Begin Contract Processing Loop */
	delete from bJBCE where JBCo = @jbco and Contract = @contract

	select @application = 0

	/* Retrieve Customer information */
	select @custpayterms = PayTerms, @custrectype = RecType,
		@custbilladdress = BillAddress,	@custbilladdr2 = BillAddress2,					
		@custbillcity = BillCity, @custbillstate = BillState, @custbillzip = BillZip,
		@custbillcountry = BillCountry
	from bARCM with (nolock)
	where CustGroup = @custgroup and Customer = @customer
	if @@rowcount = 0
		begin
 		select @errordesc = isnull(@msg,'') + ' - Invalid Customer', @errornumber = 102
 		goto jb_posting_error
 		end

	/* Any values not returned from JCCM, use those from ARCM. */
	select @payterms = isnull(@payterms, @custpayterms) , 
   		@rectype = isnull(@contractRecType, isnull(@custrectype, @ARrectype)),
		@billaddress = isnull(@billaddress, @custbilladdress),
		@billaddress2 = isnull(@billaddress2, @custbilladdr2),
		@billcity = isnull(@billcity, @custbillcity),
		@billstate = isnull(@billstate, @custbillstate),
		@billzip = isnull(@billzip, @custbillzip),
		@billcountry = isnull(@billcountry, @custbillcountry)

	if @payterms is null
		begin
		select @errordesc = isnull(@msg,'') + ' - Missing Payment Terms', @errornumber = 103
		goto jb_posting_error
		end
	  
	if @rectype is null
		begin
		select @errordesc = isnull(@msg,'') + ' - Missing Receivable Type', @errornumber = 104
		goto jb_posting_error
		end

	exec @rcode = bspARRecTypeVal @jbco, @rectype, @errmsg output
	if @rcode <> 0
		begin
		select @errordesc = isnull(@msg,'') + isnull(@errmsg,''), @errornumber = 105, @rcode = 0
		goto jb_posting_error
		end

	exec @rcode = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @duedate output, @discrate output, @errmsg output
	if @rcode <> 0
		begin
		select @errordesc = isnull(@msg,'') + isnull(@errmsg,''), @errornumber = 106, @rcode = 0
		goto jb_posting_error
		end

	/*if duedate not set from payterms set duedate to be invoice date plus 30 days, works like AR*/
	if @duedate is null select @duedate = DATEADD(day,30,@invdate)

	if @invflag = 'A'
		begin
		select @invoice = isnull(InvLastNum,0) from bARCO where ARCo = @arco
		end
	else
		begin
		select @invoice = isnull(LastInvoice,0) from bJBCO where JBCo = @jbco
		end

	if isnumeric(@invoice) >= 0
		begin
		select @invoice_num = @invoice
		end
	else
		begin
		select @invoice = null
		goto AddRec
		end

invloop:
	/* check if the invoice is already in use */
	select @invoice_num = @invoice_num + 1
	select @invoice = convert(varchar(10),@invoice_num)

	-- invoice should be right justified 10 chars */
	select @invoice = space(10 - datalength(@invoice)) + @invoice

	if exists(select * from bARTH where ARCo=@arco and Invoice=@invoice) or
		exists(select * from bARBH where Co=@arco and Invoice=@invoice) or
		exists(select * from bJBAR where Co=@jbco and Invoice=@invoice) or
		exists(select * from bJBIN where JBCo=@jbco and Invoice=@invoice)
			begin
			goto invloop
			end

	if @invflag = 'A'
		begin
		update bARCO set InvLastNum = @invoice where ARCo = @arco
		end
	else
		begin
		update bJBCO set LastInvoice = @invoice where JBCo = @jbco
		end

AddRec:
	select @billnum = isnull(max(BillNumber),0)+1
	from bJBIN with (nolock)
	where JBCo = @jbco and BillMonth = @billmth

	select @application = isnull(max(Application),0) + 1
	from bJBIN with (nolock)
	where JBCo = @jbco and Contract = @contract and ((BillMonth < @billmth) or (BillMonth = @billmth and BillNumber < @billnum))

	insert bJBIN(JBCo,BillMonth,BillNumber,Invoice,Contract,CustGroup, Customer,
		InvStatus,ARTrans,Application,RestrictBillGroupYN,
		RecType,PayTerms,InvDate,DueDate,DiscDate,BillAddress,BillAddress2,
		BillCity,BillState,BillZip,BillCountry,InvTotal,InvRetg,RetgTax,RetgRel,RetgTaxRel,
		InvDisc,TaxBasis,InvTax,InvDue,PrevAmt,PrevRetg,PrevRetgTax,PrevRRel,PrevRetgTaxRel,
		PrevTax,PrevDue,ARRelRetgTran,ARRelRetgCrTran,ARGLCo,JCGLCo,
 		CurrContract,PrevWC,WC,PrevSM,Installed,Purchased,SM,SMRetg,PrevSMRetg,PrevWCRetg,
 		WCRetg,PrevChgOrderAdds, PrevChgOrderDeds,ChgOrderAmt,AutoInitYN,BillOnCompleteYN, InitOption,
 		CreatedBy, CreatedDate)
	values(@jbco, @billmth, @billnum, @invoice, @contract, @custgroup, @customer,
 		'A', null, @application, 'N',
 		@rectype, @payterms, @invdate, @duedate, @discdate, @billaddress,@billaddress2,
 		@billcity, @billstate, @billzip, @billcountry, 0/*@invtot*/, 0, 0, 0, 0, 
		0, 0, 0, 0, 0, 0, 0, 0, 0, 
		0, 0, null, null, @arglco, @jcglco,
  		0/*@invtot*/, 0, 0 /*@invtot*/, 0, 0, 0, 0, 0, 0, 0,
  		0, 0, 0, 0,'N','Y','X',
  		SUSER_SNAME(), @invdate)	
	if @@rowcount = 0
		begin
		/* if a trigger or the server catches a problem, set rcode = 1 so the form knows how to react.
			  a message won't be neccessary here */
		select @errordesc = 'Error adding bill header', @errornumber = 109
		goto jb_posting_error
		end

	if @update = 'N' select @update = 'Y'
	   
	/* For each Contract being processed, a JBIN record gets inserted above.  The JBIN insert trigger will 
	   initialize all Contract Items to 0.00 value.  Because we might be initializing many Contracts and 
	   because Tax Amounts are dependent upon the TaxCode at the Item level, we will attempt to be a
	   bit more efficient by processing tax amount for only those Items containing a TaxCode.  This might
	   help reduce the Cursor list some.  Later we will process the remaining Items using mass update
	   statements.

	   This concept is kind of legacy code and I am not sure if it really is more efficient or not. */
	declare bcItem cursor local fast_forward for
	select Item, TaxGroup, TaxCode
	from bJBIT with (nolock)
	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and TaxCode is not null

	open bcItem
	select @openitemcursor = 1
	  
	fetch next from bcItem into @item, @taxgroup, @taxcode
	while @@fetch_status = 0
		begin	/* Begin Item Loop for TaxRate/TaxAmount */

		/* Initialize working variables */
		select @amtbilled = 0, @wc = 0, @installed = 0, @wcretg = 0, @taxbasis = 0, @taxamount = 0,
			@retg = 0, @retgbilled = 0, @retgtax = 0, @amountdue = 0, @unitsbilled = 0, @wcunits = 0

		exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @invdate,
			@taxrate output, null, null, @errmsg output
		if @rcode <> 0
			begin
			select @msg = 'Error initializing bill. - '
			select @errordesc = isnull(@msg,'') + isnull(@errmsg,''), @errornumber = 109, @rcode = 0
			if @openitemcursor = 1
				begin
				close bcItem
				deallocate bcItem
				select @openitemcursor = 0
				end 
			goto jb_posting_error
			end

		select @amtbilled = t.CurrContract - t.PrevAmt,				--PrevAmt includes both SM and WC.  AmtBilled is the Net when both (PrevWC + PrevSM) are subtracted.
			@wc = t.CurrContract - t.PrevWC,						--Net Work Complete (Can be > AmtBilled when PrevSM is being installed now!)
			@installed = (t.CurrContract - t.PrevWC) - (t.CurrContract - t.PrevAmt),	--The difference is PrevSM that now needs to be installed
			@unitsbilled = t.ContractUnits - t.PrevUnits,			--PrevUnits is only WC units.  There are no SM units
			@wcunits = t.ContractUnits - t.PrevWCUnits,				--Since there are no SM units, this is same as UnitsBilled
			@wcretg = (t.CurrContract - t.PrevWC) * i.RetainPCT,	--Net WC Retg (Can be > RetgBilled when PrevSM is being installed now!)
			@retg = (t.CurrContract - t.PrevAmt) * i.RetainPCT
		from bJBIT t with (nolock)
		join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
		join bJCCI i with (nolock) on i.JCCo = n.JBCo and i.Contract = n.Contract and i.Item = t.Item
		where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnum and t.Item = @item

		/* Bill 100% of remaining amounts. */
		if @taxcode is null or @arcoinvoicetaxyn = 'N' 
			begin
			/* Either No TaxCode on this Item or AR Company is set to No Tax on Invoice/Bills */
			select @taxbasis = 0
			select @taxamount = 0
			select @retgtax = 0
			select @retgbilled = @retg
			end
		else
			begin
			/* TaxCode does exist and AR Company is set for Tax on Invoice/Bills */
			if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'
				begin
				/* Standard US */
				select @taxbasis = @amtbilled				
				select @taxamount = @taxbasis * @taxrate	
				select @retgtax = 0
				select @retgbilled = @retg
				end
			if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
				begin
				/* International with RetgTax */
				select @taxbasis = @amtbilled - @retg	
				select @taxamount = @taxbasis * @taxrate
				select @retgtax = @retg * @taxrate
				select @retgbilled = @retg + @retgtax
				end
			if @arcotaxretgyn = 'N'
				begin
				/* International no RetgTax */
				select @taxbasis = @amtbilled - @retg
				select @taxamount = @taxbasis * @taxrate
				select @retgtax = 0
				select @retgbilled = @retg
				end			
			end

		update bJBIT
		set AmtBilled = @amtbilled,	WC = @wc, Installed = @installed, UnitsBilled = @unitsbilled,
			WCUnits = @wcunits,	WCRetg = @wcretg, TaxBasis = @taxbasis,	TaxAmount = @taxamount, 
			RetgTax = @retgtax, RetgBilled = @retgbilled, AmountDue = @amtbilled - @retg + @taxamount
		where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Item = @item

		fetch next from bcItem into @item, @taxgroup, @taxcode
		end		/* End Item Loop for TaxRate/TaxAmount */

	if @openitemcursor = 1
		begin
		close bcItem
		deallocate bcItem
		select @openitemcursor = 0
		end 

	/* Initialize remaining Item values using mass update statements.  Hopefully the result
	   is that the process is a little quicker then if these Non-Tax Items were processed using
	   the Item cursor above. */
	/* Update this bill's wc and wc units */
	update bJBIT
	set WC = t.CurrContract - t.PrevWC, WCUnits = t.ContractUnits - t.PrevWCUnits,
		AmtBilled = t.CurrContract - t.PrevAmt, UnitsBilled = t.ContractUnits - PrevUnits,
		Installed = (t.CurrContract - t.PrevWC) - (t.CurrContract - t.PrevAmt)
	from bJBIT t with (nolock)
	join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
	where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnum
		and t.TaxCode is null

	/* Update this bill's retainage */
	update bJBIT
	set WCRetg = t.WC * i.RetainPCT, RetgBilled = t.AmtBilled * i.RetainPCT		--There is No RetgTax for these Items
	from bJBIT t with (nolock)
	join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
	join bJCCI i with (nolock) on i.JCCo = n.JBCo and i.Contract = n.Contract and i.Item = t.Item
	where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnum
		and t.TaxCode is null

	/* Update this bill's amount due */
	update bJBIT
	set  AmountDue = t.AmtBilled - t.RetgBilled 		--Again there is no TaxAmount or RetgTax on these Items
	from bJBIT t with (nolock)
	join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
	where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnum
		and t.TaxCode is null

jb_posting_loop:
	fetch next from bcJCCM into @contract, @custgroup, @customer, @payterms, @billaddress, @billcity, @billstate, @billzip,
		@billcountry, @billaddress2, @invtot, @contractRecType
	end		/* End Contract Processing Loop */

/* Contract Processing Loop is finished.  Skip over JBCE error routine. */
goto bspexit

/* Any number of failures could have occured while processing a specific Contract.
   Each will bring us here to post an Error into JB Contract Error table.  After
   doing so, process will resume by retrieving the next Contract for processing. */
jb_posting_error:
	insert bJBCE (JBCo, Contract, ErrorNumber, ErrorDesc, ErrorDate)
	select @jbco, @contract, @errornumber, @errordesc, getdate()
	select @contracterrors = 1
	goto jb_posting_loop
   
bspexit:
if @openitemcursor = 1
	begin
	close bcItem
	deallocate bcItem
	select @openitemcursor = 0
	end 
if @opencursor = 1
	begin
	close bcJCCM
	deallocate bcJCCM
	select @opencursor = 0
	end
   
if @rcode = 0 and @update = 'N' select @rcode = 3
   
return @rcode





GO
GRANT EXECUTE ON  [dbo].[bspJBBillOnCompleteInit] TO [public]
GO
