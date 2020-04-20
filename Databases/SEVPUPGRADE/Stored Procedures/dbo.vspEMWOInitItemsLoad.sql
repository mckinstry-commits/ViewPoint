SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMWOInitItemsLoad]
/********************************************************
* CREATED BY: TRL 1/24/2007
* MODIFIED BY:	
*
* USAGE:
* 	Retrieves the EMGroup and AllSMG (Init allSMG Items)
	
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
* from EMCO (EM Company file):
*	EMGroup
*	AllSMG 
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@emco bCompany, 
@emgroup bGroup output, 
@allsmg bYN output,
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

select @emgroup = HQCO.EMGroup, @allsmg=AllSMG
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
GRANT EXECUTE ON  [dbo].[vspEMWOInitItemsLoad] TO [public]
GO
