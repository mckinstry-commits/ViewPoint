SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDUserFormUpdate]  
/********************************  
* Created: kb 2/9/4  
* Modified: GG 04/22/04 - changed vDDUF to vDDFU, added SplitPosition  
*   mj 8/30/05 - added Options to the list of items to save  
*	DC 10/20/2008 -129914- added @FilterOption parameter to update FilterOption
*   kene 1/13/2012 -  added @OpenAttachmentViewer parameter to update OpenAttachmentViewer
* Called from the VPForm Class to save the form size and  
* position of a form by user.  
*  
* Input:  
* @form    Form   
* @position   Comma delimited string of top, left, width, height  
* @rowheight   grid row height  
* @splitpos   Split position value  
* @options   Form options - specific to form  
*  
* Output:  
* @errmsg  error message  
*  
* Return code:  
* 0 = success, 1 = failure  
*  
*********************************/  
 (@form varchar(30) = null, @position varchar(20) = null, @rowheight smallint = 0,  
  @splitpos int = null, @options varchar(256) = null, @FilterOption bYN = null, 
  @OpenAttachmentViewer bYN = 'N', @errmsg varchar(256) output)  
as  
  
set nocount on  
  
declare @rcode int  
select @rcode = 0  
  
-- try to update existing user entry  
update dbo.vDDFU  
set FormPosition = @position, GridRowHeight = @rowheight, SplitPosition = @splitpos,  
 Options = @options, LastAccessed = getdate(), FilterOption = @FilterOption, OpenAttachmentViewer = @OpenAttachmentViewer
where VPUserName = suser_sname() and Form = @form   
if @@rowcount = 0  
 begin  
 -- add new entry  
 insert dbo.vDDFU (VPUserName, Form, DefaultTabPage, FormPosition, LastAccessed, GridRowHeight,  
  SplitPosition, Options, FilterOption, OpenAttachmentViewer)  
 select suser_sname(), @form, null, @position, getdate(), @rowheight,  
  @splitpos, @options, @FilterOption, @OpenAttachmentViewer
 end  
  
vspexit:  
 return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDUserFormUpdate] TO [public]
GO
