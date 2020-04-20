SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHQATDelete]
   /*******************************************************************************
   * CREATED BY: GR 09/13/00
   * MODIFIED BY: TV 11/02/01 - The formatting is all messed up for the delete...issue 15030
   *				RM/TV 02/21/02 - Changed input parameters to use AttachmentID instead of
   *								 All of the others in an attempt to remove the keystring from HQAT
   *				RT 09/24/03 - #21492, delete records from HQDR (doc routing) when attachments are deleted.
   *				RM 02/13/04 - #23061, Add isnulls to all concatenated strings
   *				RT 04/13/04 - #24330, Check for existence of UniqueAttchID column before updating.
   *				RM 09/20/05 - Changed to vsp procedure for 6.x changes   
   *				JonathanP 02/06/07 - Updated to now have the username for auditing.
   *				JonathanP 03/11/08 - Modified to handle stand alone attachments and archiving.   
   *				JonathanP 03/28/08 - See #127605. Changed ArchiveDeletedAttachmentInfo to ArchiveDeletedAttachments
   *				JonathanP 04/18/08 - Added "and @currentState <> 'D'" to check if the attachment to be deleted is 
   *								     alredy in the deleted state. If it is, we delete it.   
   *			    JonathanP 03/30/09 - See #3127603. Added the statement at the bottom of this procedure to clean up vDMAttachmentDeletionQueue.
   *				JonathanP 01/12/10 - See #131182. Removed the delete from bHQAF
   *				JVH 10/19/2010	- #141299 Updated @tablename,@parenttable to varchar(128)
   *
   * Deletes a record into HQ Attachment table - called from frmAttachment
   *
   * Inputs:  
   *		@attid - The Attachment ID of the attachment to delete.
   *
   *		@username - Name of the user who called this method. Mainly used for auditing.
   *
   *		@deletedFromRecord - If the attachment was attached to a record, and the record 
   *			was deleted (as opposed to the attachment being deleted specifically), this 
   *			should be true.
   *
   *		@existsInHQAT - An output parameter. Equals 'Y' if the attachment was actually 
   *			deleted from HQAT. If it equals 'N', then the attachment was changed to a 
   *			stand alone attachment, archived, or didn't get deleted for some other reason.
   *
   *		@msg - An output parameter. Used to return error messages.
   *
   * Error returns:
   *  1 and error message
   *
   ********************************************************************************/
   (@attid int, @username VARCHAR(128) = NULL, @deletedFromRecord bYN = 'N', @existsInHQAT bYN = 'Y' output, @msg varchar(255) output)
   as
       set nocount on
       declare @rcode int
       select @rcode=0
   

  declare @uniqueid varchar(500), @tablename varchar(128), @parenttable varchar(128), @sql varchar(1000),
  		@ColExist INT, @originalFileName AS VARCHAR(512), @currentState AS char
  
  select @uniqueid = UniqueAttchID, 
		 @parenttable = ISNULL(TableName, ''), 
		 @originalFileName = OrigFileName, 
		 @currentState = CurrentState 
  from bHQAT 
  where AttachmentID=@attid
  
  if @attid is null
  begin
	return
  end
  
   if @uniqueid <> '' AND (not exists(select * from bHQAT where UniqueAttchID=@uniqueid and AttachmentID<>@attid))
  	begin
  		set @sql='Update ' + isnull(@parenttable,'') + ' set UniqueAttchID=null where UniqueAttchID=''' + isnull(@uniqueid,'') + ''''
  		exec(@sql)
  TryAgain:
  		select @tablename = min(LinkedTable) from DDLT where PrimaryTable=@parenttable and ((LinkedTable>@tablename) or @tablename is null)
  		if @tablename is not null
  		begin
  			--Issue #24330, check to see if table has column UniqueAttchID first.
  			select @ColExist = count(*) from syscolumns where object_name(id) = @tablename and name = 'UniqueAttchID'
  			if @ColExist > 0 
  			begin
  				set @sql='Update ' + isnull(@tablename,'') + ' set UniqueAttchID=null where UniqueAttchID=''' + isnull(@uniqueid,'') + ''''			

  				exec(@sql)
  			end
  			goto TryAgain
  		end 
  	end
  	  	
  	-- Get some of the attachment option flags from HQAO.
	DECLARE @createStandAloneOnDelete AS bYN, @archiveDeletedAttachment AS bYN, @useAuditing AS bYN
	SELECT TOP 1 @createStandAloneOnDelete = [CreateStandAloneOnDelete],
				 @archiveDeletedAttachment = [ArchiveDeletedAttachments],
				 @useAuditing = [UseAuditing]				 
	FROM bHQAO
  	
  	-- If @deletedFromRecord is 'Y', then the most vspHQATDelete will do from here is change an attachment 
  	-- from being attached to being a stand alone attachment. 
	IF @deletedFromRecord = 'Y'
	BEGIN			
		-- Change the attachment to a stand alone attachment if need be.
		IF @createStandAloneOnDelete = 'Y' AND @currentState = 'A'
		BEGIN
			-- Update the attachment record to be a stand alone attachment.
			UPDATE bHQAT 
			SET [UniqueAttchID] = NULL, [CurrentState] = 'S' 
			WHERE [AttachmentID] = @attid
			
			-- Audit the conversion to a stand alone attachment..     		
			EXEC @rcode = dbo.[vspDMAttachmentAuditLogInsert]					
				 @attachmentID = @attid, --  int
				 @userName = @username, --  bVPUserName
				 @fieldName = null,
				 @oldValue = null, --  varchar(255)
				 @newValue = null, --  varchar(255)
				 @event = 'Changed to Stand Alone Attachment', --  varchar(50)
				 @errorMessage = @msg OUTPUT				    					
		    			
			-- The attachment was changed to a stand alone attachment, so leave this procedure.
			GOTO bspexit
		END
	END
		
	-- Check if we should set the attachment to the deleted state. If it is already in the deleted 
	-- state, we delete it.
	IF @archiveDeletedAttachment = 'Y' and @currentState <> 'D'
	BEGIN
		-- Update the attachment record to be in the deleted state.
		UPDATE bHQAT 
		SET [UniqueAttchID] = NULL, [CurrentState] = 'D' 
		WHERE [AttachmentID] = @attid
		
		-- Audit the fact that the attachment has been marked as deleted.
		EXEC @rcode = dbo.[vspDMAttachmentAuditLogInsert]					
			 @attachmentID = @attid, --  int
			 @userName = @username, --  bVPUserName
			 @fieldName = null,
			 @oldValue = null, --  varchar(255)
			 @newValue = null, --  varchar(255)
			 @event = 'Archived', --  varchar(50)
			 @errorMessage = @msg OUTPUT				
	END		
	
	-- Delete the attachment since we are not going to archive it.
	ELSE
	BEGIN			
		-- Delete the attchment	
		delete bHQAT
		where AttachmentID=@attid
		
		SELECT @existsInHQAT = 'N'

		if @@rowcount=0
		   begin
		   select @msg='Could not delete a record', @rcode=1
		   goto bspexit
		   end
		    
		if @rcode <> 0
		begin   		
			GOTO bspexit   		
		end  

		--issue #21492
		delete bHQDR
		where AttachmentID=@attid

		-- bHQAF can now exist in another database. This deletion should happen in the remote service.
		--delete bHQAF where AttachmentID=@attid
			
	END


   bspexit:
	   
	   -- Delete the attachment record from the AttachmentDeletionQueue if it exists.
	   delete from vDMAttachmentDeletionQueue where AttachmentID = @attid
   
   
       if @rcode<>0 select @msg = isnull(@msg,'') + char(13) + char(10) + '[vspHQATDelete]'
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQATDelete] TO [public]
GO
