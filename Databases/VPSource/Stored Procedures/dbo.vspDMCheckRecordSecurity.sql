SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE proc [dbo].[vspDMCheckRecordSecurity]  
     /**********************************************************  
     * Created:   
  * JonathanP 09/27/07 - Created. This code was initially taken from vspHQCreateIndex and modified.    
  *   
  * History:   
  * JonathanP 03/12/08 - Since we now have stand alone and archived attachments, we can have  
  *  HQAT records with no UniqueAttachmentID. So, in those cases we return true for this   
  *  method granting access.     
  * JonathanP 06/13/08 - See issue #128454. We now check to make sure a column name UniqueAttchID exists  
  *       linked tables before running "exec @rowCount = bspGetRowCount @selectstring"  
  * JonathanP 06/17/08 - See #128622. We return true if the CurrentState of the attachment is not 'A' (attached)  
  * JonathanP 04/24/09 - See #133091. We now check if the record does actually exist with viewpointcs permissions after  
  *          checking the users permissions. If the record does exist but they don't have access, we return 1.  
  *       If the record does not exist anymore, then return 0.  
  * RickM	  09/08/2010 - Issue #141164 - Run select as passed in user.
  * JacobV	  10/19/2010 - Issue #141299 - Update @hqattable, @realtable to varchar(128)
     *     
     * Usage:  
     *   Returns 0 if access is to the given attachment ID. The check is done by seeing if the user can  
  *   access any of the records that are associated with the attachment.  
     *  
     * Inputs:  
     *   attachmentID - The attachment ID.  
  *     
     * Outputs:  
     *   errorMessage - The error message to return if there is an error.  
     *  
     * Return Code:  
     *   errorCode - 0 on success, 1 on error or access denied.  
     *  
     ************************************************************/  
       
 (@hqattable varchar(128), @keystring varchar(255), @user varchar(255), @errorMessage varchar(255) = null output)  
        
 as        
    set nocount on   
  
 declare @selectstring varchar(max),@vcsselectstring varchar(max),   
   @realtable varchar(128), @rowCount int, @currentState CHAR, @returnCode int   
   
 select @returnCode = 0  

  
  
 -- Build a select statement that will get the records associated with the given UniqueAttchID from the HQAT record's table name. 
 select @vcsselectstring =  'Select * from ' + isnull(@hqattable,'') + ' with (nolock) where ' + @keystring
 select @selectstring = 'Execute as User=''' + @user + ''';' + @vcsselectstring
   
 -- Get the number of rows that come back when @selectstring is executed.  
 exec @rowCount = bspGetRowCount @selectstring  
  
 -- @rowCount will equal 0 if no rows were returned, but this may be because of the view security. We need to now check  
 -- if the row actually does exist in the table.  
 if @rowCount = 0  
 begin                    
  exec @rowCount = vspGetRowCountAsViewpointCS @vcsselectstring  
             
  if @rowCount > 0  
  begin  
   select @errorMessage = 'Access is denied for that user', @returnCode = 1     
   goto bspExit  
  end             
 end  
  
 while @rowCount = 0  
 begin  
      select @realtable = min(LinkedTable)  
      from vDDLT with (nolock)  
      where PrimaryTable = @hqattable and ((LinkedTable>@realtable) or @realtable is null)  
         
      if @realtable is null  
      begin  
       select @errorMessage = 'Could not find record for this attachment.'         
       goto bspExit  
      end  
                      
    -- check for existence in linked table  
      select @selectstring='select 1 from ' + isnull(@realtable,'') + ' with (nolock) where ' + @keystring
         
       -- See issue #128454  
       if exists(select top 1 1 from sys.syscolumns where id = object_id(@realtable) and name = 'UniqueAttchID')  
       begin  
        -- Check if the a record exists with the given attachment ID (view security is enforced)  
        exec @rowCount = bspGetRowCount @selectstring  
                  
        -- @rowCount will equal 0 if no rows were returned, but this may be because of the view security. We need to now check  
        -- if the row actually does exist in the table.  
        if @rowCount = 0  
        begin                    
         exec @rowCount = vspGetRowCountAsViewpointCS @selectstring  
                    
         if @rowCount > 0  
         begin  
          select @errorMessage = 'Access is denied for that user', @returnCode = 1  
          goto bspExit  
         end             
        end  
       end  
 end       
  
 --  
 -- If we get to this point, then no errors occured and the record was found, so @returnCode will equal 0 denoting success.  
 --   
  
bspExit:  
 return @returnCode  
 

GO
GRANT EXECUTE ON  [dbo].[vspDMCheckRecordSecurity] TO [public]
GO
