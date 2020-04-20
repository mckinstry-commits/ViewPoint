SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure dbo.vspHQReviewerGroupTypeVal
	/******************************************************
	* CREATED BY:	MarkH 
	* MODIFIED By: 
	*
	* Usage:
	*	
	*
	* Input params:
	*
	*	@revgroup - Reviewer Group
	*	@revgrouptype - Reviewer Group Type
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/

   	@revgroup varchar(10), @revgrouptype tinyint, @msg varchar(100) output
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @revgrouptype = 2
	begin
		if (select count(distinct ApprovalSeq) from HQRD where ReviewerGroup = @revgroup) > 1 
		begin
			select @msg = 'Reviewer Group Type "2-Timesheet" requires all Reviewer''s Approval Sequences to be the same level.', @rcode = 1
		end	
	end
	 
	vspexit:

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQReviewerGroupTypeVal] TO [public]
GO
