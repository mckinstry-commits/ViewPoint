SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE        PROCEDURE [dbo].[vspVPMenuCopySubfolder]
/**************************************************
* Created: JRK 05/27/2005
* Modified: 
*	
*
* Copies items from one subfolder to another within DDSI.
* Used in VPMenu for subfolder copy-paste or drag-drop.
*
* Inputs:
*	@from_co 	Company to copy from
*	@to_co 		Company to copy to
*	@from_mod 	Mod to copy from
*	@to_mod 	Mod to copy to
*	@from_subfolder Subfolder to copy from
*	@to_subfolder 	Subfolder to copy to
*	@from_user	
*	@to_user	
* Output:
*	@errmsg		Error message
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@from_co bCompany = null, @to_co bCompany = null,
	 @from_mod char(2) = null, @to_mod char(2) = null,
	 @from_subfolder smallint = null, @to_subfolder smallint = null, 
	 @from_user bVPUserName = null, @to_user bVPUserName = null, 
	 @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0


if @from_co is null or @to_co is null 
or @from_mod is null or @to_mod is null 
or @from_subfolder is null or @to_subfolder is null
or @from_user is null or @to_user is null
	begin
	select @errmsg = 'Missing required input parameter: from_co, to_co, from_mod, to_mod, from_subfolder, to_subfolder, from_user or to_user.', @rcode = 1
	goto vspexit
	end

insert into DDSI (Co, VPUserName, Mod, SubFolder, ItemType, MenuItem, MenuSeq)
select @to_co, @to_user, @to_mod, @to_subfolder, ItemType, MenuItem, MenuSeq
from DDSI
where Co=@from_co and Mod=@from_mod and SubFolder=@from_subfolder and VPUserName = @from_user
order by MenuSeq


vspexit:
if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuCopySubfolder]'
return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspVPMenuCopySubfolder] TO [public]
GO
