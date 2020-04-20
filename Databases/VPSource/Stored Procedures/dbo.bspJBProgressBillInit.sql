SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBProgressBillInit    Script Date: 8/28/99 9:36:45 AM ******/
CREATE proc [dbo].[bspJBProgressBillInit]
   
/***************************************************************************
* CREATED BY: kb 7/16/99
* MODIFIED By : bc 04/19/00 - readded acothrudate
*  		bc 10/09/00 - only reads bills from JCCM that have a DefaultBillType = 'P'.  removed 'B' types as an option.
*  		bc 11/08/00 - removed DefaultBillType from the restriction altogether.
*      	kb 5/22/01 - changed so spin off JCCM for security instead of bJCCM
*    	kb 7/23/1 - issue #13319
*     	kb 9/24/1 - issue #14440
*		kb 7/18/2 - issue #17948 allow missing payterms, no error in JBCE
*		TJL 09/05/02 - Issue #17948, If PayTerms missing then DueDate = InvDate
*		TJL 09/06/02 - Issue #18434, Correct retrieval of BillAddress info from Contract or Customer
*		TJL 03/26/03 - Issue #20041, When initialized by Contract, need contract ProcGroup value
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 03/16/04 - Issue #24031, Call bspJBGetLastInvoice to get default Invoice Numbers
*		TJL 03/17/04 - Issue #18413, Allow Invoice #s greater than 4000000000
*		TJL 04/15/04 - Issue #24191, Send Missing/Invalid Customer error to Contract err.  Rewrite/simplify proc
*									 Corrected ARRecType validation to use ARCo not JBCo
*		TJL 05/04/04 - Issue #18944, Add Invoice Description to JBTMBills and JBProgressBillHeader forms
*		TJL 10/22/07 - Issue #29193, Address Defaults JCCM vs ARCM returned on single field basis
*		GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*		TJL 03/06/08 - Issue #127077, International Addresses
*		TJL 07/24/08 - Issue #128287, JB International Sales Tax
*		TJL 01/05/09 - Issue #120173, Combine Progress and T&M Auto-Initialization
*		TJL 11/18/09 - Issue #136478, Duplicate Key error logging Contract Error in JBCE
*		GF 09/10/2010 - issue #141031 change to use vfDateOnly
*
*
* USAGE: This procedure is called to initialize JB Progress Bills.
*
*
*  INPUT PARAMETERS
*	@co	= Company
*	@mth 	= BillMonth and used to restrict costs in JCIP
* 	@initflag   = initialize by 'P'rocessGroup or 'C'ontract
*	@procgroup	= Progress Process Group
*	@begincont 	= Beginning Contract
*	@endcont 	= Ending Contract
*  	@restrictbyYN	= Restrict by item bill group check box
*	@itembillgroup	= Item Bill Group
*	@invdate 	= Invoice Date
*	@fromdate 	|
*				| identifies the date range the bill covers
*	@thrudate	|
*	@acothrudate	= Through date which all approved invoices will impact the current billing
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
****************************************************************************/
(@co bCompany, @mth bMonth, @contract bContract, @billinitopt char(1), @restrictbyYN bYN, @itembillgroup bBillingGroup = null,
	@invdate bDate, @fromdate bDate = null, @thrudate bDate = null, @acothrudate bDate = null, @assigninv bYN, @invdescription bDesc = null,
	@billnum int output, @contracterrors tinyint output, @msg varchar(255) output)
as

set nocount on
   
