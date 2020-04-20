SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                       PROCEDURE [dbo].[vspDDGetUsersDefaultCompany]
/**************************************************
* Created:  JK 06/20/2005
* Modified: AL 10/13/2011: Added UserType to the where clause to prevent Connects 
*						   Only users from logging into V6
*
* Retrieves a user's default company.  Used when validating user at login time.
*
* Inputs:  All will default to "all".
*       @username		VPUserName used when logging in.
*
* Output
*	selected value of DefaultCompany	
*
****************************************************/
	(@username bVPUserName = null)
as

set nocount on 


/*
-- Do case-insensitive username lookup if trusted connection;
-- Ie, if there is a backslash, then it is trusted connection.
if charindex('\',@username) = 0
	begin
	--Not found so case-sensitive.
	select DefaultCompany 
	from DDUP
	where @username = VPUserName
	end
else
	begin
	--Found so case-insensitive.
	select DefaultCompany 
	from DDUP
	where lower(@username) = lower(VPUserName)
	end
*/
/*
-- This is what we had before putting in the "if charindex" function.
select DefaultCompany 
from DDUP
where @username = VPUserName
*/


select DefaultCompany 
from DDUP with (nolock)
where @username = VPUserName AND UserType <> 1
GO
GRANT EXECUTE ON  [dbo].[vspDDGetUsersDefaultCompany] TO [public]
GO
