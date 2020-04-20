SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 CREATE PROCEDURE [dbo].[vspVPMenuGetModules]  
/**************************************************  
* Created: GG 07/11/03  
* Modified: JRK 08/04/03 - Add checks for any form or report subfolder items the user has access to before saying a module is not accessible.  
*   GG 07/15/04 - removed vDDMO.ShowOnMenu, fix Access flag   
*   AL 08/26/08 - changed Subfolder check in cursor to use m.VPUserName rather then f.VPUserName  
*        Also added check to ensure that Show on menu is true  
*   GG 08/27/08 - rewrote module access checks, but after finding poor performance due to excessive SP execution  
*       I commented out those checks and simply return list of modules with Access set equal to Active flag 
*			DC 11/06/08 - Changed column, Modules are ORDER'd BY 
*  
* Used by VPMenu to list Viewpoint Modules   
*  
* Inputs:  
* @co   Company - needed for security checks  
*  
* Output:  
* resultset of Viewpoint Modules with access info  
* @errmsg  Error message  
*  
*  
* Return code:  
* @rcode 0 = success, 1 = failure  
*  
****************************************************/  
 (@co bCompany = null, @errmsg varchar(512) output)  
as  
  
set nocount on   
  
declare @rcode int, @user bVPUserName  
  
/*declare @openmodcursor tinyint, @openformcursor tinyint, @openreportcursor tinyint, @openitemcursor tinyint,  
 @mod char(2), @form varchar(30), @reportid int, @itemtype char(1), @menuitem varchar(30),  
 @title varchar(30), @active bYN, @access char(1) */  
  
if @co is null  
 begin  
 select @errmsg = 'Missing required input parameter: Company #', @rcode = 1  
 goto vspexit  
 end  
  
select @rcode = 0, @user = suser_sname() --, @openmodcursor = 0, @openformcursor = 0, @openreportcursor = 0, @openitemcursor = 0  
  
  
-- use a local table to hold all Modules  
--declare @allmods table([Mod] char(2), Title varchar(30), Active char(1), Access char(1))  
  
--insert @allmods ([Mod], Title, Active, Access)  
select [Mod], Title, Active, Active as [Access] -- case when @user = 'viewpointcs' then 'Y' else 'N' end -- assume no access unless user is viewpoint  
from vDDMO  
where [Mod] <> 'VP' and ([Mod] <> 'DD' or @user = 'viewpointcs')   
order by Title
  
