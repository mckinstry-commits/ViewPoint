SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE     proc [dbo].[vspVADDSGGroupUsersGet]
/********************************
* Created: JRK 09/26/06  
* Modified:	
*
* Used to retrieve security group members.
*
* Input:
*	@group		security group

* Output:
*	1st resultset - available users  
*	2nd resultset - group members
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@group varchar(30))
as
	
set nocount on
	
declare @rcode int

-- get users just for this security group 
select u.VPUserName
from vDDSU u
where SecurityGroup = @group
order by u.VPUserName 
-- get user property overrides 

bspexit:
	return @rcode
















GO
GRANT EXECUTE ON  [dbo].[vspVADDSGGroupUsersGet] TO [public]
GO
