SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfJBGetARCustBillAddress]
(@jbco bCompany = null, @custgroup bGroup = null, @customer bCustomer = null)

returns varchar(255)
/***********************************************************
* CREATED BY:  TJL 10/24/07 - Issue #27178, Return Customer Billing Address to label
* MODIFIED BY:  TJL 03/06/08 - Issue #127077, International Addresses
*
* USAGE:
* 	Returns Customer Master Billing Address to be displayed
*	in label on forms JBContractInfo, JCCM, and PM Contract
*
* INPUT PARAMETERS:
*	@jbco
*	@custgroup
*	@customer  
*	
*	
*
* OUTPUT PARAMETERS:
*	@custbilladdress
*	
*
*****************************************************/
as
begin

declare @custbilladdress varchar(255), @billaddress varchar(60), @billcity varchar(30), @billstate varchar(4), @billzip bZip, 
	@billcountry char(2), @billaddress2 varchar(60)

select @custbilladdress = ''

select @billaddress = BillAddress, @billcity = BillCity, @billstate = BillState,
	@billzip = BillZip, @billcountry = BillCountry, @billaddress2 = BillAddress2
from bARCM with (nolock)
where CustGroup = @custgroup and Customer = @customer

if @billaddress is not null or @billcity is not null or @billstate is not null or @billzip is not null or @billcountry is not null
	or @billaddress2 is not null
	begin
	select @custbilladdress = isnull(@billaddress, '') + ',     ' + isnull(@billcity, '') + ',  ' + isnull(@billstate, '') + '  ' 
		+ isnull(@billzip, '') + '  ' + isnull(@billcountry, '') + char(13) + char(10) + isnull(@billaddress2, '')
	end

exitfunction:
  			
return @custbilladdress
end

GO
GRANT EXECUTE ON  [dbo].[vfJBGetARCustBillAddress] TO [public]
GO