/* -- GG - commented out code to used to determine users module access --  
  
if @user = 'viewpointcs' goto return_results -- Viewpoint system user has access to all modules  
  
-- create a cursor to process each active module to see if user has access  
declare vcMods cursor local fast_forward for  
select Mod from @allmods where Active = 'Y' -- skip inactive modules   
  
open vcMods  
select @openmodcursor = 1  
  
mod_loop: -- check Security for each Module  
 fetch next from vcMods into @mod  
 if @@fetch_status <> 0 goto end_mod_loop  
   
 -- need a cursor to check access to forms assigned to the module  
 declare vcForms cursor local fast_forward for  
 select m.Form   
  from DDMFShared m (nolock)  
 join DDFHShared h (nolock) on h.Form = m.Form  
 join vDDMO o (nolock) on h.Mod = o.Mod -- join on form's primary module  
 where m.Mod = @mod and m.Active = 'Y' and h.ShowOnMenu = 'Y'   
  and (o.LicLevel > 0 and o.LicLevel >= h.LicLevel)  
  
 open vcForms  
 set @openformcursor = 1  
  
 form_loop: -- loop to check form access   
  fetch next from vcForms into @form  
  if @@fetch_status <> 0 goto end_form_loop  
  
  exec @rcode = vspDDFormSecurity @co, @form, @access output, @errmsg = @errmsg output  
  if @rcode <> 0 goto vspexit  
    
  if @access in (0,1) -- break out if we find a form the user can access  
   begin  
   -- update module access  
   update @allmods set Access = 'Y' where [Mod] = @mod  
   -- cleanup cursor  
   close vcForms  
   deallocate vcForms  
   select @openformcursor = 0  
   goto mod_loop  
   end   
    
  goto form_loop -- loop back for another form in the module  
   
 end_form_loop: --  finished checking forms for the module, no accessible forms found  
  close vcForms  
  deallocate vcForms  
  select @openformcursor = 0  
    
 -- need a cursor to check access to reports assigned to the module  
 declare vcReports cursor local fast_forward for  
 select m.ReportID  
 from RPRMShared m (nolock)  
 join RPRTShared t on t.ReportID = m.ReportID  
 where m.Mod = @mod and m.Active = 'Y' and t.ShowOnMenu = 'Y'   
  
 open vcReports  
 set @openreportcursor = 1  
  
 report_loop: -- check Security for each Report  
  fetch next from vcReports into @reportid  
  if @@fetch_status <> 0 goto end_report_loop  
  
  exec @rcode = vspRPReportSecurity @co, @reportid, @access output, @errmsg = @errmsg output  
  if @rcode <> 0 goto vspexit  
    
  if @access = 0 -- break out if we find a report the user can access  
   begin  
   -- update module access  
   update @allmods set Access = 'Y' where [Mod] = @mod  
   -- cleanup cursor  
   close vcReports  
   deallocate vcReports  
   select @openreportcursor = 0  
   goto mod_loop  
   end   
   
  goto report_loop -- loop back for another report in the module  
  
 end_report_loop: --  finished checking reports for the module, no accessible reports found  
  close vcReports  
  deallocate vcReports  
  select @openreportcursor = 0  
    
 -- need a cursor to check access to subfolder items assigned to the module  
 declare vcItems cursor local fast_forward for  
 select ItemType, MenuItem   
  from dbo.vDDSI (nolock)  
 where Co = 0 and VPUserName = @user and [Mod] = @mod -- Co# 0 used for standard modules  
  
 open vcItems  
 set @openitemcursor = 1  
  
 item_loop: -- loop to check access   
  fetch next from vcItems into @itemtype, @menuitem  
  if @@fetch_status <> 0 goto end_item_loop  
  
  if @itemtype = 'F'  
   begin  
   exec @rcode = vspDDFormSecurity @co, @menuitem, @access output, @errmsg = @errmsg output  
   if @rcode <> 0 goto vspexit  
    
   if @access in (0,1) -- break out if we find a form the user can access  
    begin  
    -- update module access  
    update @allmods set Access = 'Y' where [Mod] = @mod  
    -- cleanup cursor  
    close vcItems  
    deallocate vcItems  
    select @openitemcursor = 0  
    goto mod_loop  
    end   
    
   goto item_loop -- loop back for another subfolder item in the module  
   end  
     
  if @itemtype = 'R'  
   begin  
   exec @rcode = vspRPReportSecurity @co, @menuitem, @access output, @errmsg = @errmsg output  
   if @rcode <> 0 goto vspexit  
     
   if @access = 0 -- break out if we find a report the user can access  
    begin  
    -- update module access  
    update @allmods set Access = 'Y' where [Mod] = @mod  
    -- cleanup cursor  
    close vcItems  
    deallocate vcItems  
    select @openitemcursor = 0  
    goto mod_loop  
    end   
    
   goto item_loop -- loop back for another subfolder item in the module  
   end  
     
 end_item_loop: --  finished checking subfolder items for the module, no accessible items found  
  close vcItems  
  deallocate vcItems  
  select @openitemcursor = 0  
    
  goto mod_loop  
  
end_mod_loop: --  all modules checked  
 close vcMods  
 deallocate vcMods  
 select @openmodcursor = 0  
  
return_results:  -- return 1st resultset of Modules  
 select [Mod], Title, Active, Access  
 from @allmods  
 order by Mod  
*/  
     
vspexit:  
 /*if @openmodcursor = 1  
  begin  
  close vcMods  
  deallocate vcMods  
  end  
 if @openformcursor = 1  
  begin  
  close vcForms  
  deallocate vcForms  
  end  
 if @openreportcursor = 1  
  begin  
  close vcReports  
  deallocate vcReports  
  end  
 if @openitemcursor = 1  
  begin  
  close vcItems  
  deallocate vcItems  
  end */  
  
 --if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuGetModules]'  
 return @rcode  
  
  
  
  
  
  
  
  
  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetModules] TO [public]
GO
