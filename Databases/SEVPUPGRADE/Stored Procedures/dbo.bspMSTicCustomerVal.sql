SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROC [dbo].[bspMSTicCustomerVal]
/***********************************************************
 * Created By:  GF 09/01/2000
 * Modified By: GG 01/24/01 - initialized output parameters to null
 *				GF 07/19/2004 - #24991 - added status to output parameters
 *
 * USAGE:   Validate customer entered in MS TicEntry
 *
 *
 * INPUT PARAMETERS
 *  @arco       AR Company
 *  @custgroup  Customer Group
 *  @customer   Customer sort name or number
 *
 * OUTPUT PARAMETERS
 *  @customeroutput     Customer number
 *  @payterms           Customer Pay Terms
 *  @matldisc           Material Discount YN flag from Payment Terms
 *  @discrate           Payment discount rate from HQPT
 *  @creditlimit        Customer Credit Limit
 *  @balance            Customer's current Balance (= Invoiced - Retainage - Paid amount - Discount taken)
 *  @rectype            Receivable type
 *  @prntlvl            Customer's default MS Invoice Print level
 *  @subtotallvl        Customer's default MS Invoice Subtotal level
 *  @sephaul            Customer's default MS Invoice Separate Haul flag
 *  @msg                Customer Name or error message if error occurs
 *
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *****************************************************/
(@arco bCompany = null, @custgroup tinyint = null, @customer bSortName = null,
 @customeroutput bCustomer = null output, @payterms bPayTerms = null output, @matldisc bYN = null output,
 @discrate bUnitCost = null output, @creditlimit bDollar = null output, @balance bDollar = null output,
 @rectype int = null output, @printlvl char(1) = null output, @subtotallvl char(1) = null output,
 @sephaul bYN = null output, @status char(1) = null output, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @retcode int, @retmsg varchar(255)

select @rcode = 0, @retcode = 0

if @arco is null
	begin
   	select @msg = 'Missing Company!', @rcode = 1
   	goto bspexit
   	end

if @custgroup is null
	begin
   	select @msg = 'Missing Customer Group!', @rcode = 1
   	goto bspexit
   	end

if @customer is null
   	begin
   	select @msg = 'Missing Customer!', @rcode = 1
   	goto bspexit
   	end

exec @rcode =  bspARCustomerVal @custgroup, @customer, 'U', @customeroutput output, @msg output
if @rcode = 1 goto bspexit
   
---- get customer information
select @status=Status, @msg=Name, @payterms=PayTerms, @creditlimit=CreditLimit, @rectype=RecType,
          @printlvl=PrintLvl, @subtotallvl=SubtotalLvl, @sephaul=SepHaul
from dbo.ARCM with (nolock) where CustGroup=@custgroup and Customer=@customeroutput

---- get current balance = (Invoiced - Retainage - Paid amount - Discount taken)
select @balance = 0
select @balance =(isnull(sum(Invoiced),0)-isnull(sum (Retainage),0)-isnull(sum(Paid),0)-isnull(sum(DiscountTaken),0))
from dbo.ARMT with (nolock) where ARCo=@arco and CustGroup=@custgroup and Customer=@customeroutput
group by ARCo,CustGroup,Customer

---- now get discount info from HQPT
if @payterms is not null
	begin
	select @matldisc=MatlDisc, @discrate=DiscRate
	from dbo.HQPT with (nolock) where PayTerms=@payterms
	end



 bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicCustomerVal] TO [public]
GO
