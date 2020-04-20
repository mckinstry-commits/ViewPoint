SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspEMSHCompanyGet]
/********************************************************
* CREATED BY: TRL 1/24/2007
* MODIFIED BY:	TRL 12/08/08, Issue 131273, removed IN Matl Group from return parameter
*
* USAGE:
* 	Retrieves the Matl Group, EMGroup form EM Company
	
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
* from EMCO (EM Company file):
*	EMGroup
*	MatlGroup 
*	
*	
*	
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@emco bCompany, @emgroup bGroup output, @matlgroup bGroup output ,@errmsg varchar(255) output)
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
	for Matle Group*/
	select 	@emgroup = HQCO.EMGroup, @matlgroup=HQCO.MatlGroup
	from dbo.EMCO (nolock)
	Left Join dbo.HQCO with(nolock)on HQCO.HQCo=EMCo
	where EMCo = @emco 

	/*131273 Added check for Matl Group*/
	If @matlgroup=null
	begin
		select @errmsg = 'Missing HQ Matl Group!', @rcode = 1
		goto vspexit
	end
	
vspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMSHCompanyGet] TO [public]
GO
