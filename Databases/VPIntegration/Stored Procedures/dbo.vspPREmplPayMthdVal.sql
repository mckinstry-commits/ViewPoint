SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPREmplPayMthdVal]
	/******************************************************
	* CREATED BY:	markh 02/18/08 
	* MODIFIED By: 
	*
	* Usage:
	*	
	*		Validation to check if an email address is specified 
	*		when PayMethodDelivery is not "N"
	*
	* Input params:
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @employee bEmployee, @email varchar(60), 
	@paymethoddeliv char(1), @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @email is null and @paymethoddeliv <> 'N'
	begin
		select @msg = 'Method of Pay Stub Delivery is Email.  Email address required.' 
		select @rcode = 1
	end
	 
	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPREmplPayMthdVal] TO [public]
GO
