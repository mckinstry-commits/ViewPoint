SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfARCheckForInvoices]
(@arco bCompany = null)

returns char(1)
/***********************************************************
* CREATED BY:  TJL 07/29/08 - Issue #128286, AR Company Invoices exist flag
* MODIFIED BY:  
*
* USAGE:
* 	Returns 'Y' when Invoice transactions exist for this AR Company.  Used to
*	warn users when changing ARCO.InvoiceTax, TaxRetg, and SeparateRetgTax
*
* INPUT PARAMETERS:
*	@arco
*	
*
* OUTPUT PARAMETERS:
*	@invexists
*	
*
*****************************************************/
as
begin

declare @invexists bYN

select @invexists = 'N'

if exists (select top 1 1 from bARTH with (nolock) where ARCo = @arco and ARTransType = 'I')
	begin
	select @invexists = 'Y'
	end

exitfunction:
  			
return @invexists
end

GO
GRANT EXECUTE ON  [dbo].[vfARCheckForInvoices] TO [public]
GO
