SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMGroupGet    Script Date: 8/28/99 9:34:28 AM ******/
CREATE   proc [dbo].[vspEMGroupGetAlloc]
/********************************************************
* CREATED BY: 	TV 06/28/06
* 
* USAGE:
* 	Retrieves EMGroup from HQCompany
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	EMGroup from bHQCO
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/

(@emco bCompany = 0, @EMGroup tinyint output, @GLCo bCompany output, @msg varchar(60) output) as 
set nocount on
declare @rcode int
select @rcode = 0

  if @emco is null
  	begin
	  	select @msg = 'Missing EM Company', @rcode = 1
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

select @EMGroup = EMGroup 
from dbo.HQCO with(nolock)
where HQCo = @emco

if @@rowcount = 0 
  select @msg = 'EM Company does not exist.', @rcode=1, @EMGroup=0

if @EMGroup is Null 
  select @msg = 'EM Group not setup for EM Co ' + isnull(convert(varchar(3),@emco),'') + ' in HQ!' , @rcode=1, @EMGroup=0

select @GLCo = GLCo
from dbo.EMCO with (nolock)
where EMCo = @emco


bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMGroupGetAlloc] TO [public]
GO
