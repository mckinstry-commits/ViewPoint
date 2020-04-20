SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[bspARCustomerValWithInfo]
/***********************************************************
* CREATED BY: CJW 5/9/97
* MODIFIED By : JM 5/23/97
*		JM 1/9/97 - Added output of ARCM.MiscDistCode by CustGrp/Customer
*				Added output of ARMC.Description by CustGrp/ARCM.MiscDistCode
		JM 3/9/99 - Added select for RecType against bARCO if it is not found in bARCM.
*		GR 11/11/99 issue 5447 - Added an output parameter Finance Charge
*				Receivable Type to default in ARFinCharges based on Company
*				from AR Company, if Fin Chg Rec.Type is null then defaults
*				to recivable type from ARCO
*		bc 01/11/00 removed UseRetg
*		GF 06/18/2003 - issue #21568 - deadlocks occuring when posting MS Invoice Batch. Added (nolocks)
*		TJL 10/25/07 - Issue #27178, Return Customer Billing Address (Concatenated).
*		TJL 03/06/08 - Issue #127077, International Addresses
*		TJL 07/24/09 - Issue #130964, Auto generate Misc Distributions based on AR Customer setup.
*			
*
* USAGE:
* 	Validates Customer
*	Returns Name, Phone, Contact for Customer
* 	Returns Customer's current Balance (= Invoiced - Retainage - Paid amount - Discount taken)
*	Returns DaysTillDisc and DaysTillDue from HQPT for ARCM.PayTerms , DiscAmount
*
* INPUT PARAMETERS
*   Company		ARCo Company
*   CustGroup	Customer Group
*   Customer	Customer to validate
*
* OUTPUT PARAMETERS
*   @Phone		ARCM.Phone
*   @Contact		ARCM.Contact
*   @balance		ARMT.Invoiced - ARMT.Retainage - ARMT.Paid - ARMT.DiscountTaken
*   @daysuntildisc	HQPT.DaysTillDisc for ARCM.PayTerms
*   @daysuntildue	HQPT.DaysTillDue for ARCM.PayTerms
*   @creditlimit	ARCM.CreditLimit
*   @taxcode		ARCM.TaxCode
*   @custoutput	An output of bspARCustomerVal
*   @discamount	ARCM.MarkupDiscPct
*   @rectype		ARCM.RecType
*   @payterms		ARCM.PAYTERMS
*   @miscdistcode	ARCM.MiscDistCode
*   @miscdistcodedesc  ARMC.Description
*   @msg      		error message if error occurs, or ARCM.Name
* RETURN VALUE
*   0	Success
*   1	Failure
*****************************************************/
(@Company bCompany,
	@CustGroup bGroup = null,
	@Customer bSortName = null,
	@Phone bPhone = null output,
	@Contact varchar(30) = null output,
	@balance bDollar = null output,
	@daysuntildisc int = null output,
	@daysuntildue int = null output,
	@creditlimit bDollar = null output,
	@taxcode varchar(10) = null output,
	@custoutput bCustomer = null output,
	@discamount bPct = null output,
	@rectype int = null output,
	@payterms bPayTerms = null output,
	@finchgpct bPct = null output,
	@finchgtype varchar(1) = null output,
	@miscdistcode char(10) = null output,
	@miscdistcodedesc bDesc = null output,
	@status char(1) = null output,
	@fcrectype int = null output,
	@custbilladdress varchar(255) = null output,
	@miscdistonpayyn bYN = null output,
	@msg varchar(255) = null output)
     
as
set nocount on

declare @rcode int, @option char(1), @arcorectype int,
	@billaddress varchar(60), @billcity varchar(30), @billstate varchar(4), @billzip bZip, 
	@billcountry char(2), @billaddress2 varchar(60)

select @rcode = 0, @option = null, @custbilladdress = ''
   
if @Company is null
	begin
	select @msg = 'Missing Company!', @rcode = 1
	goto bspexit
	end
if @CustGroup is null
	begin
	select @msg = 'Missing Customer Group!', @rcode = 1
	goto bspexit
	end
if @Customer is null
	begin
	select @msg = 'Missing Customer!', @rcode = 1
	goto bspexit
	end
   
exec @rcode =  bspARCustomerVal @CustGroup, @Customer, @option, @custoutput output, @msg output
if @rcode = 1 goto bspexit
   
-- Get current Balance = (Invoiced - Retainage - Paid amount - Discount taken)
select @balance = 0
select @balance =(isnull(sum(Invoiced),0) - isnull(sum (Retainage),0) - isnull(sum(Paid),0))
from bARMT with (nolock)
where ARCo = @Company and CustGroup = @CustGroup and Customer = @custoutput
group by ARCo, CustGroup, Customer
   
-- Need to get other customer info
select  @rectype = a.RecType, @taxcode = a.TaxCode,	@creditlimit = a.CreditLimit,
  	@Phone = a.Phone, @Contact = a.Contact,	@discamount=a.MarkupDiscPct, @msg = a.Name,
  	@payterms = a.PayTerms,	@finchgpct = a.FCPct, @finchgtype = a.FCType, @status = a.Status,
	@miscdistcode = a.MiscDistCode, @miscdistcodedesc = m.Description, @miscdistonpayyn = MiscOnPay,
	@billaddress = a.BillAddress, @billcity = a.BillCity, @billstate = a.BillState,
	@billzip = a.BillZip, @billcountry = a.BillCountry, @billaddress2 = a.BillAddress2
from ARCM a with (nolock)
left join ARMC m with (nolock) on m.CustGroup = a.CustGroup and m.MiscDistCode = a.MiscDistCode
where a.CustGroup = @CustGroup and a.Customer = @custoutput

-- Concatenate the entire Customer Billing Address into single string value
if @billaddress is not null or @billcity is not null or @billstate is not null or @billzip is not null or @billcountry is not null
	or @billaddress2 is not null
	begin
	select @custbilladdress = isnull(@billaddress, '') + ',     ' + isnull(@billcity, '') + ',  ' + isnull(@billstate, '') + '  ' 
		+ isnull(@billzip, '') 	+ '  ' + isnull(@billcountry, '') + char(13) + char(10) + isnull(@billaddress2, '')
	end

-- Get payterms info from HQPT
if isnull(@payterms,'') <> ''
select @daysuntildisc=DaysTillDisc, @daysuntildue=DaysTillDue
from HQPT with (nolock) where PayTerms=@payterms
   
-- Get receivable type and finance charge receivable type from ARCO
select @arcorectype=RecType, @fcrectype=FCRecType
from bARCO with (nolock) 
where ARCo = @Company
   
-- If RecType not found in ARCM, use ARCO receivable type
if @rectype is null select @rectype = @arcorectype
     
-- Get finance charge receivable type for this company. if FC RecType is null then default
-- FC RecType from Customer Master else from ARCo
if @fcrectype is null select @fcrectype=@rectype
   
bspexit:
if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspARCustomerValWithInfo]'
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspARCustomerValWithInfo] TO [public]
GO
