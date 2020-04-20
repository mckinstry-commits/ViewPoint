SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRGroupInfoGet    Script Date: 8/28/99 9:34:50 AM ******/
  CREATE         proc [dbo].[vspPRGroupInfoGet]
/*************************************
* CREATED BY	: EN 5/20/05
* MODIFIED BY	: EN 7/26/07  added prco validation and error msg
*
* Returns commonly needed info for PR Load Procedures
*
* Pass:
*	PR Company
*
* Success returns:
*	PRCO Information:
*		GL Company
*		CM Company
*		Y/N flag indicating if bEmployee datatype is secure
*	0 and Group Description from bHQGP
*
* Error returns:
*	1 and error message
**************************************/
(@prco bCompany, @prglco bCompany output, @prcmco bCompany output, @empldtsecure bYN output,
 @msg varchar(60) output)

as 
 	set nocount on
  	declare @rcode int, @prjcco bCompany
  	select @rcode = 0
  	
if @prco is null
  	begin
  	select @msg = 'Missing PR Company', @rcode = 1
  	goto vspexit
  	end

--get PRCO info  
select @prglco=GLCo, @prcmco=CMCo
from dbo.PRCO with (nolock)
where PRCo=@prco
if @@ROWCOUNT = 0
	begin
	select @msg = 'Company# ' + convert(varchar,@prco) + ' not setup in PR', @rcode = 1
  	goto vspexit
  	end

--get Secure flag
select @empldtsecure = 'N'
select @empldtsecure = Secure
  	from dbo.DDDTShared (nolock)
  	where Datatype = 'bEmployee'
if @@rowcount = 0
  	begin
  	select @msg = 'Datatype bEmployee not set up!', @rcode = 1
  	end


vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRGroupInfoGet] TO [public]
GO
