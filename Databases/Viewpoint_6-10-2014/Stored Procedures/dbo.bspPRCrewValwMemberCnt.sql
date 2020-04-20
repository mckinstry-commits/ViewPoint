SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRCrewValwMemberCnt]
	/******************************************************
	* CREATED BY:	MarkH 
	* MODIFIED By: 
	*
	* Usage:	Validate Crew and return count of Crew Members.
	*	
	*	Created as a shell for bspPRCrewVal.  Needed a count of crew members
	*	but due to usage of bspPRCrew it was not practical to change that proc.
	*
	* Input params:
	*	
	*	@prco, @crew	
	*
	* Output params:
	*
	*	@crewcount  Count of crew members in PRCW.  
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany = 0, @crew varchar(10) = null, @crewcount int= 0 output , @msg varchar(60) output)
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	exec @rcode = bspPRCrewVal @prco, @crew, @msg output

	select @crewcount = isnull(count(PRCo),0) from dbo.PRCW (nolock) where PRCo = @prco and Crew = @crew

	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCrewValwMemberCnt] TO [public]
GO
