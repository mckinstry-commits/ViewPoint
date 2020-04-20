SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[bspJBARCustomerValWithInfo]
/***********************************************************
* CREATED BY: kb 1/15/2
* MODIFIED By : kb 1/23/2 - issue #15854
*		CMW 07/30/02 fixed extra info lookups.
*		TJL 09/16/02 - Issue #17887, Get PayTerms for Non-Contract Bills. Make more
*						consistent with bspJBTandMInit and bspJBProgressInit
*		TJL 10/09/02 - Issue #18757, If JCCM and ARCM.RecType is NULL get from JCCO.ARCo
*		TJL 09/25/03 - Issue #22352, Pass back Customer.Status for Customer_StdBidtekFormValidation
*						ReWrite for better efficiency.
*		TJL 10/22/07 - Issue #29193, Address Defaults JCCM vs ARCM returned on single field basis
*		TJL 03/06/08 - Issue #127077, International Addresses
*
* USAGE:
* 	Validates Customer
*
* INPUT PARAMETERS
*   Company	Company
*   CustGroup	Customer Group
*   Customer	Customer to validate
*
* OUTPUT PARAMETERS
*   @msg      		error message if error occurs, or ARCM.Name
* RETURN VALUE
*   0	Success
*   1	Failure
*****************************************************/
(@JCCo bCompany, @Contract bContract = null, @CustGroup bGroup = null, @Customer bSortName = null,
	@custoutput bCustomer = null output, @billaddress varchar(60) output, @billaddr2 varchar(60) output,
	@billcity varchar(30) output, @billstate varchar(4) output,@billzip bZip output, @billcountry char(2) output,
	@dflt_rectype tinyint output, @dflt_payterms bPayTerms output, @custstatus char(1) output, 
	@msg varchar(60) = null output)
   
as
set nocount on

declare @rcode int, @contractpayterms bPayTerms, @contractrectype tinyint,
	@custbilladdress varchar(60), @custbilladdr2 varchar(60), @custbillcity varchar(30),
	@custbillstate varchar(4), @custbillzip bZip, @custbillcountry char(2), @custpayterms bPayTerms,
	@custrectype tinyint
   
exec @rcode =  bspARCustomerVal @CustGroup, @Customer, null, @custoutput output,
    @msg output
if @rcode = 1 goto bspexit
   
/* Get the info from Contract.  In most cases Contract information, when available, takes
   precedence over Customer or AR Company information when setting default values. */
select @contractpayterms = PayTerms, @contractrectype = RecType,
	@billaddress = BillAddress, @billaddr2 = BillAddress2,
	@billcity = BillCity, @billstate = BillState, @billzip = BillZip, @billcountry = BillCountry
from bJCCM with (nolock)
where JCCo = @JCCo and Contract = @Contract
   
/* Get the info from Customer.  Default values (Contract vs Customer) determined later. */
select @custbilladdress = BillAddress, @custbilladdr2 = BillAddress2,
	@custbillcity = BillCity, @custbillstate = BillState, @custbillzip = BillZip, @custbillcountry = BillCountry,
	@custpayterms = PayTerms, @custrectype = RecType, @custstatus = Status
from bARCM with (nolock)
where CustGroup = @CustGroup and Customer = @custoutput

/* Any values not returned from JCCM, use those from ARCM. */
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
   	join bJCCO with (nolock) on bJCCO.ARCo = bARCO.ARCo
   	where bJCCO.JCCo = @JCCo
	end
   	
bspexit:
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBARCustomerValWithInfo] TO [public]
GO
