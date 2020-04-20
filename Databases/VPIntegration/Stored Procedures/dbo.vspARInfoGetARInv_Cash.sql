SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQGroupVal    Script Date: 8/28/99 9:34:50 AM ******/
CREATE proc [dbo].[vspARInfoGetARInv_Cash]
/*******************************************************************************
*  Created:		TJL
*  Modified:	TJL 07/24/07 - Add check for Menu Company (HQCo) in AR Module Company Master	
*		TJL 06/05/08 - Issue #128457:  ARCashReceipts International Sales Tax
*
*  AR Information returned to ARInvoiceEntry or ARCashReceipts Form during Load
*
*  Inputs:
*	 ARCo:		AR Company
*
*  Outputs:
*	 Many
*
* Error returns:
*	0 and Group Description from bHQGP
*	1 and error message
*
******************************************************************************************/
(@arco bCompany, @glco bCompany output, @custgroup bGroup output, @taxgroup bGroup output, 
	@rectype int output, @matlgroup bGroup output, @jcco bCompany output, @jccoglco bCompany output,
	@discopt char(1) output, @invtaxyn char(1) output, @rectypeyn char(1) output, @disctaxyn char(1) output, @invautonumyn char(1) output,
	@rectaxyn char(1) output, @relretgyn char(1) output, @cmco bCompany output, @cmacct bCMAcct output, @emco bCompany output, 
	@taxretgyn bYN output, @sepretgtaxyn bYN output, @msg varchar(60) output)
as 
set nocount on
declare @rcode int
select @rcode = 0
  	
if @arco is null
	begin
	select @msg = 'Missing AR Company.', @rcode = 1
	goto vspexit
	end
else
	begin
	select top 1 1 
	from dbo.ARCO with (nolock)
	where ARCo = @arco
	if @@rowcount = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@arco) + ' not setup in AR.', @rcode = 1
		goto vspexit
		end
	end

/* Get AR Company information */
select @glco = a.GLCo, @custgroup = h.CustGroup, @taxgroup = h.TaxGroup, @rectype = a.RecType, @matlgroup = h.MatlGroup, 
	@jcco = a.JCCo, @jccoglco = j.GLCo, @discopt = a.DiscOpt, @invtaxyn = a.InvoiceTax, 
	@rectypeyn = a.RecTypeOpt, @disctaxyn = a.DiscTax, @invautonumyn = a.InvAutoNum, 
	@rectaxyn = a.ReceiptTax, @relretgyn = a.RelRetainOpt, @cmco = a.CMCo, @cmacct = a.CMAcct,
	@emco = a.EMCo, @taxretgyn = a.TaxRetg, @sepretgtaxyn = a.SeparateRetgTax
from bARCO a with (nolock)
join bHQCO h with (nolock) on h.HQCo = a.ARCo
left join bJCCO j with (nolock) on j.JCCo = a.JCCo
where a.ARCo = @arco and h.HQCo = @arco
if @@rowcount = 0
	begin
	select @msg = 'Error getting AR Common information.', @rcode = 1
	end
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARInfoGetARInv_Cash] TO [public]
GO
