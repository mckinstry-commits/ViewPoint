SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[vspPRAPUpdateInfoGet]    Script Date: 08/07/2008 09:15:16 ******/
  CREATE         proc [dbo].[vspPRAPUpdateInfoGet]
/*************************************
* CREATED BY	: EN 8/07/08
* MODIFIED BY	: 
*
* Returns info for PR AP Update load procedure
*
* Pass:
*	@prco	PR Company
*
* Success returns:
*	@apcmco	CMCo value from bAPCO
*
* Error returns:
*	@rcode=1 and @msg=error message
**************************************/
(@prco bCompany, @apcmco bCompany output, @msg varchar(60) output)

as 
 	set nocount on
  	declare @rcode int, @apco bCompany
  	select @rcode = 0
  	
--validate PRCo
if @prco is null
  	begin
  	select @msg = 'Missing PR Company', @rcode = 1
  	goto vspexit
  	end

--get AP Company # from bPRCO
select @apco = APCo from dbo.PRCO with (nolock) where PRCo = @prco
if @@rowcount = 0
	begin
	select @msg = 'Company# ' + convert(varchar,@prco) + ' not setup in PR', @rcode = 1
  	goto vspexit
  	end

--get @apcmco
select @apcmco = CMCo from dbo.APCO with (nolock) where APCo = @apco
if @@rowcount = 0
  	begin
  	select @msg = 'AP company info not setup!', @rcode = 1
	goto vspexit
  	end


vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRAPUpdateInfoGet] TO [public]
GO
