SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE      PROCEDURE [dbo].[vspVPMenuGetDDSIItems]


/**************************************************
* Created: JRK 10/14/03
* Modified: JRK 02/03/04 - If-Else for selecting company items versus user items.
* Modified: JRK 03/08/06 - Use DDSI instead of vDDSI.
*
* Used by VPMenu to temporarily populate a datatable with DDSI rows
* in order to update their MenuSeq fields.  This is done after the
* user has used drag-drop to resequence items in a user folder.
*
* Inputs:
*	@co			Company will be 0 for user items, and >0 for company items.
*	@user			Have to pass in the user's login id since this uses the system connection.
*	@mod			Module - empty for 'My Viewpoint'
*	@subfolder		Sub-Folder ID# - 0 used for module level items
*
* Output:
*	resultset of users' accessible items for the sub folder
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@co bCompany = null, @user bVPUserName = null, @mod char(2) = null,
	 @subfolder smallint = null, @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int, @itemtype char(1), @menuitem varchar(30),
	@reportid int

if @co is null or @user is null or @mod is null AND @subfolder is null
	begin
	select @errmsg = 'Missing required input parameters: Company #, User, Module, and/or Sub-Folder!', @rcode = 1
	goto vspexit
	end

select @rcode = 0	--not used at this point.

if @co = 0
	begin
	select Co, VPUserName, Mod, SubFolder, ItemType, MenuItem, MenuSeq from DDSI
	where VPUserName = @user and Mod = @mod and SubFolder = @subfolder   
   	end
else
	begin
	select Co, VPUserName, Mod, SubFolder, ItemType, MenuItem, MenuSeq from DDSI
	where Co = @co and SubFolder = @subfolder   
   	end

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuGetDDSIItems]'
	return @rcode










GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetDDSIItems] TO [public]
GO
