SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE     proc [dbo].[vspVADDUsersGet]
/********************************
* Created: MJ 04/6/06  
* Modified:	
*
* Used to retrieve available users 
*
* Input:
*	
* Output:
*	1st resultset - available users  
*	*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/

as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0

-- get all users from DDUP
select u.VPUserName
from vDDUP u
order by u.VPUserName 

-- get user property overrides 

bspexit:
	return @rcode
















GO
GRANT EXECUTE ON  [dbo].[vspVADDUsersGet] TO [public]
GO
