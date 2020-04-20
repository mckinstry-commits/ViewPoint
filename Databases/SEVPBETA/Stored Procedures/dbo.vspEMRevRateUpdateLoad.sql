SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMGroupGet    Script Date: 8/28/99 9:34:28 AM ******/
CREATE  proc [dbo].[vspEMRevRateUpdateLoad]
/********************************************************
* CREATED BY: 	TRL 03/06/09
* MODIFIED BY: 
*
* USAGE:
* 	Retrieves EMGroup from HQCompany 
*	and EM Company Default RevBrkdownCode
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	EMGroup from bHQCO
*	UseRevBrkdownCodeDefault
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@emco bCompany = 0, @emgroup bGroup output,
@userevbrkdowncodedefault varchar(10) output, 
@msg varchar(60) output) as 

set nocount on

declare @rcode int

select @rcode = 0

IF @emco is null
	BEGIN
  		select @msg = 'Missing EM Company', @rcode = 1
		goto vspexit
	END
ELSE
	BEGIN
		select top 1 1 	from dbo.EMCO with (nolock)	where EMCo = @emco
		if @@rowcount = 0
		begin
			select @msg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
			goto vspexit
		end
	END

select @emgroup = h.EMGroup, @userevbrkdowncodedefault = e.UseRevBkdwnCodeDefault
from dbo.HQCO h with(nolock)
Inner join dbo.EMCO e with(nolock)on e.EMCo=h.HQCo
where h.HQCo = @emco

if @@rowcount = 0 
begin
  select @msg = 'EM Company does not exist.', @rcode=1, @emgroup=0
End

if @emgroup is Null 
begin
  select @msg = 'EM Group not setup for EM Co ' + isnull(convert(varchar(3),@emco),'') + ' in HQ!' , @rcode=1, @emgroup=0
End

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRevRateUpdateLoad] TO [public]
GO
