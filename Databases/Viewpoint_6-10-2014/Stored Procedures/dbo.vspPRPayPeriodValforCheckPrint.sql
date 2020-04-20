SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRPayPeriodValforCheckPrint]
	/******************************************************
	* CREATED BY:	mh 2/27/2008 
	* MODIFIED By: 
	*
	* Usage:	Validates Pay Period for Check Print.  Returns
	*			status as output parameter.
	*	
	*
	* Input params:
	*	
	*	@prco bCompany
	*	@prgroup bGroup 
	*	@enddate bDate - Pay period end date
	*
	* Output params:
	*
	*	@status Status of pay period.
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
	(@prco bCompany, @prgroup bGroup, @enddate bDate, @status tinyint output, @msg varchar(60) output)
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	exec @rcode = bspPREndDateVal @prco, @prgroup, @enddate, '0', @msg output
	select @status = @rcode	
	 
	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRPayPeriodValforCheckPrint] TO [public]
GO