/*generic declares */
declare @rcode int, @errmsg varchar(255),
   @invflag char(1), @custgroup bGroup, @customer bCustomer, @taxgroup bGroup,
   @payterms bPayTerms, @origcontract bDollar,
   @billaddress varchar(60), @billaddr2 varchar(60), @billcity varchar(30), @billstate varchar(4), @billzip bZip, 
   @billcountry char(2), @prevwc bDollar, @discdate bDate, @duedate bDate, @discrate bPct, @rectype tinyint,
   @application smallint, @invoice varchar(10), @arglco bCompany,
   @jcglco bCompany, @ARrectype tinyint, @arco bCompany,
   @postclosedjobs bYN, @errordesc varchar(255), @errornumber int,
   @contractRecType tinyint, @contractprocgroup varchar(10),
   @custbilladdress varchar(60), @custbilladdr2 varchar(60), @custbillcity varchar(30), @custbillstate varchar(4),
   @custbillzip bZip, @custbillcountry char(2), @custpayterms bPayTerms, @custrectype tinyint, @invdesc bDesc,
   @postsoftclosedjobs bYN, @customerref bDesc, @invappdesc bDesc, @template varchar(10)

select @rcode=0, @contracterrors = 0, @invoice = null

/* Getting Starting values. */
select @invflag = b.InvoiceOpt, @jcglco = c.GLCo, @arco = c.ARCo, @postclosedjobs = c.PostClosedJobs,
	@arglco = a.GLCo, @ARrectype = a.RecType, @taxgroup = h.TaxGroup, @postsoftclosedjobs = c.PostSoftClosedJobs
from bJBCO b with (nolock) 
join bJCCO c with (nolock) on c.JCCo = b.JBCo
join bARCO a with (nolock) on a.ARCo = c.ARCo
join bHQCO h with (nolock) on h.HQCo = b.JBCo
where b.JBCo = @co
   
/* Validation, required field checks */
if @arglco is null		--@jcglco will never be null in bJCCO
	begin
   	select @msg = 'Invalid (blank) AR Company GLCo. ', @rcode = 1
   	goto bspexit
   	end 
   
select @msg = 'Contract ' + @contract
delete from bJBCE where JBCo = @co and Contract = @contract

select @billnum = isnull(max(BillNumber),0) + 1
from bJBIN with (nolock)
where JBCo = @co and BillMonth = @mth
   
select @application = isnull(max(Application),0) + 1
from bJBIN with (nolock)
where JBCo = @co and Contract = @contract
select @invappdesc = 'JB App# ' + convert(varchar(5), @application)
   
/* Get customer info from JCCM if available there */
select @custgroup = CustGroup, @customer = Customer,
	@payterms = PayTerms, @origcontract = OrigContractAmt,
    @billaddress = BillAddress, @billaddr2 = BillAddress2,
    @billcity = BillCity, @billstate = BillState, @billzip = BillZip, @billcountry = BillCountry,
    @contractRecType = RecType, @contractprocgroup = ProcessGroup,
	@customerref = CustomerReference, @template = JBTemplate
from bJCCM with (nolock)
where JCCo = @co and Contract = @contract
 
select @invdesc = case when @billinitopt in ('P','X') then isnull(@invdescription, @invappdesc)
		else isnull(@invdescription, isnull(@invappdesc, isnull(@customerref,'JB T&M'))) end
  
/* Validation, required field checks, and additional information. */
select @custbilladdress = BillAddress, @custbilladdr2 = BillAddress2,
	@custbillcity = BillCity, @custbillstate = BillState, @custbillzip = BillZip, @custbillcountry = BillCountry,
	@custpayterms = PayTerms, @custrectype = RecType 
from bARCM with (nolock)
where CustGroup = @custgroup and Customer = @customer
if @@rowcount = 0
	begin
	select @errordesc = @msg + ' - Invalid or Missing Customer', @errornumber = 102
	goto Contract_error
	end
   
/* Any values not returned from JCCM, use those from ARCM. */
select @payterms = isnull(@payterms, @custpayterms) , 
	@rectype = isnull(@contractRecType, isnull(@custrectype, @ARrectype)),
	@billaddress = isnull(@billaddress, @custbilladdress),
	@billaddr2 = isnull(@billaddr2, @custbilladdr2),
	@billcity = isnull(@billcity, @custbillcity),
	@billstate = isnull(@billstate, @custbillstate),
	@billzip = isnull(@billzip, @custbillzip),
	@billcountry = isnull(@billcountry, @custbillcountry)

