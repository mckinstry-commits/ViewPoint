SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMGroupGet    Script Date:  ******/
CREATE proc [dbo].[vspEMCompanyGroupGet]
/********************************************************
* CREATED BY: TV 06/01/06
* USAGE:	TJL  10/23/06 - Issue #27929:  Make this into more of a CommonInfoGet LoadProc
*		DANF 06/13/07 - 124114 Remove Automatic GL on Usage
*		TJL 07/24/07 - Add check for Menu Company (HQCo) in EM Module Company Master
*		TJL 12/07/07 - Issue #124113, Add EMCO.HoursUM to output.  Adjust DDFH for all forms using as LoadProc
*
* 	Retrieves Information commonly used by EM.
*		To retrieve only EMGroup or EMGroup & GLCo info use:  vspEMGroupGet or vspEMGroupGetAlloc
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	EMGroup from bHQCO
*	GLCO from EMCO
*	
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/

(@emco bCompany, @emgroup tinyint output, @emcophasegroup tinyint output, @jccophasegroup tinyint output, @emcoglco bCompany output, 
	@userateorideyn bYN output, @useautogl bYN output, @gloverride bYN output, @emcoshopgroup bGroup output, @emcomatlgroup bGroup output,
	@emcojcco bCompany output, @emcoprco bCompany output, @compunattached varchar(10) output, @postcosttocomp bYN output,
	@emcohoursum bUM output, @msg varchar(60) output) 
as 
set nocount on

declare @rcode int
select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto vspexit
	end
else
	begin
	select top 1 1 
	from dbo.EMCO with (nolock)
	where EMCo = @emco
	if @@rowcount = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
		goto vspexit
		end
	end

select @emgroup = h.EMGroup, @emcophasegroup = h.PhaseGroup, @jccophasegroup = hjc.PhaseGroup, @emcoglco = e.GLCo,
	@userateorideyn = e.UseRateOride, @gloverride = e.GLOverride, @emcoshopgroup = h.ShopGroup, @emcomatlgroup = h.MatlGroup,
	@emcojcco = e.JCCo, @emcoprco = e.PRCo, @compunattached = e.CompUnattachedEquip, @postcosttocomp = e.CompPostCosts,
	@emcohoursum = e.HoursUM
from bEMCO e with (nolock)
join bHQCO h with (nolock) on h.HQCo = e.EMCo
join bHQCO hjc with (nolock) on hjc.HQCo = e.JCCo
where e.EMCo = @emco and h.HQCo = @emco

if @@rowcount = 0
	begin
	select @msg = 'Error getting EM Common information.', @rcode = 1
	goto vspexit
	end

if @emgroup is Null 
	begin
	select @msg = 'EM Group not setup for EM Co ' + isnull(convert(varchar(3),@emco),'') + ' in HQ.', @rcode=1
	goto vspexit
	end

if @jccophasegroup is Null 
	begin
	select @msg = 'JC Phase Group not setup for EMCo JC Company in HQ.', @rcode=1
	goto vspexit
	end

if @emcophasegroup is Null 
	begin
	select @msg = 'EM Phase Group not setup for EM Company in HQ.', @rcode=1
	goto vspexit
	end

vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCompanyGroupGet] TO [public]
GO
