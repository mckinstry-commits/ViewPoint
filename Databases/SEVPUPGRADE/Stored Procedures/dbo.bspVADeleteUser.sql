SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   CREATE PROC [dbo].[bspVADeleteUser]
   /***********************************************************  
    * CREATED BY: DANF 10/31/01  
    * Modified  DANF 05/14/07 - 6.X Recode
    * Modified Dave C 06/18/09 - Issue# 132719 ADDED:
	*	Removed user entries from:
	*		VPQuerySecurity
	*		VAAttachmentTypeSecurity
	*		VPCanvasSettings
	*		VPCanvasTemplateSecurity
	*		VPPartSettings
	*		JBIDTMWork
	*		DDNotificationPrefs
	*	prior to delete from DDUP
    *  
    * USAGE:  
    *  Delete user form tables  
    *  
    * INPUT PARAMETERS  
    *   Date to purge through  
    *  
    * OUTPUT PARAMETERS  
    *   @msg      error message  
    * RETURN VALUE  
    *   0         success  
    *   1         failure  
    *****************************************************/  
   
   (@user bVPUserName, @msg varchar(60) output)
   as
   
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if isnull(@user,'') = ''
   	begin
   	select @msg = 'Missing User!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   /*Now delete user from the Viewpoint tables */  
     
   delete from ARAA where VPUserName = @user  
     
   delete from APWH where UserId = @user  
  
   delete from APWD where UserId = @user  
  
   delete from DDDU where VPUserName = @user  
     
   delete from DDTS where VPUserName = @user  
     
   delete from DDFS where VPUserName = @user  
  
   delete from DDFU where VPUserName = @user  
  
   delete from DDSI where VPUserName = @user  
     
   delete from DDSF where VPUserName = @user  
  
   delete from DDSU where VPUserName = @user  
  
   delete from DDUI where VPUserName = @user  
     
   delete from DDUL where VPUserName = @user  
  
   delete from DDWL where VPUserName = @user  
  
   delete from DDUC where VPUserName = @user  
  
   delete from DDUT where VPUserName = @user  

   delete from JCUO where UserName = @user  
  
   delete from INCW where UserName = @user  
     
   delete from PMDZ where UserName = @user  
  
   delete from PRGS where VPUserName = @user  
     
   delete from PRPE where VPUserName = @user  
     
   delete from PRUP where UserName = @user  
     
   delete from RPRS where VPUserName = @user  
  
   delete from RPUP where VPUserName = @user  
  
   delete from HQRP where VPUserName = @user
   
   delete from VPQuerySecurity where VPUserName = @user
   
   delete from VAAttachmentTypeSecurity where VPUserName = @user
      
   
   delete from VPCanvasTemplateSecurity where VPUserName = @user
   
	delete VPPartSettings  
	from VPPartSettings 
	INNER JOIN VPCanvasSettings ON dbo.VPPartSettings.CanvasId = dbo.VPCanvasSettings.KeyID
	where VPCanvasSettings.VPUserName = @user
   
   delete from VPCanvasSettings where VPUserName = @user
   
   delete from JBIDTMWork where VPUserName = @user
   
   delete from DDNotificationPrefs where VPUserName = @user
  
   delete from DDUP where VPUserName = @user  
   

   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVADeleteUser] TO [public]
GO
