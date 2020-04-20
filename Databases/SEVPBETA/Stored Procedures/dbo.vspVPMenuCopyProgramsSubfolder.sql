SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE          PROCEDURE [dbo].[vspVPMenuCopyProgramsSubfolder]
/**************************************************
* Created: JRK 05/27/2005
* Modified: JRK 07/12/2005 Needed to improve the select so only forms 
* 	that appear in the menu would be copied.  Was getting DDSI trigger error.
* JRK 06/19/2006 Use ROW_NUMBER function to set menu seq nbr, rather than zero.
*	
*
* Copies items from a Programs subfolder to a subfolder in DDSI.
* Used in VPMenu for subfolder copy-paste or drag-drop.
*
* Inputs:
*	@co 		Company to copy to
*	@from_mod 	Mod to copy Programs from
*	@to_mod 	Mod to copy to
*	@to_subfolder 	Subfolder number to copy to
*	@user		The user will be the same for From and To.
* Output:
*	@errmsg		Error message
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@co bCompany = null, 
	 @from_mod char(2) = null, @to_mod char(2) = null,
	 @to_subfolder smallint = null, @user bVPUserName = null, 
	 @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0


if @co is null  
or @from_mod is null or @to_mod is null 
or @to_subfolder is null
or @user is null
	begin
	select @errmsg = 'Missing required input parameter: co, from_mod, to_mod, to_subfolder, or user.', @rcode = 1
	goto vspexit
	end

insert into DDSI (Co, VPUserName, Mod, SubFolder, ItemType, MenuItem, MenuSeq)
select @co, @user, @to_mod, @to_subfolder, 'F', m.Form, ROW_NUMBER() OVER (ORDER BY h.Title)
from DDMFShared m
join DDFHShared h on h.Form = m.Form
where m.Mod = @from_mod and m.Active = 'Y' and h.ShowOnMenu = 'Y'
order by m.Form

vspexit:
if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuCopyProgramsSubfolder]'
return @rcode










GO
GRANT EXECUTE ON  [dbo].[vspVPMenuCopyProgramsSubfolder] TO [public]
GO
