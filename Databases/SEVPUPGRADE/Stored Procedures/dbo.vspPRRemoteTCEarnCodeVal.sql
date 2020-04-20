SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure dbo.vspPRRemoteTCEarnCodeVal
	/******************************************************
	* CREATED BY:	Mark H 
	* MODIFIED By:   TL 07/05/2012 TK-16109 added JC Cost Type has output parameter for SM
	*
	* Usage:	Validates Earnings code entered in PR Remote Timecard Employee Entry.
	*			Earnings code must be flagged for use in Remote Timecard Employee Entry 
	*			in PREC.
	*	
	*
	* Input params:
	*	
	*			@prco - PR Company
	*			@earncode - Earnings Code
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @earncode bEDLCode, @jccosttype bJCCType output, @msg varchar(100) output)

	as 
	set nocount on

	declare @rcode int
   	
	select @rcode = 0

	if @prco is null
	begin
		select @msg = 'Missing PR Company!', @rcode = 1
		goto vspexit
	end

	if @earncode is null
	begin
		select @msg = 'Missing Earnings Code!', @rcode = 1
		goto vspexit
	end

	if exists(select 1 from dbo.PREC (nolock) where PRCo = @prco and EarnCode = @earncode and IncldRemoteTC = 'Y')
		begin
			select @msg = [Description], @jccosttype = JCCostType from dbo.PREC (nolock) where PRCo = @prco and EarnCode = @earncode and IncldRemoteTC = 'Y'
		end	
	else
		begin
			select @msg = 'Invalid Earnings Code.', @rcode = 1
		end

	vspexit:

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRRemoteTCEarnCodeVal] TO [public]
GO
