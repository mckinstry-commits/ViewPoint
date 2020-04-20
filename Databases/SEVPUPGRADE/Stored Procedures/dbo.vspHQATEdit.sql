SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[vspHQATEdit]
   /*****************************************************
   	Created: RM 06/08/04
   	Modified: 	RT 08/19/04 - #21497, add OrigFileName and increase filename to 512 bytes.
   				RT 09/21/04 - #21497, also remove transaction.
				JonathanP 05/01/07 - DocAttchYN will now be updated.
				JonathanP 02/05/08 - Updated to vspHQATEdit and added attachment auditing.
				JonathanP 04/18/08 - Issue #127708. Added @attachmentTypeID parameter. Passing a 0 sets the ID column in HQAT to null (no type).
									 Passing -1 preserves the current type.
   	Usage:
   		Used to change the path and/or description of a given attachment.
   		
   
   ******************************************************/
   (@attid int, @filename varchar(512), @desc VARCHAR(512), @origfilename varchar(512), 
    @docattchyn as char = 'N', @username as varchar(128), @attachmentTypeID as int = -1, 
    @errmsg varchar(255) output)
   as
   
   
	declare @rcode int
	select @rcode = 0
   
	DECLARE @previousDocName AS VARCHAR(512)    
	DECLARE @previousDescription AS VARCHAR(512)
	DECLARE @previousOriginalFileName AS VARCHAR(512)
	DECLARE @previousDocumentAttachmentYN AS char
	DECLARE @previousAttachmentTypeID AS INTEGER

	-- Get the previous values in bHQAT
	SELECT @previousDocName = DocName, @previousDescription = [Description], 
		@previousOriginalFileName = OrigFileName, @previousDocumentAttachmentYN = DocAttchYN,
		@previousAttachmentTypeID = AttachmentTypeID
	FROM [bHQAT]
	WHERE [AttachmentID] = @attid
   
   -- Update the bHQAT record.
	update bHQAT
	set DocName=@filename,
		Description=@desc,
		OrigFileName = @origfilename,
		DocAttchYN = @docattchyn,
		AttachmentTypeID = CASE WHEN @attachmentTypeID = 0 THEN NULL				-- 0 sets the column to null
								WHEN @attachmentTypeID = -1 THEN AttachmentTypeID   -- -1 preserves the current value
								ELSE @attachmentTypeID END                          -- Set the Attachment Type ID to @attachmentTypeID
	where AttachmentID=@attid
   
	if @@rowcount <> 1
	begin
   		set @rcode=1
   		set @errmsg='An error occurred while trying to update the attachment record.' 
   		GOTO bspExit
	end   
          
    -- Check if DocName changed.
	IF @previousDocName <> @filename
	BEGIN
		EXEC @rcode = dbo.[vspDMAttachmentAuditLogInsert]			
			@attachmentID = @attid, --  int
			@userName = @username, --  bVPUserName
			@fieldName = 'DocName',
			@oldValue = @previousDocName, --  varchar(255)
			@newValue = @filename, --  varchar(255)
			@event = 'Update', --  varchar(50)
			@errorMessage = @errmsg OUTPUT	
	END		          
            
	if @rcode <> 0
	begin   		
   		GOTO bspExit   		
	end  
	
	-- Check if the description changed.
	IF @previousDescription <> @desc
	BEGIN
		EXEC @rcode = dbo.[vspDMAttachmentAuditLogInsert]					
			@attachmentID = @attid, --  int
			@userName = @username, --  bVPUserName
			@fieldName = 'Description',
			@oldValue = @previousDescription, --  varchar(255)
			@newValue = @desc, --  varchar(255)
			@event = 'Update', --  varchar(50)
			@errorMessage = @errmsg OUTPUT	
	END		          
            
	if @rcode <> 0
	begin   		
   		GOTO bspExit   		
	end  
	
	-- Check if the original file name changed.
	IF @previousOriginalFileName <> @origfilename
	BEGIN
		EXEC @rcode = dbo.[vspDMAttachmentAuditLogInsert]			
			@attachmentID = @attid, --  int
			@userName = @username, --  bVPUserName
			@fieldName = 'OrigFileName',
			@oldValue = @previousOriginalFileName, --  varchar(255)
			@newValue = @origfilename, --  varchar(255)
			@event = 'Update', --  varchar(50)
			@errorMessage = @errmsg OUTPUT	
	END		          
            
	if @rcode <> 0
	begin   		
   		GOTO bspExit   		
	end    
	
	-- Check if the Document Attachment flag changed.
	IF @previousDocumentAttachmentYN <> @docattchyn
	BEGIN
		EXEC @rcode = dbo.[vspDMAttachmentAuditLogInsert]			
			@attachmentID = @attid, --  int
			@userName = @username, --  bVPUserName
			@fieldName = 'DocAttchYN',
			@oldValue = @previousDocumentAttachmentYN, --  varchar(255)
			@newValue = @docattchyn, --  varchar(255)
			@event = 'Update', --  varchar(50)
			@errorMessage = @errmsg OUTPUT	
	END		        
	
	
	-- Check if the Attachment Type ID changed.
	IF @previousAttachmentTypeID <> @attachmentTypeID
	BEGIN
		EXEC @rcode = dbo.[vspDMAttachmentAuditLogInsert]			
			@attachmentID = @attid, --  int
			@userName = @username, --  bVPUserName
			@fieldName = 'AttachmentTypeID',
			@oldValue = @previousAttachmentTypeID, --  varchar(255)
			@newValue = @attachmentTypeID, --  varchar(255)
			@event = 'Update', --  varchar(50)
			@errorMessage = @errmsg OUTPUT	
	END	  
            
	if @rcode <> 0
	begin   		
   		GOTO bspExit   		
	end   
   
   bspExit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQATEdit] TO [public]
GO