if @rectype is null
	begin
	select @errordesc = @msg + ' - Missing Receivable Type', @errornumber = 104
	goto Contract_error
	end
else
	begin
	exec @rcode = bspARRecTypeVal @arco, @rectype,  @errmsg output
	if @rcode <> 0
		begin
		select @errordesc = @msg + ' - ' + @errmsg, @rcode = 0, @errornumber = 104
		goto Contract_error
		end
	end
   
if @payterms is not null
	begin
  	exec @rcode = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @duedate output, @discrate output, @errmsg output
  	if @rcode <> 0
   		begin
   	   	select @errordesc = @msg + @errmsg, @rcode = 0, @errornumber = 106
   	   	goto Contract_error
   	   	end
	end
   
/* If duedate not set from payterms set duedate to be invoice date. */
if @duedate is null select @duedate = @invdate		--DATEADD(day,30,@invdate)
   
/* Automatically Assign Invoice number from either JBCO or ARCO */
if @assigninv = 'Y'
	begin
	exec @rcode = bspJBGetLastInvoice @co, @invoice output, @errmsg output
	if @rcode <> 0
		begin
		select @msg = @errmsg + char(10) + char(13)
		select @msg = @msg + 'Begin initialization again starting with Contract ' + isnull(@contract,'')
		goto bspexit
		end
	end
   
/* Add JBIN record. */
select @prevwc = 0
insert bJBIN(JBCo,BillMonth,BillNumber,Invoice,Contract,CustGroup, Customer,
	ProcessGroup,BillGroup,InvStatus,ARTrans,Application, RestrictBillGroupYN,
	RecType,PayTerms,InvDate,DueDate,DiscDate,FromDate,ToDate,BillAddress, BillAddress2,
	BillCity,BillState,BillZip,BillCountry,InvTotal,InvRetg,RetgTax,RetgRel,RetgTaxRel,InvDisc,TaxBasis,InvTax,InvDue,PrevAmt,
	PrevRetg,PrevRetgTax,PrevRRel,PrevRetgTaxRel,PrevTax,PrevDue,ARRelRetgTran,ARRelRetgCrTran,ARGLCo,JCGLCo,
	CurrContract,PrevWC,WC,PrevSM,Installed,Purchased,SM,SMRetg,PrevSMRetg,PrevWCRetg,
	WCRetg,PrevChgOrderAdds, PrevChgOrderDeds,ChgOrderAmt,AutoInitYN, BillType, ACOThruDate,
	InvDescription,Template,CreatedBy,CreatedDate,InitOption)
values(@co, @mth, @billnum, @invoice, @contract, @custgroup, @customer,
	@contractprocgroup, @itembillgroup, 'A',  null, @application, @restrictbyYN,
	@rectype, @payterms, @invdate, @duedate, @discdate, @fromdate, @thrudate, @billaddress, @billaddr2,
	@billcity, @billstate, @billzip, @billcountry, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, null, null, @arglco, @jcglco,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 'Y',
	case when @billinitopt in ('P', 'X') then 'P' else 'B' end, 
	@acothrudate, @invdesc, 
	case when @billinitopt in ('B') then @template end,
	----#141031
	SUser_Name(), dbo.vfDateOnly(), @billinitopt)
   
if @@rowcount = 0
	begin
	select @errordesc = 'Error initializing bill.', @rcode = 0, @errornumber = 109
	goto Contract_error
	end

goto bspexit
   
Contract_error:
if not exists(select top 1 1 from bJBCE with (nolock) where JBCo = @co and Contract = @contract and ErrorNumber = @errornumber)  --#136478
	begin
	insert bJBCE (JBCo, Contract, ErrorNumber, ErrorDesc, ErrorDate)
	select @co, @contract, @errornumber, @errordesc, convert(smalldatetime,CURRENT_TIMESTAMP)
	end
select @contracterrors = 1

bspexit:
return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspJBProgressBillInit] TO [public]
GO
