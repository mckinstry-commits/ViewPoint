SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMShopsLoadProc]
/**************************************************************************
*	CREATED:  6/15/06
*	MODIFIED:  TJL 01/24/07 - Issue #28024, 6x Rewrite EMLocXferBatch.  Add EMCOGLCo, ShopGroup
*		TJL 07/24/07 - Add check for Menu Company (HQCo) in EM Module Company Master
*
*	
* USAGE:
* returns next available WO to  EMWOinit
*
*   Inputs:
*	Shop	
*   Outputs:
*	Work Order Opt
*	INCo
*
*
*   RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*
***************************************************************************/
(@emco bCompany, @autoopt varchar(20) output, @inco bCompany output, @emgroup bGroup output, @emcoglco bCompany output,
	@shopgroup bGroup output, @matlgroup bGroup output, @msg varchar(255) output)
as

set nocount on

declare @rcode int
select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto bspexit
	end
else
	begin
	select top 1 1 
	from dbo.EMCO with (nolock)
	where EMCo = @emco
	if @@rowcount = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
		goto bspexit
		end
	end

select @autoopt = e.WorkOrderOption, @inco = e.INCo, @emgroup = e.EMGroup, @emcoglco = e.GLCo,
	@shopgroup = h.ShopGroup, @matlgroup = h.MatlGroup
from dbo.EMCO e with (nolock)
join dbo.HQCO h with (nolock) on e.EMCo = h.HQCo
where e.EMCo = @emco
if @@rowcount = 0
	begin
	select @msg = 'Error getting EM and HQ common information.', @rcode = 1
	goto bspexit
	end

bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMShopsLoadProc] TO [public]
GO
