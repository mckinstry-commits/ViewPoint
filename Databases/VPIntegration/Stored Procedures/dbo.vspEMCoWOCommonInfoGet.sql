SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspEMCoWOCommonInfoGet]
/********************************************************
* CREATED BY: TRL 1/24/2007
* MODIFIED BY:	TRL 12/08/08, Issue 131273, removed IN Matl Group from return parameter
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
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@emco bCompany, 
@emgroup bGroup output, 
@matlgroup bGroup output , 
@wobeginstatus varchar(10) output, 
@wobeginpartsstatus varchar(10) output,
@dfltrepairtype varchar(10) output, 
@partscosttype bEMCType output, 
@outsiderepairct bEMCType output, 
@prco bCompany output,  
@inco bCompany output, 
@woautoseq bYN output, 
@woautoopt varchar(5) output, 
@shopgroup bGroup output, 
@showallwo bYN output,
@matlvalid bYN output,
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

/*131273 Removed IN Co from select statement and INCo.MatlGroup from return param
for Matl Group, should only be EM HQCo.MatlGroup*/
select @emgroup = HQCO.EMGroup, @matlgroup= HQCO.MatlGroup,@wobeginstatus = EMCO.WOBeginStat, 
@wobeginpartsstatus = EMCO.WOBeginPartStatus,@dfltrepairtype = WODefaultRepType, @partscosttype = EMCO.PartsCT, 
@outsiderepairct =OutsideRprCT, @prco = EMCO.PRCo, @inco=EMCO.INCo,  @woautoseq = EMCO.WOAutoSeq, 
@woautoopt = EMCO.WorkOrderOption, @shopgroup=HQCO.ShopGroup, @showallwo=EMCO.ShowAllWO,@matlvalid=MatlValid
	from dbo.EMCO (nolock)
	Left Join dbo.HQCO with(nolock)on HQCO.HQCo=EMCO.EMCo
	where EMCo = @emco 
	if @@rowcount = 0
    	begin
			select @errmsg = 'EM Company does not exist.', @rcode=1
    		goto vspexit
    	end

	if @emgroup is null
    	begin
			select @errmsg = 'EM Group does not exist.', @rcode=1
    		goto vspexit
    	end

vspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCoWOCommonInfoGet] TO [public]
GO
