SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMWOPartsPostingLoad]
/********************************************************
* CREATED BY: TRL 1/24/2007
* MODIFIED BY:	TJL 02/05/08 - Issue #126814:  Return EMCO.MatlLastUsedYN value.
*				TRL 12/09/08 - Issue #131273: Removed INCo Matl Group column has output parameter
*								also, removed INCO from select statement
*
* USAGE:
* 	Retrieves the Matl Group, EMGroup, Beginning WO Order Status, Beginning Parts Code
*  DefaultRepairType, Parts Cost Type, Outside Repair Cost Type.
	
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
* from EMCO (EM Company file):
*	EMGroup
*	MatlGroup 
*	Beginning WO Order Status
*	Beginning Parts Code
*	DefaultRepairType
*  Parts Cost Type
*  Outside Repair Cost Type
*	PRCo
*  INCo
*	EMCO.WOAutoSeq
*	EMSX.WOShop
*	EMCO.AutoOpt
*  HQCO.ShopGroup
*  EMCo.GLCo
*
* RETURN VALUE:
* 	0 	    Success*	1 & message Failure
*
**********************************************************/
(@emco bCompany, 
@emgroup bGroup output, 
@matlgroup bGroup output , 
@partscosttype bEMCType output, 
@outsiderepairct bEMCType output, 
@prco bCompany output,  
@inco bCompany output, 
@allwcostcodechange bYN output, 
@matltax bYN output, 
@matlvalid bYN output, 
@glco bCompany output, 
@glmiscglaccount bGLAcct output,
@taxgroup bGroup output,
@emcomatllastusedyn bYN output,
@errmsg varchar(255) output)

as 
set nocount on

declare @rcode int
select @rcode = 0
if @emco is null
  	begin
	  	select @errmsg = 'Missing EM Company', @rcode = 1
  		goto vspexit
  	end
  else
	begin
		select top 1 1 
		from dbo.EMCO with (nolock)
		where EMCo = @emco
		if @@rowcount = 0
			begin
				select @errmsg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
				goto vspexit
			end
	end

select @emgroup = HQCO.EMGroup, @matlgroup=HQCO.MatlGroup,@partscosttype = EMCO.PartsCT, 
@outsiderepairct =OutsideRprCT, @prco = EMCO.PRCo, @inco=EMCO.INCo,  @allwcostcodechange = EMCO.WOCostCodeChg, 
@matltax= EMCO.MatlTax, @matlvalid=EMCO.MatlValid, @glco = EMCO.GLCo, @glmiscglaccount = EMCO.MatlMiscGLAcct, @taxgroup = HQCO.TaxGroup,
@emcomatllastusedyn = EMCO.MatlLastUsedYN
from dbo.EMCO (nolock)
Left Join dbo.HQCO with(nolock)on HQCO.HQCo=EMCO.EMCo
where EMCo = @emco 
if @@rowcount = 0
	begin
		select @errmsg = 'EM Company does not exist.', @rcode=1
		goto vspexit
	end

If  @matlgroup= null 
begin
	select @errmsg = 'Material Group missing in HQCo for this EM Company!', @rcode=1
    goto vspexit
end

If @emgroup = null 
begin
	select @errmsg = 'EM Group missing for this EM Company!', @rcode=1
    goto vspexit
end

If @taxgroup = null 
begin
	select @errmsg = 'Unable to get TaxGroup for EM Company!', @rcode=1
    goto vspexit
end

if @glco is null
begin
	select @errmsg = 'Could not get GL Co for this EM Co!', @rcode=1
    goto vspexit
end

vspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOPartsPostingLoad] TO [public]
GO
