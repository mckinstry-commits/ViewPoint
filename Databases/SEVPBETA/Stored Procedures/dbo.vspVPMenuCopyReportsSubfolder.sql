SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE         PROCEDURE [dbo].[vspVPMenuCopyReportsSubfolder]
/**************************************************
* Created: JRK 06/06/2005
* Modified: JRK 06/19/2006 Use ROW_NUMBER function to set menu seq nbr, rather than zero.
*	
*
* Copies items from a Reports subfolder to a subfolder in DDSI.
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
select @co, @user, @to_mod, @to_subfolder, 'R', m.ReportID, ROW_NUMBER() OVER (ORDER BY t.Title)
from RPRMShared m
join RPRTShared t on t.ReportID = m.ReportID
where m.Mod = @from_mod and m.Active = 'Y' and t.ShowOnMenu = 'Y' 
order by m.ReportID

--from vRPRM
--where Mod=@from_mod

/*
from RPRMShared m
join RPRTShared t on t.ReportID = m.ReportID
left outer join vRPUP u on u.ReportID = m.ReportID and u.VPUserName = @user
--left outer join DDSI si on si.MenuItem = t.ReportID and si.Co = @co and si.VPUserName = @user and si.Mod = @mod and si.SubFolder = -1
where m.Mod = @mod and m.Active = 'Y' and t.ShowOnMenu = 'Y' 
*/

vspexit:
if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuCopyReportsSubfolder]'
return @rcode









GO
GRANT EXECUTE ON  [dbo].[vspVPMenuCopyReportsSubfolder] TO [public]
GO
