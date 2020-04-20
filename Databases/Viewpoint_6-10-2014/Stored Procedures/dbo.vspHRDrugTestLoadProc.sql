SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRDrugTestLoadProc]
	/******************************************************
	* CREATED BY:	mh 12/6/2007 
	* MODIFIED By: 
	*
	* Usage:  Load Procedure for HR Drug Testing
	*	
	*
	* Input params:
	*	
	*	HRCo
	*
	* Output params:
	*
	*	@defltstatus - Default Drug Test Status Code from HRCO
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@hrco bCompany, @defltstatus varchar(10) output, @msg varchar(512) output
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HRCo', @rcode = 1
		goto vspexit
	end

	exec @rcode = vspCompanyVal @hrco, 'HR', @msg 

	if @rcode = 1 
		goto vspexit	 

	select @defltstatus = InitDrugTestStatus from HRCO where HRCo = @hrco

	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRDrugTestLoadProc] TO [public]
GO
