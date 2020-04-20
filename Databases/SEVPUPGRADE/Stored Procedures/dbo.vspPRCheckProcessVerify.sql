SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRCheckProcessVerify]
/***********************************************************
* Created: GG 02/07/07
* Modified:	EN 2/28/08 #25357 - add facility to return -1 if pay period is reserved by another user
*
* Used by PR Check Print to see if entries exist in bPRSP for a given PRCo/PRGroup/PREndDate.
* Existing entries indicate a previously interrupted check print session.  
* As of issue 25357, also indicates if pay period is reserved by another user by returning -1.
*
* Input params:
*	@prco		PR company
*	@prgroup	PR Group
*	@prenddate  Period End Date
*
* Output params:
*	@inuseby	if the pay period is reserved by another user (@rcode=5) this is the username
*
* RETURN VALUE
*   0       success
*   1       records were found in bPRSP for the PRCo, PRGroup, and PR Ending Date
*	5		regardless of whether records were found in bPRSP, the pay period is reserved by another user
**************************************************************************/
	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @inuseby bVPUserName output)

as
set nocount on

   declare @rcode int
   
   select @rcode = 0

	-- check for records in bPRSP for a given PRCo, PRGroup, and PR Ending Date
	if (select count(*) from dbo.bPRSP (nolock)	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate) > 0
		select @rcode = 1

	-- check to see if the pay period is reserved by another user
	select @inuseby = ''
	select @inuseby = InUseBy from dbo.bPRPC (nolock)
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and 
		InUseBy is not null and InUseBy <> SUSER_SNAME()
	if @@rowcount <> 0
		begin
		select @rcode = 5
		end

	 
	vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCheckProcessVerify] TO [public]
GO
