SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAREMCompanyValWithInfo    ******/
CREATE proc [dbo].[vspAREMCompanyValWithInfo]
/*************************************
* CREATED:	TJL 10/24/05 - Issue #27709, 6x rewrite
* 
*
* Pass:
*	JC Company number
*
* Success returns:
*	0 and other info
*
* Error returns:
*	1 and error message
**************************************/
(@emco bCompany = null, @glco bCompany output, @gloverride bYN output, @emgroup bGroup output, 
	@taxgroup bGroup output, @msg varchar(60) output)
as

set nocount on

declare @rcode int, @hqemgroup bGroup

select @rcode = 0
  
if @emco is null
  	begin
  	select @msg = 'Missing EM Company#', @rcode = 1
  	goto vspexit
  	end
  
/* Validate EMCo */
if exists(select 1 from bEMCO with (nolock) where @emco = EMCo)
	begin
	select @msg = Name from bHQCO with (nolock) where HQCo = @emco
	end
else
	begin
	select @msg = 'Not a valid EM Company', @rcode = 1
	goto vspexit
	end
 

select @glco = e.GLCo, @gloverride = e.GLOverride, @emgroup = isnull(e.EMGroup, h.EMGroup), @taxgroup = h.TaxGroup,
	@hqemgroup = h.EMGroup
from bEMCO e with (nolock)
join bHQCO h with (nolock) on h.HQCo = e.EMCo
where e.EMCo = @emco
  
vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')	--+ char(13) + char(10) + char(13) +char(10) + '[vspAREMCompanyValWithInfo]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAREMCompanyValWithInfo] TO [public]
GO
