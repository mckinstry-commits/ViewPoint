SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspHQATInsert]
    /*******************************************************************************
    * CREATED BY: GR 09/08/00
    * MODIFIED BY: RM 06/11/01 - Added Attachment ID to HQAT
    *		RM 07/15/02 - Fixed to look through DDLT
    *		RM 09/17/02 - Fixed so that it removes attachment from HQAT if there is an error.
    *		GG 10/03/02 - cleanup
    *		GF 01/29/04 - issue #20653 - added special code for form = 'PMChangeOrders' different tables
    *		RM 02/13/04 = #23061, Add isnulls to all concatenated strings
    *		RM 03/18/04 - #24019 - Added Tablename Parameter, Prepare for Grids.
    *		gf 04/07/04 - #24286 - expanded keyfield from 255 to 500.
    *		RM 06/15/04 - #24847 - expanded DocName from 128 to 512
    *		RT 08/19/04 - #21497 - added OrigFileName parameter to match new column in bHQAT.
    *		RM 11/16/05 - added uniqueattachid output to help with 6.x standards
    *		RM 12/13/05 - Changed to use vDDxx tables instead of DDxx tables
	*		JonathanP 04/30/07 - The DocAttchYN column will now be updated.
	*		RM 06/13/07 - #124729 - Modified to remove dependency on FormName, use sp_executesql, and clean up some old, unused code
    *       JonathanP 06/14/07 - When creating the index, we now call vspHQCreateIndex instead of bspHQCreateIndex 
    *		RM 03/06/08 - See issue 127343. Fixed error message when attachment IDs were over 5 characters.
    *		JonathanP 01/24/08 - Changed code that gets the next AttachmentID number to also look at DMDeletedAttachments table.
    *		JonathanP 02/05/08 - Added auditing
    *		JonathanP 03/06/08 - Changed @description from bDesc to varchar(255). See issue #120620
    *		JonathanP 03/12/08 - Removed DMDeletedAttachments related code since that table has been dropped.    
    *		JonathanP 03/21/08 - Issue #127497. Added @createAsStandAloneAttachment parameter for stand alone attachments.
    *		JonathanP 04/17/08 - Issue #127708. Added @attachmentTypeID parameter. Passing a 0 sets the ID column in HQAT to null (no type).
    *		CC		  07/07/08 - Issue #134469 - Corrected check for missing keyfield, changed error message for missing key field.
    *		JVH		  11/30/09 - Issue #136513 - Fixed sql to allow only one insert to HQAT at a time to prevent duplicate key errors
    *		CC		  03/04/10 - Issue #130945 - Add IsEmail field
    *		JVH       12/19/10 - Issue #141299 - Changed @tablename,@parenttable to varchar(128)
    *
    * Inserts a record into HQ Attachment table - called from frmAttachmentDetail
    *
    * Inputs:
    * 	@hqco          					HQ Company
    * 	@formname     					Name of the form to which the file will be attached
    * 	@keyfield      					Key of the parent form
    * 	@description   					Description
    * 	@addedby       					User name adding the attachment
    * 	@adddate       					Date the file was attached to the form
    * 	@docname      					Name of the attached file with the path
	*	@docattchyn						Pass in 'Y' to say this attachment is a document attachment (used in PM)
	*   @createAsStandAloneAttachment	'Y' makes this a stand alone attachment.
	*	@attachmentTypeID				The ID of the attachment type. 0 means no type (the column will be set to null)
    *
    * Output:	
    *	@attid			Attachment ID#
    *	@msg			Error message	
    *
    * Return code:
    *	@rcode			0 = success, 1 = failure
    *
    ********************************************************************************/
   	(@hqco bCompany = null, @formname varchar(30) = null, @keyfield varchar(500) = null,
    	 @description VARCHAR(255), @addedby varchar(128), @adddate bDate, @docname varchar(512),
   	 @tablename varchar(128) = null, @origfilename varchar(512), @attid int output, 
	 @uniqueattchid uniqueidentifier = null output, @docattchyn char = 'N', 
	 @createAsStandAloneAttachment bYN = 'N', @attachmentTypeID int = 0, @IsEmail bYN = 'N', @msg varchar(100) output)
   
   as
    
   set nocount on      
   
   
   declare @rcode int, @seq int,@parenttable varchar(128),
   	@guid uniqueidentifier,@rc int,@newkey varchar(500), @sqlstring varchar(1000)   	
   
   declare @i int, @maxgridseq int, @currentgridseq int, @gridpos int,
   	@gridformname varchar(30)
   
   select @rcode = 0, @seq = 0
        
	if @docname is null
	begin
		select @msg = 'Missing Doc Name', @rcode = 1
		goto bspexit
	end        
    
	if @origfilename is null
	begin
		select @msg = 'Missing the original file name', @rcode = 1
		goto bspexit
	end
	
	-- checks for a non stand alone document
	if @createAsStandAloneAttachment <> 'Y'
	begin
	   if @hqco is null
   		begin
		   select @msg='Missing HQ Company', @rcode=1
		   goto bspexit
		   end
	   if @formname is null
		   begin
		   select @msg='Missing Form Name', @rcode=1
		   goto bspexit
		   end
	   if ISNULL(@keyfield,'') = ''
		   begin
		   select @msg='Missing Key Field, record may need to be saved first.', @rcode=1
		   goto bspexit
		   end  	
	end
	
	-- Begin a transaction so we can use the UPDLOCK to prevent inserting non unique records
	begin tran
	
		-- Get the next attachment ID  		   
		select @attid = isnull(max(AttachmentID),0) + 1
		from bHQAT (UPDLOCK)
	
	    if @createAsStandAloneAttachment = 'Y'
		begin
			-- add HQ Attachment as stand alone attachment
			insert bHQAT (AttachmentID, HQCo, FormName, KeyField, [Description],
				AddedBy, AddDate, DocName, TableName, OrigFileName, DocAttchYN, 
				CurrentState, AttachmentTypeID, IsEmail)
			values (@attid, @hqco, '', '', @description, @addedby, @adddate, 
				@docname, '', @origfilename, isnull(@docattchyn, 'N'), 'S', 
				case when @attachmentTypeID = 0 then null else @attachmentTypeID end, @IsEmail)     
		end
		else
		begin
		   -- add HQ Attachment without UniqueAttchID
		   insert bHQAT (AttachmentID, HQCo, FormName, KeyField, Description,
			   AddedBy, AddDate, DocName, TableName, OrigFileName, DocAttchYN, 
			   CurrentState, AttachmentTypeID, IsEmail)
		   values (@attid, @hqco, @formname, @keyfield, @description,
			   @addedby, @adddate, @docname, @tablename, @origfilename, @docattchyn, 'A', 
			   case when @attachmentTypeID = 0 then null else @attachmentTypeID end, @IsEmail)     
		end
		
	commit tran
	
	if @createAsStandAloneAttachment = 'Y'
	begin
   		-- Audit the add in DMAttachmentAuditLog.
		EXEC @rcode = dbo.[vspDMAttachmentAuditLogInsert] 
			@attachmentID = @attid, --  int	
			@userName = @addedby, --  bVPUserName
			@fieldName = null,
			@oldValue = null, --  varchar(255)
			@newValue = @origfilename, --  varchar(255)
			@event = 'Add', --  varchar(50)
			@errorMessage = @msg
	
		-- Since this is all we need to do, jump to the end	(I don't like gotos, but it is appropriate here)
		goto bspexit
	end
   
   -- reformat key field
   select @newkey =  dbo.bfFixKeyString(@keyfield, @tablename)

   -- check for existence of record in form's primary table, should
   -- always exist unless attachment is added without using Viewpoint software
   select @sqlstring = 'select 1 from ' + isnull(@tablename,'') + ' where ' + isnull(@newkey,'')

  exec(@sqlstring)
    select @rc = @@rowcount
    if @rc = 0	-- record does not exist in primary table
		begin
 			select @msg = 'No records were found that match the keystring supplied.',@rcode = 1
			delete bHQAT where AttachmentID = @attid	-- cleanup
 			goto bspexit
 		end
	if @rc > 1
		begin
			begin
     		select @msg = 'Multiple records were found that match the keystring supplied.',@rcode = 1
    		delete bHQAT where AttachmentID = @attid 
     		goto bspexit
     		end
		end
    if @rc = 1	-- a single record found
 		begin
			if not exists(select 1 from syscolumns where name='UniqueAttchID' and id=object_id(@tablename))
 				begin
 					select @msg = 'This table is not setup to allow attachments.',@rcode = 1
 					delete bHQAT where AttachmentID = @attid 
 					goto bspexit
 				end
		end
   
  -- update UniqueAttchId in new Attachment entry, will pull existing guid if one exists and
    -- will be null if first attachement added to record 
    select @sqlstring = 'update HQAT set UniqueAttchID=(select UniqueAttchID from ' + isnull(@tablename,'')
    	+ ' where ' + isnull(@newkey,'') + '), TableName=''' + isnull(@tablename,'') + '''  where AttachmentID = ' + convert(varchar, @attid)
 
    exec(@sqlstring)
    
   -- if UniqueAttchId in new Attachment entry is null, generate a new one and update it to table record
   if exists(select * from bHQAT where AttachmentID = @attid and UniqueAttchID  is null)
    	begin
   	-- generate a new guid for UniqueAttchID
   	select @guid = newID()
    	select @sqlstring = 'update ' +  isnull(@tablename,'') + ' set UniqueAttchID  = '''
   		+ isnull(convert(varchar(500),@guid),'') + ''' where ' + isnull(@newkey,'')

    	exec(@sqlstring)
    	update bHQAT set UniqueAttchID = @guid where AttachmentID = @attid
   	if @@rowcount <> 1
   		begin
   		select @msg = 'Update to bHQAT failed!', @rcode = 1
   		delete bHQAT where AttachmentID = @attid	-- cleanup
   		goto bspexit
   		end
    	end

    --return UniqueAttachID in case the form needs it.
    select @uniqueattchid=UniqueAttchID from HQAT where AttachmentID=@attid

   --create indexes
   exec @rcode = vspHQCreateIndex @attid,'Y',@msg output
   if @rcode <> 0
    	begin
    	--select @msg = 'Create Indexes Failed.',@rcode = 1
       	goto bspexit
    end
    
    -- Audit the add in DMAttachmentAuditLog.
    EXEC @rcode = dbo.[vspDMAttachmentAuditLogInsert] 
	@attachmentID = @attid, --  int	
	@userName = @addedby, --  bVPUserName
	@fieldName = null,
	@oldValue = null, --  varchar(255)
	@newValue = @origfilename, --  varchar(255)
	@event = 'Add', --  varchar(50)
	@errorMessage = @msg

	if @rcode <> 0
    	begin
    	select @msg = 'Could not audit this insert into the audit table.',@rcode = 1
    	goto bspexit
    end
        

  bspexit:
        if @rcode<>0 select @msg = isnull(@msg,'') + char(13) + char(10) +  '[vspHQATInsert]'
        return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspHQATInsert] TO [public]
GO
