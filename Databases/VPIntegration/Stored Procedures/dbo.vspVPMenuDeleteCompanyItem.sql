SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE            PROCEDURE [dbo].[vspVPMenuDeleteCompanyItem]
/**************************************************
* Created:  JK 12/10/03 - VP.NET
* Modified:
*
* Used by VPMenu to delete an item from a company-specific folder during
* a Cut or Delete menu action.
* The item represents a shortcut to a form the user is permitted to access.
*
* The key of DDSI is  co + username + mod + itemtype + menuitem.
* For company-specific items, we expect co > 0 and mod = '' and username = ''.
*
* Inputs
*	@co			Needed since we use the system connection.
*	@subfolder		Numeric id of subfolder for specified module.
*	@itemtype 		'F' (form) or 'R' (report)
*	@menuitem 		form name or report id
*
* Output
*	@errmsg
*
****************************************************/
	(@co bCompany = null, 
	 @subfolder smallint = null , @itemtype char(1) = null,
	 @menuitem varchar(30) = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@co is null or @subfolder is null or @itemtype is null or @menuitem is null) 
	begin
	select @errmsg = 'Missing required field:  co, subfolder, itemtype or menuitem.', @rcode = 1
	goto vspexit
	end

if (@co = 0) 
	begin
	select @errmsg = 'co must be > 0', @rcode = 2
	goto vspexit
	end

-- Delete the row with the supplied data.
DELETE FROM DDSI WHERE Co = @co and VPUserName='' and Mod = '' and SubFolder=@subfolder and ItemType=@itemtype and MenuItem=@menuitem
   
vspexit:
	return @rcode










GO
GRANT EXECUTE ON  [dbo].[vspVPMenuDeleteCompanyItem] TO [public]
GO
