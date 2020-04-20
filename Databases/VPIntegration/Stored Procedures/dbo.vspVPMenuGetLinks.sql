SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE                  PROCEDURE [dbo].[vspVPMenuGetLinks]
/**************************************************
* Created:  JK 07/07/05
* Modified: JK 07/29/03
*
* Used by VPMenu to retrieve the "links" (URLs) for a specified user.
* Used with a user connection so the VPUserName is determined.
* 
* Inputs
*       none
*
* Output
*	@errmsg
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 
declare @rcode int, @user bVPUserName

select @rcode = 0, @user = suser_sname() -- Get the user id from the connection.

/*
 Even though we know the VPUserName, get it too because when we do an insert
 later we'll need it for the Insert command of the data adapter.
*/

SELECT VPUserName, [Name], Address, Seq FROM vDDWL 
WHERE VPUserName = @user
ORDER BY Seq
   
vspexit:
	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetLinks] TO [public]
GO
