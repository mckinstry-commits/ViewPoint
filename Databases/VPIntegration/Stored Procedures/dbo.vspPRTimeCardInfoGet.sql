SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRTimeCardInfoGet    Script Date: 8/28/99 9:34:50 AM ******/
CREATE PROCEDURE [dbo].[vspPRTimeCardInfoGet]
/*************************************
* CREATED BY	: EN 1/06/06
* MODIFIED BY	: EN 7/26/07  added prco validation and error msg
*				  EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
*                 ECV 04/19/11 - TK-04236 - Added default to SMCo field.
*
* Returns commonly needed info for PR Load Procedures
*
* Pass:
*	PR Company
*
* Success returns:
*	PRCO Information:
*		JC Company
*		EM Company
*		GL Company
*		EM Usage flag
*		InsStateOpt
*		TaxStateOpt
*		LocalOpt
*		UnempStateOpt
*		InsByPhase
*		AllowNoPhase
*		OfficeState
*		OfficeLocal
*	EMCO Information:
*		GLCo
*		EMGroup
*		LaborCostCodeChg (@emcostcodeoverride)
*		LaborCT
*	DDUP ShowRates flag
*	0 and Group Description from bHQGP
*   Default SMCo from PRCO
*
* Error returns:
*	1 and error message
**************************************/
(@prco bCompany, @prjcco bCompany output, @premco bCompany output, 
	@prglco bCompany output, @emusage bYN output, @insstateopt bYN output,
	@taxstateopt bYN output, @localopt bYN output, @unempstateopt bYN output,
	@insbyphase bYN output, @allownophase bYN output,
	@officestate varchar(4) output, @officelocal bLocalCode output,
	@emglco bCompany output, @emgroup bGroup output, @emcostcodeoverride bYN output, 
	@emlaborct bEMCType output, @ddupshowrates bYN output, 
	@smcodefault bCompany output, @msg varchar(60) output)

as 
 	set nocount on
  	declare @rcode int
  	select @rcode = 0
  	
if @prco is null
  	begin
  	select @msg = 'Missing PR Company', @rcode = 1
  	goto vspexit
  	end

--get PRCO info  
select @prjcco=JCCo, @premco=EMCo, @prglco=GLCo,
	@emusage=EMUsage, @insstateopt=InsStateOpt,
	@taxstateopt=TaxStateOpt, @localopt=LocalOpt, @unempstateopt=UnempStateOpt,
	@insbyphase=InsByPhase, @allownophase=AllowNoPhase,
	@officestate=OfficeState, @officelocal=OfficeLocal,
	@smcodefault=SMCo
from dbo.PRCO with (nolock)
where PRCo=@prco
if @@ROWCOUNT = 0
	begin
	select @msg = 'Company# ' + convert(varchar,@prco) + ' not setup in PR', @rcode = 1
  	goto vspexit
  	end

--get EMCO info
if @premco is not null
	begin
 	select @emglco=EMCO.GLCo, @emgroup=HQCO.EMGroup, @emcostcodeoverride=LaborCostCodeChg, @emlaborct = LaborCT
	from dbo.EMCO with (nolock)
  	join dbo.HQCO with (nolock) on HQCO.HQCo=EMCO.EMCo 
	where EMCO.EMCo=@premco
 	if @@rowcount = 0
	 	begin
	 	select @msg = 'Invalid EM Company' + convert(varchar(3),@premco), @rcode = 1
	 	goto vspexit
	 	end
	end

--get ShowRates from DDUP  
select @ddupshowrates=ShowRates from dbo.DDUP with (nolock) where VPUserName = suser_sname()


vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTimeCardInfoGet] TO [public]
GO
