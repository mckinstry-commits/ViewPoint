SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspHQReviewerValWithInfo]
	/******************************************************
	* CREATED BY:  Mark H 
	* MODIFIED By: 
	*
	* Usage:  Based on bspHQReviewer, validates the Reviewer and returns
	*		  the reviewer group type 
	*	
	*
	* Input params:
	*	
	*	@reviewer
	*
	* Output params:
	*
	*	@reviewergrouptype
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@reviewer varchar(10) = null, @reviewergroup varchar(10), @reviewergrouptype tinyint output, 
   	@msg varchar(60) output)
   	
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	exec @rcode = bspHQReviewer @reviewer, @msg output
	
	if @rcode = 0
	begin
		select @reviewergrouptype = ReviewerGroupType from HQRG where ReviewerGroup = @reviewergroup
	end
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQReviewerValWithInfo] TO [public]
GO
