SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE Proc [dbo].[vspPMHIInsert]
/*******************************
 * Created By:	SP 12/11/2012 6.6
 * Modified By:	AW 1/6/2014 TFS 70345 Adding Body to message.
 *
 * Purpose of stored procedure is to insert or update the document audit tables
 * with create and send information. The information will go into PMHI, the document (if any)
 * will go into PMHF, and attachment id's will go into PMHA for the audit record.
 *
 *
 *******************************/
(@username bVPUserName, @vendorgroup bGroup, @senttofirm bVendor = null, @senttocontact bEmployee = null,
 @sourcetablename varchar(50), @sourcekeyid bigint,
 @email varchar(100) = null, @fax bPhone = null, @faxaddress varchar(100) =  null, @subject varchar(255) = null,
 @ccaddresses varchar(500) = null, @bccaddresses varchar(500) = null,
 @filename varchar(255) = null, @filedata varbinary(max) = null,
 @attachlist varchar(max) = null,
 @isemailed varchar(1), @isfaxed varchar(1), @isprinted varchar(1), @body varchar(max) = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @pmdoccreateauditid bigint, @complete tinyint, @char char(1), @commapos int,
		@attachcommapos int, @retstring varchar(max), @retstringlist varchar(max),
		@attachmentid bigint

select @rcode = 0, @complete = 0

BEGIN TRY

	begin transaction

		---- insert PMHI (audit info) record
		insert PMHI(SourceTableName, SourceKeyId, CreatedBy, VendorGroup,
					SentToFirm, SentToContact, EMail, Fax, FaxAddress, Subject, CCAddresses,
					bCCAddresses, Emailed, Faxed, Printed, Body)
		select @sourcetablename, @sourcekeyid, @username, @vendorgroup,
			   @senttofirm, @senttocontact, @email, @fax, @faxaddress, @subject, @ccaddresses,
			   @bccaddresses, @isemailed, @isfaxed, @isprinted,@body

		---- get PMHI.KeyID
		select @pmdoccreateauditid = SCOPE_IDENTITY()

		---- insert PMHF (audit file image) record
		if @filedata is not null
			begin
			insert PMHF(PMHIKeyId, FileName, FileData)
			select @pmdoccreateauditid, @filename, @filedata
			end

		if @attachlist is not null
			begin
			while @complete = 0
				BEGIN
  				---- get attachment id
  				select @char = ','
  				exec dbo.bspParseString @attachlist, @char, @commapos output, @retstring output, @retstringlist output, @msg output
  				select @attachmentid = convert(bigint,@retstring)
  				select @attachlist = @retstringlist
  				select @attachcommapos = @commapos
	  
  				if isnull(@attachmentid,'') <> ''
  					begin
  					---- insert PMHA (audit attachment id) record
					insert PMHA(PMHIKeyId, AttachmentID)
					select @pmdoccreateauditid, @attachmentid
					end

				if @attachcommapos = 0 select @complete = 1
				END
			end
		
		commit transaction
		select @msg = 'Distribution audit has been successfully added.'
		goto bspexit

END TRY

BEGIN CATCH
	begin
	IF @@TRANCOUNT > 0
		begin
		rollback transaction
		end
	select @msg = 'Distribution audit insert/update failed. ' + ERROR_MESSAGE()
	select @rcode = 1
	end
END CATCH




bspexit:
  	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMHIInsert] TO [public]
GO
