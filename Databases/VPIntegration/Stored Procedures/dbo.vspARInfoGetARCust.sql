SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQGroupVal    Script Date: 8/28/99 9:34:50 AM ******/
CREATE proc [dbo].[vspARInfoGetARCust]
/*************************************
*  Created:		TJL
*  Modified:	TJL 07/24/07 - Add check for Menu Company (HQCo) in AR Module Company Master	
*
*  AR Information returned
*
*  Inputs:
*	 @arco:		AR Company (Actually Menu Company which is HQCo)
*
*  Outputs:
*	 @msco:			GLCo from ARCo
*	 @custgroup:	Customer Group from HQCo
*	 @taxgroup:		Tax Group from HQCo
*	 @rectype:		RecType from ARCo
*	 @fcpct:		FinanceChg Pct from ARCo
*
* Error returns:
*	0 and Group Description from bHQGP
*	1 and error message
**************************************/
(@arco bCompany, @msco bCompany output, @custgroup bGroup output, @taxgroup bGroup output, 
	@rectype int output, @fcpct bPct output, @msg varchar(60) output)
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

/* Get AR Common information */
select @custgroup = h.CustGroup, @taxgroup = h.TaxGroup,
	@rectype = a.RecType, @fcpct = a.FCPct
from bARCO a with (nolock)
join bHQCO h with (nolock) on h.HQCo = a.ARCo
where a.ARCo = @arco and h.HQCo = @arco
if @@rowcount = 0
	begin
	select @msg = 'Error getting AR Common information.', @rcode = 1
	end

/* Get Specific information relative to ARCustomers form */
select @msco = min(MSCo)
from bMSCO with (nolock)
where ARCo = @arco
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARInfoGetARCust] TO [public]
GO
