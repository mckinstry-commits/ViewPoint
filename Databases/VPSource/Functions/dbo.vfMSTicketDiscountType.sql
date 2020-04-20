SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfMSTicketDiscountType]
(@msco bCompany = null, @custgroup bGroup = null, @customer bCustomer = null, @custjob varchar(20) = null,
 @custpo varchar(20) = null, @matlgroup bGroup = null, @material bMatl = null)
returns varchar(1)
/***********************************************************
* Created By:	GF 07/01/2007
* Modified By:	
*
* retrive discount type
*
* Pass:
* @custgroup		Customer Group
* @customer			Customer
* @payterms			Pay Terms
* @matlgroup		Material Group
* @material			Material
*
*
*
*
* OUTPUT PARAMETERS:
* Discount Type
*
*****************************************************/
as
begin

declare @rcode int, @discount_type varchar(1), @matldisc bYN, @msqh_payterms bPayTerms,
		@arcm_payterms bPayTerms, @payterms bPayTerms

select @rcode = 0, @discount_type = 'N', @matldisc = 'N'

---- exit function if missing key values
if @msco is null goto exitfunction
if @custgroup is null goto exitfunction
if @customer is null goto exitfunction
if @matlgroup is null goto exitfunction
if @material is null goto exitfunction


---- look in ARCM first
select @arcm_payterms=PayTerms
from dbo.ARCM with (nolock) where CustGroup=@custgroup and Customer=@customer
---- look for quote overrides - Customer, CustJob, CustPO
select @msqh_payterms=PayTerms
from dbo.MSQH with (nolock) 
where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
and isnull(CustJob,'')=isnull(@custjob,'') and isnull(CustPO,'')=isnull(@custpo,'') and Active='Y'
if @@rowcount = 0
	begin
	---- look for quote overrides - Customer, CustJob
	select @msqh_payterms=PayTerms
	from bMSQH with (nolock) 
	where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
	and isnull(CustJob,'')=isnull(@custjob,'') and CustPO is null and Active='Y'
	if @@rowcount = 0
		begin
		---- look for quote overrides - Customer
		select @msqh_payterms=PayTerms
		from bMSQH with (nolock) 
		where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
		and CustJob is null and CustPO is null and Active='Y'
		end
	end

---- set payterms based on AR or MS
select @payterms = isnull(@msqh_payterms, @arcm_payterms)
if @payterms is null
	begin
	select @discount_type = 'N'
	goto exitfunction
	end

---- now get material discount flag from HQPT
select @matldisc=MatlDisc
from dbo.HQPT with (nolock) where PayTerms=@payterms
if @@rowcount = 0 select @matldisc = 'N'

---- get discount type from HQMT
select @discount_type=PayDiscType
from dbo.HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0
	begin
	select @discount_type = 'N'
	goto exitfunction
	end

---- if HQPT.MatlDisc <> 'Y' then set discount type to (R)ate
if isnull(@matldisc,'N') <> 'Y'
	begin
	select @discount_type = 'R'
	goto exitfunction
	end






exitfunction:
	return @discount_type
end

GO
GRANT EXECUTE ON  [dbo].[vfMSTicketDiscountType] TO [public]
GO
