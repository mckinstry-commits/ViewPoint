SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE           PROCEDURE [dbo].[vspVPMenuDeleteLinks]
/**************************************************
* Created: JRK 07/11/2005
*
* Used by regular users to delete their links in table vDDWL.
*
*
* Inputs:
*	@name			Link's name
* Output:
*	@errmsg		Error message
*
* Return code:
*	@rcode			Number of rows deleted
*
****************************************************/
	(@name varchar(60), @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int, @user bVPUserName

select @rcode = 0, @user = suser_sname() -- Get the user id from the connection.

DELETE FROM vDDWL 
WHERE VPUserName = @user and [Name] = @name

SELECT @rcode = @@rowcount

/*
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuUpdateLinks]'
*/

return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspVPMenuDeleteLinks] TO [public]
GO
