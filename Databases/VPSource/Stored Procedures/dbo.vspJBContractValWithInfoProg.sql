SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBContractValWithInfoProg    Script Date:  ******/
CREATE proc [dbo].[vspJBContractValWithInfoProg]
/*******************************************************************************************
* CREATED BY:   TJL 01/30/06 - Issue #28048, 6x Rewrite
* MODIFIED By :	TJL 10/22/07 - Issue #29193, Address Defaults JCCM vs ARCM returned on single field basis
*		GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*		TJL 03/06/08 - Issue #127077, International Addresses
*		TJL 07/18/08 - Issue #129025, Incorrect No Contract error when Customer missing from Contract
*		TJL 10/21/08 - Issue #128538, Allow Progress Bill Header to be saved when Contract Closed and PostToClosed = No
*		TJL 01/05/09 - Issue #120173, Combine Progress and T&M Auto-Initialization
*		TJL 11/18/09 - Issue #136478, Duplicate Key error logging Contract Error in JBCE
*		TJL 12/21/09 - Issue #129894/137089, Max Retainage Enhancement
*  
*               
*
* USAGE:
* 	Validates JC contract 
*	Returns Information
*
*
* INPUT PARAMETERS
*
*
* OUTPUT PARAMETERS
*
*
* RETURN VALUE
*   0         success
*   1         Failure
********************************************************************************************/
(@jbco bCompany = 0, @contract bContract = null,
	@customer bCustomer = null output, @processgroup varchar(20) = null output,
	@dflt_payterms bPayTerms = null output, @billaddress varchar(60) = null output,
	@billaddr2 varchar(60) = null output, @billcity varchar(30) = null output,
	@billstate varchar(4) = null output, @billzip bZip = null output, @billcountry char(2) = null output,
	@appnum int output, @roundopt char(1) output, @dflt_rectype tinyint output,
	@customeraddr bYN = null output, @customerrectype bYN = null output,
	@customerref bDesc = null output, @billtype char(1) output, @contractstatus  tinyint output,
	@reportretgitemyn bYN output, @jbflatbillingamt bDollar output, @origcontractamt bDollar output,
	@currcontractamt bDollar output, @template varchar(10) output, @mincontractitem bContractItem output,
	@billinitopt char(1) output, @maxretgopt char(1) output,
	@msg varchar(60) output)
as
set nocount on

declare @rcode int, @custgroup bGroup, @arco bCompany, @postclosedjobs bYN,
	@custbilladdress varchar(60), @custbilladdr2 varchar(60), @custbillcity varchar(30),
   	@custbillstate varchar(4), @custbillzip bZip, @custbillcountry char(2), @custpayterms bPayTerms,
   	@custrectype tinyint, @contractpayterms bPayTerms, @contractrectype tinyint,
	@postsoftclosedjobs bYN

select @rcode = 0

if @jbco is null
	begin
	select @msg = 'Missing JB Company!', @rcode = 1
	goto bspexit
	end

if @contract is null
	begin
	select @msg = 'Missing Contract!', @rcode = 1
	goto bspexit
	end
   
/* Get JCCO.ARCo and HQCO.CustGroup using this ARCo */
select @arco = j.ARCo, @postclosedjobs = j.PostClosedJobs, @custgroup = h.CustGroup,
		@postsoftclosedjobs = j.PostSoftClosedJobs
from bJCCO j with (nolock)
join bHQCO h with (nolock) on h.HQCo = j.ARCo
where j.JCCo = @jbco
   
/* Get the info from Contract.  In most cases Contract information, when available, takes
   precedence over Customer or AR Company information when setting default values. */
select @msg = Description, @customer = Customer, @processgroup = ProcessGroup,
	@contractpayterms = PayTerms, @contractrectype = RecType,
	@billaddress = BillAddress, @billaddr2 = BillAddress2,
	@billcity = BillCity, @billstate = BillState, @billzip = BillZip, @billcountry = BillCountry,
	@roundopt = RoundOpt, @customerref = CustomerReference,
	@contractstatus = ContractStatus, @reportretgitemyn = ReportRetgItemYN,
	@jbflatbillingamt = JBFlatBillingAmt, @origcontractamt = OrigContractAmt,
	@currcontractamt = ContractAmt, @template = JBTemplate,
	@maxretgopt = MaxRetgOpt
from bJCCM with (nolock)
where JCCo = @jbco and Contract = @contract

/* Contract Validation and returned messages. */
if @@rowcount = 0
	begin
	/* Validation fails, Contract may not be used. */
	select @msg = 'Contract not on file.', @rcode = 1
	goto bspexit
	end

if @contractstatus = 0
	begin
	/* Validation fails, Contract may not be used. */
	select @msg = 'Cannot bill pending contracts.', @rcode = 1
	goto bspexit
	end

if @postsoftclosedjobs = 'N' and @contractstatus = 2
	begin
	---- Contract may not receive further billing.  Bill may only be used to release retainage.
	select @msg = 'Contract is soft-closed.  Billing not allowed.'
	end

if @postclosedjobs = 'N' and @contractstatus = 3
	begin
	---- Contract may not receive further billing.  Bill may only be used to release retainage.
	select @msg = 'Contract is hard-closed.  Billing not allowed.'
	end

/* If we have not exited by now, then Contract is OK to use.  We now must determine
   Default values in the event that the Contract does not contain these values. 
   Get the info from Customer.  Default values (Contract vs Customer) determined later. */
if @customer is not null
	begin
	select @custbilladdress = BillAddress, @custbilladdr2 = BillAddress2,
		@custbillcity = BillCity, @custbillstate = BillState, @custbillzip = BillZip, @custbillcountry = BillCountry,
		@custpayterms = PayTerms, @custrectype = RecType
	from bARCM with (nolock)
	where CustGroup = @custgroup and Customer = @customer
	end

/* Set outputs based upon Contract first, then Customer. */
select @dflt_payterms = isnull(@contractpayterms, @custpayterms), 
	@dflt_rectype = isnull(@contractrectype, @custrectype),
	@billaddress = isnull(@billaddress, @custbilladdress),
	@billaddr2 = isnull(@billaddr2, @custbilladdr2),
	@billcity = isnull(@billcity, @custbillcity),
	@billstate = isnull(@billstate, @custbillstate),
	@billzip = isnull(@billzip, @custbillzip),
	@billcountry = isnull(@billcountry, @custbillcountry)

/* If Default RecType still missing, get from ARCO */
if @dflt_rectype is null
   	begin
	select @dflt_rectype = RecType
	from bARCO with (nolock)
   	where ARCo = @arco
	end

/* Determine BillType.  This is returned to JBTMBills form but not used by JBProgressBillHeader form. */
if exists(select 1 from bJCCI with (nolock) where JCCo = @jbco and Contract = @contract and BillType = 'B')
	begin
   	select @billtype = 'P', @billinitopt = 'X'
   	end
else
   	begin
   	select @billtype = 'P', @billinitopt = 'P'
   	end

/* Increment the application # for this contract.  It gets used as a Default App# on the form. */
select @appnum = isnull(max(Application),0) + 1
from bJBIN with (nolock)
where JBCo = @jbco and Contract = @contract

/* Get Minimum Contract Item for this Contract.  Default for JBTMBills only. */
select @mincontractitem = Min(Item)
from bJCCI with (nolock)
where JCCo = @jbco and Contract = @contract
  
bspexit:
return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspJBContractValWithInfoProg] TO [public]
GO
