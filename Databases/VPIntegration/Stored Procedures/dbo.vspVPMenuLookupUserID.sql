SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE         PROCEDURE [dbo].[vspVPMenuLookupUserID]
/**************************************************
* Created: JRK 06/13/2005
* Modified: 
*
* Used during login to verify the existence of a user ID.
*
* Inputs:
*	<none>
*
* Output:
*	resultset	Just the VPUserName.
*	@errmsg		Error message

*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @user bVPUserName

select @user = suser_sname()

return_results:		-- return resultset
	select VPUserName
	from DDUP
	where VPUserName = @user
   







GO
GRANT EXECUTE ON  [dbo].[vspVPMenuLookupUserID] TO [public]
GO
