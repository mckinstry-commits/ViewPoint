SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRPayStubNotifyLoad]
	/******************************************************
	* CREATED BY:  markh 
	* MODIFIED By: 
	*
	* Usage:  Load procedure for PR Pay Stub Notify.
	*	
	*
	* Input params:
	*	
	*	@prco - Payroll Company	
	*
	* Output params:
	*
	*	@fromemailaddress  Default email address
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@prco bCompany, @fromemailaddress varchar(55) output, @attachtypeid int output, @msg varchar(100) output
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if not exists(select 1 from dbo.bPRCO (nolock) where PRCo = @prco)
	begin
		select @msg = 'Company# ' + convert(varchar,@prco) + ' not setup in PR', @rcode = 1
		goto vspexit
	end

	select @fromemailaddress = [Value] from dbo.WDSettings (nolock) where Setting = 'FromAddress'

	select @attachtypeid = PayStubAttachTypeID from dbo.PRCO (nolock) where PRCo = @prco


	vspexit:

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRPayStubNotifyLoad] TO [public]
GO
