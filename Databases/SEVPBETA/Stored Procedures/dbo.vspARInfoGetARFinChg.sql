SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQGroupVal    Script Date: 05/03/05 ******/
CREATE proc [dbo].[vspARInfoGetARFinChg]
/*******************************************************************************
*  Created:		TJL 05/03/05
*  Modified:	TJL 07/24/07 - Add check for Menu Company (HQCo) in AR Module Company Master		
*
*  AR Information returned to ARFinChg Form during Load
*
*  Inputs:
*	 @arco:		AR Company (Actually Menu Company which is HQCo)
*
*  Outputs:
*	 Many
*
* Error returns:
*	0 and Group Description from bHQGP
*	1 and error message
*
******************************************************************************************/
(@arco bCompany, @glco bCompany output, @custgroup bGroup output, @invautonumyn char(1) output, @rectype tinyint output,
	@rectypeyn char(1) output, @fclevel tinyint output, @fcpct bPct output, @fcfinserv char(1) output,
	@fcrectype tinyint output, @jcglco bCompany output, @msg varchar(60) output)
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
select @glco = a.GLCo, @custgroup = h.CustGroup, @invautonumyn = a.InvAutoNum, @rectype = a.RecType, @rectypeyn = a.RecTypeOpt, 
	@fclevel = a.FCLevel, @fcpct = a.FCPct, @fcfinserv = a.FCFinOrServ, @fcrectype = a.FCRecType, @jcglco = j.GLCo
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
GRANT EXECUTE ON  [dbo].[vspARInfoGetARFinChg] TO [public]
GO
