SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE     proc [dbo].[vspVADDSGUsersGet]
/********************************
* Created: MJ 02/15/05  
* Modified:	
*
* Used to retrieve available users to add to security
* groups as well as group members.
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
	
select @rcode = 0
exec [vspVADDUsersGet]
-- get all users from DDUP
/*
select u.VPUserName
from vDDUP u
order by u.VPUserName 
*/

-- get users just for this security group 
select u.VPUserName
from vDDSU u
where SecurityGroup = @group
order by u.VPUserName 
-- get user property overrides 

bspexit:
	return @rcode
















GO
GRANT EXECUTE ON  [dbo].[vspVADDSGUsersGet] TO [public]
GO
