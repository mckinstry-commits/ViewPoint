SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[vspPMHIInsertAndUpdate]
/*******************************
 * Created By:	GF 11/19/2007 6.x
 * Modified By:	GF 10/30/2008 - issue #130850 expand CCAddresses
 *				GF 09/03/2010 - added default to table for created date time
 *
 *
 * Purpose of stored procedure is to insert or update the document audit tables
 * with create and send information. The information will go into PMHI, the document (if any)
 * will go into PMHF, and attachment id's will go into PMHA for the audit record.
 *
 *
 *******************************/
(@pmco bCompany, @pmdzkeyid bigint, @username bVPUserName,
 @vendorgroup bGroup, @senttofirm bVendor = null, @senttocontact bEmployee = null,
 @sourcetablename varchar(50), @sourcekeyid bigint, @filename varchar(255) = null,
 @filedata varbinary(max) = null, @attachlist varchar(max) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @email varchar(100), @fax bPhone, @faxaddress varchar(100),
		@subject varchar(255), @ccaddresses varchar(500), @bccaddresses varchar(500),
		@pmdoccreateauditid bigint, @complete tinyint, @char char(1), @commapos int,
		@attachcommapos int, @retstring varchar(max), @retstringlist varchar(max),
		@attachmentid bigint

select @rcode = 0, @complete = 0

---- get create and send info from PMDZ
select @email=EMail, @fax=Fax, @faxaddress=FaxAddress, @subject=Subject,
	   @ccaddresses=CCAddresses, @bccaddresses=bCCAddresses, @pmdoccreateauditid=PMHIKeyId
from PMDZ with (nolock) where KeyID=@pmdzkeyid
if @@rowcount = 0
	begin
	select @msg = 'Error reading create and send information. Cannot add audit.', @rcode = 1
	goto bspexit
	end

----select @msg = convert(varchar(10),@pmdzkeyid) + ',' + convert(varchar(10),@sourcekeyid), @rcode = 1
----goto bspexit


BEGIN TRY

	begin

	begin transaction

	---- if not audit id set yet then inserting new rows into audit tables #141031
	if @pmdoccreateauditid is null
		begin
		---- insert PMHI (audit info) record
		insert PMHI(SourceTableName, SourceKeyId, CreatedBy, VendorGroup,
					SentToFirm, SentToContact, EMail, Fax, FaxAddress, Subject, CCAddresses,
					bCCAddresses)
		select @sourcetablename, @sourcekeyid, @username, @vendorgroup,
			   @senttofirm, @senttocontact, @email, @fax, @faxaddress, @subject, @ccaddresses,
			   @bccaddresses

		---- get PMHI.KeyID
		select @pmdoccreateauditid = SCOPE_IDENTITY()
		---- update PMDZ with PMDocCreateAuditId
		update PMDZ set PMHIKeyId=@pmdoccreateauditid
		where KeyID=@pmdzkeyid

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
		end
	else
		begin
		---- update PMHI (audit info) record
		update PMHI set EMail=@email, Fax=@fax, FaxAddress=@faxaddress, Subject=@subject,
					CCAddresses=@ccaddresses, bCCAddresses=@bccaddresses
		where KeyId=@pmdoccreateauditid

		---- delete old PMHF, then insert if we have an image
		delete from PMHF where PMHIKeyId=@pmdoccreateauditid
		---- insert PMHF (audit file image) record
		if @filedata is not null
			begin
			insert PMHF(PMHIKeyId, FileName, FileData)
			select @pmdoccreateauditid, @filename, @filedata
			end

		---- delete old PMHA, then insert if we have attachments
		delete from PMHA where PMHIKeyId=@pmdoccreateauditid
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
		select @msg = 'Distribution audit has been successfully updated.'
		end

	end

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
GRANT EXECUTE ON  [dbo].[vspPMHIInsertAndUpdate] TO [public]
GO
