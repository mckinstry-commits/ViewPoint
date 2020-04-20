SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCompanyValWithInfo    Script Date: 08/02/01 9:34:25 AM ******/
CREATE proc [dbo].[bspEMCompanyValWithInfo]
/***********************************************************
* CREATED BY: 	TJL - 08/02/01
* MODIFIED By : TV 02/11/04 - 23061 added isnulls
*		TJL 12/06/06 - Issue #27979, 6x Recode EMUsePosting.   (Made vDDFI entries to all 6x forms, NA elsewhere).
*			Added GLCo and WOCostCodeChg  
*
* USAGE:
* validates EM Company number and returns EMGroup
*
* INPUT PARAMETERS
*   EMCo   EM Co to Validate
*
* OUTPUT PARAMETERS
*   @GLOverride,  Allow GLAcct override or not
*   @EMGroup,  EMGroup
*   @msg If Error, error message, otherwise description of Company
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@emco bCompany = null, @emgroup bGroup output, @gloverride bYN output, 
	@emcoglco bCompany output, @wocostcodechgyn bYN output, @msg varchar(60) output)
as
set nocount on

declare @rcode int
select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company#.', @rcode = 1
	goto bspexit
	end

select @emgroup = h.EMGroup, @gloverride = e.GLOverride, @emcoglco = e.GLCo,
	@wocostcodechgyn = e.WOCostCodeChg, @msg = h.Name
from bEMCO e
join bHQCO h with (nolock) on h.HQCo = e.EMCo
where e.EMCo = @emco and h.HQCo = @emco 
if @@rowcount = 0
	begin
	select @msg = 'Not a valid EM Company.', @rcode = 1
	goto bspexit
	end

if @emgroup is null
	begin
	select @msg = 'An EMGroup must be setup in HQ for this EMCo.', @rcode = 1
	goto bspexit
	end

bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCompanyValWithInfo] TO [public]
GO
