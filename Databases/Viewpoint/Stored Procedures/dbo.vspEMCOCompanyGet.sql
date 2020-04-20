SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspEMCOCompanyGet]
/********************************************************
* CREATED BY: TV 4/5/2005
* MODIFIED BY:  TJL 07/24/07 - Add check for Menu Company (HQCo) in EM Module Company Master	
*
* USAGE:
* 	Retrieves the GL, JC and PR companies
	from EMCO
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
* from EMCO (EM Company file):
*	GLCO 
*	JCCP 
*	PRCO 
*	CompUnattachedEquip
*	CompPostCosts
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@emco bCompany, @glco bCompany output, @jcco bCompany output, @prco bCompany output, @compunattached varchar(10) output, @postcost bYN output,
	@errmsg varchar(255) output)
as 
set nocount on

declare @rcode int
select @rcode = 0

if @emco is null
	begin
	select @errmsg = 'Missing EM Company.', @rcode = 1
	goto bspexit
	end
else
	begin
	select top 1 1 
	from dbo.EMCO with (nolock)
	where EMCo = @emco
	if @@rowcount = 0
		begin
		select @errmsg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
		goto bspexit
		end
	end

select 	@glco = GLCo, @jcco = JCCo, @prco = PRCo, @compunattached = CompUnattachedEquip,
	@postcost = CompPostCosts
from dbo.EMCO with(nolock)
where EMCo = @emco 
if @@rowcount = 0
	begin
	select @errmsg = 'Error getting EM Common information.', @rcode = 1
	goto bspexit
	end

bspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCOCompanyGet] TO [public]
GO
