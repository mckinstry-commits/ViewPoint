SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRResValforVA]
	/******************************************************
	* CREATED BY:	mh 09/09/2008 
	* MODIFIED By: 
	*
	* Usage:	Validates Resource against HRRM and checks
	*			for previous assignment in VA User Profile
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
   
   	(@vpusername bVPUserName, @hrco bCompany, @hrref varchar(15), @refout int output, @msg varchar(75) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	exec @rcode = bspHRResVal @hrco, @hrref, @refout output, null, @msg output

	if @rcode = 0
	begin
		--Check for previous usage in VA - DDUP
		if exists(select 1 from DDUP where HRCo = @hrco and HRRef = @refout and VPUserName <> @vpusername)
		begin
			select @msg = 'Resource number currently assigned to another VA User.', @rcode = 1
		end
	end

	 
	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRResValforVA] TO [public]
GO
