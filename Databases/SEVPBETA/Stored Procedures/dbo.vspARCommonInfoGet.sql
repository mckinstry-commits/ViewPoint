SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARCommonInfoGet    Script Date: ******/
CREATE proc [dbo].[vspARCommonInfoGet]
/*************************************
*  Created:		TJL
*  Modified:	TJL 07/24/07 - Add check for Menu Company (HQCo) in AR Module Company Master
*		TJL 05/29/08 - Issue #128286, International Sales Tax	
*
*  Common AR Information returned to AR Forms during Load
*
*  Inputs:
*	 @arco:		AR Company (Actually Menu Company which is HQCo)
*
*  Outputs:
*	 GLCo:		GLCo from ARCo
*	 CustGroup:	Customer Group from HQCo
*	 TaxGroup:	Tax Group from HQCo
*	 RecType:	RecType from ARCo
*	 FCPct:		FinanceChg Pct from ARCo
*
* Error returns:
*	0 and Group Description from bHQGP
*	1 and error message
**************************************/
(@arco bCompany, @glco bCompany output, @custgroup bGroup output, @taxgroup bGroup output, 
	@matlgroup bGroup output, @rectype int output, @fcpct bPct output, @jcco bCompany output, 
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

select @glco = a.GLCo, @custgroup = h.CustGroup, @taxgroup = h.TaxGroup, @taxretgyn = a.TaxRetg,
	@matlgroup = h.MatlGroup, @rectype = a.RecType, @fcpct = a.FCPct, @jcco = a.JCCo,
	@sepretgtaxyn = a.SeparateRetgTax
from bARCO a with (nolock)
join bHQCO h with (nolock) on h.HQCo = a.ARCo
where a.ARCo = @arco and h.HQCo = @arco
if @@rowcount = 0
	begin
	select @msg = 'Error getting AR Common information.', @rcode = 1
	end
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARCommonInfoGet] TO [public]
GO
