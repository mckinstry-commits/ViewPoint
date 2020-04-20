SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE  PROCEDURE [dbo].[vspDMCheckAttachmentTypeSecurity]  
/********************************************************  
 * Created: JonathanP 04/28/08 - See issue #127475. Created for attachment type security.    
 * Modified:    
 *			JonathanP 05/29/08 - See issue #  
 *			JeremiahB 1/14/10	#128753	- Added the VPUserName parameter.
 *  
 * Used to determine attachment type security level for a specific   
 * attachment ID and user.  
 *  
 * Inputs:  
 * @company   Currently ignored.   
 * @attachmentID  Attachment ID  
 *   
 * Outputs:  
 * @accessLevel  Access level: 0 = full, 2 = denied, null = missing  
 * @errorMessage  Error message  
 *  
 * Return Code:  
 * @returnCode   0 = success, 1 = error  
 *  
 *********************************************************/  
  
 (@attachedcompany int, @attachmenttypeid int, @user bVPUserName, 
  @access tinyint output, @errorMessage varchar(512) output)  
as  
  
set nocount on  
  
declare @returnCode int  
select @returnCode = 0  

if @attachmenttypeid is not null  
begin  
 -- Check the attachment security for that type and return the result.  
 exec @returnCode = dbo.vspVAAttachmentTypeSecurity @attachedcompany, @attachmenttypeid, @user, @access output, @errorMessage output  
end  
  
return @returnCode  
GO
GRANT EXECUTE ON  [dbo].[vspDMCheckAttachmentTypeSecurity] TO [public]
GO
