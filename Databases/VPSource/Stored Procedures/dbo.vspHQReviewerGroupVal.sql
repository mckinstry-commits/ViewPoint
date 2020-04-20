SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspHQReviewerGroupVal]
	/******************************************************
	* CREATED BY:	Mark H 
	* MODIFIED By: 
	*
	* Usage:	Validates HQ Reviewer Group against HQRG.
	*	
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
   
   	@revgroup varchar(10), @mod char(2), @msg varchar(100) output

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if exists(select 1 from HQRG (nolock) where ReviewerGroup = @revgroup)
	begin
		if @mod = 'PR' 
		begin
			--Reviewer Group Exists - Check that it is Type 2
			if not exists(select 1 from HQRG (nolock) where ReviewerGroup = @revgroup and ReviewerGroupType = 2)
			begin
				select @msg = 'Reviewer Group must be Reviewer Group Type "2-Timesheet"', @rcode = 1
				goto vspexit
			end
		end

		if @mod = 'AP'
		begin

			--Reviewer Group Exists - Check that it is Type 1
			if not exists(select 1 from HQRG (nolock) where ReviewerGroup = @revgroup and ReviewerGroupType = 1)
			begin
				select @msg = 'Reviewer Group must be Reviewer Group Type "1-Invoice"', @rcode = 1
				goto vspexit
			end
		end
	
		select @msg = [Description] from HQRG (nolock) where ReviewerGroup = @revgroup 
	end
	else
	begin
		select @msg = 'Reviewer Group has not been set up in HQ Reviewer Groups.', @rcode = 1
	end

	vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspHQReviewerGroupVal] TO [public]
GO
