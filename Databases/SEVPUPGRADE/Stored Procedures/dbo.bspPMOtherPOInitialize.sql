SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspPMOtherPOInitialize    Script Date: 8/28/99 9:36:25 AM ******/
CREATE   procedure [dbo].[bspPMOtherPOInitialize]
/*******************************************************************************
 * Modified By:	GF 10/15/2002 - Issue #18992 need to get next seq for bPMOC.
 *				GF 12/09/2003 - #23212 - check error messages, wrap concatenated values with isnull
 *				GF 02/07/2005 - issue #22095 - allow daily log copy on all Job Status
 *				GF 08/11/2005 - issue #29540 - changed to load @firmnumber not @vendor as related firm
 *				GF 06/11/2007 - issue #124803 - format PO to the bDocument data type.
 *				DC 01/28/08	- Issue #121529 - Increase the PO change order line description to 60.
 *				GP 7/29/2011 - TK-07143 changed @PO from varchar(10) to varchar(30)
 *				GF 10/03/2011 TK-08858 initialize either using PO or next number. add related record.
 *
 *
 *
 * Pass this SP all the info to initialize document for PO based on selected 
 * PO, and selected document type to initialize.
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 * If there is an error it will display the error message.
 *
 *
 * Pass In
 *   Connection    Connection to do query on
 *   PMCo          PM Company to initialize in
 *   Project       Project to initialize Document for
 *   VendorGroup   VendorGroup the vendors are in
 *   po            po to initialize
 *   doctype       doctype to initialize
 * 
 * RETURN PARAMS
 *   msg           Error Message, or Success message
 *
 * Returns
 *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
 *
 ********************************************************************************/
(@pmco bCompany, @apco bCompany, @project bJob, @vendorgroup bGroup, @ourfirm bFirm,
 @contact bEmployee, @po varchar(30), @doctype bDocType, 
 @new_document bDocument = null output, @source_guid uniqueidentifier = null output,
 @new_keyid bigint = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @status bStatus, @description bItemDesc,--@description bDesc  DC #121529 
		@location varchar(10), @seq int,
   		@vendor bVendor, @document bDocument, @jobstatus tinyint, @firmnumber bFirm,
   		@contactcode bEmployee, @docmask varchar(30), @doclength varchar(10),
		@firmtype bFirmType, @guid UNIQUEIDENTIFIER, 
		---- TK-08858
		@docnumber bDocument, @errmsg VARCHAR(255), @POKeyID BIGINT

select @rcode=1, @firmtype=null, @msg='Error Initializing!', @new_document = '', @new_keyid = 0

select @jobstatus = JobStatus from JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0 
	begin
	select @msg='Project ' + isnull(@project,'') + ' not setup, cannot initialize!',@rcode=1
	goto bspexit
   	end

if @po is null
	begin
	select @msg='Purchase order must not be null, cannot initialize!',@rcode=1
	goto bspexit
   	end

if @doctype is null
	begin
	select @msg='Document type must not be null, cannot initialize!',@rcode=1
	goto bspexit
   	end

if @ourfirm is null
   	begin
	select @msg='Responsible firm must not be null, cannot initialize!',@rcode=1
	goto bspexit
   	end

if @contact is null
	begin
	select @msg='Responsible person must not be null, cannot initialize!',@rcode=1
	goto bspexit
   	end

---- get input mask for bDocument
select @docmask=InputMask, @doclength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bDocument'
if isnull(@docmask,'') = '' set @docmask = 'R'
if isnull(@doclength,'') = '' set @doclength = '10'
if @docmask in ('R','L') select @docmask = @doclength + @docmask + 'N'

---- get default beginning status from PMCo if there is one 
---- otherwise get first beginning status from PMSC
select @status = BeginStatus from PMCO where PMCo=@pmco
if isnull(@status,'') = ''
	begin
	select @status = min(Status) from PMSC where CodeType = 'B'
	if @@rowcount = 0
		begin
		select @msg = 'Must set up at least one beginning status in status codes.', @rcode = 1
		goto bspexit
		end
	end

---- get purchase order data from POHD
select @description=Description, @vendor=Vendor, @location=ShipLoc,
		@guid=UniqueAttchID, @POKeyID = KeyID
from POHD with (nolock) where POCo=@apco and PO=@po
if @@rowcount=0
	begin
	select @msg='Unable to locate purchase order in POHD, cannot initialize!',@rcode=1
	goto bspexit
   	end

if @description is null
	begin
	select @description='Document from PO ' + isnull(@po,'') + ' .'
   	end

---- initialize vendor into PMFM if needed
if @vendor is not null
   	begin
   	exec bspPMFirmInitialize @vendorgroup, @vendor, @vendor, @firmtype, @msg
   	end

---- get firm and contact from PMPF if valid 
select @firmnumber=min(FirmNumber)
from PMFM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
if @@rowcount <> 0
   	begin
   	select @contactcode=min(ContactCode) from PMPF with (nolock) 
   	where PMCo=@pmco and Project=@project and VendorGroup=@vendorgroup and FirmNumber=@firmnumber
   	end

---- Convert po to document format
select @po = ltrim(rtrim(@po))
---- TK-08858
IF LEN(@po) > 10
	BEGIN
	EXEC @rcode = dbo.vspPMGetNextPMDocNum @pmco, @project, @doctype, NULL, 'OTHER',
			@docnumber output, @errmsg output
	IF @rcode <> 0
		BEGIN
		SET @msg = 'Error occurred getting next Other Document Number.'
		SET @rcode = 1
		GOTO bspexit
		END
		
	---- set @po = @docnumber
	SET @po = @docnumber
	END
	
---- now format the po or next other document number
exec bspHQFormatMultiPart @po, @docmask, @document output

---- insert document into PMOD if not already exists
if not exists (select top 1 1 from PMOD with (nolock) where PMCo=@pmco and Project=@project 
   					and DocType=@doctype and Document=@document)
	begin		 
   	insert into PMOD(PMCo, Project, DocType, Document, Description, Location,
				VendorGroup, RelatedFirm, Status, ResponsibleFirm, ResponsiblePerson)
   	values(@pmco, @project, @doctype, @document, @description, @location,
				@vendorgroup, @firmnumber, @status, @ourfirm, @contact)

	if @firmnumber is not null and @contactcode is not null
		begin
   		select @seq=1
   		select @seq=isnull(Max(Seq),0)+1
   		from PMOC with (nolock) where PMCo=@pmco and Project=@project and DocType=@doctype and Document=@document
   	    insert into PMOC(PMCo, Project, DocType, Document, Seq, VendorGroup, SentToFirm, SentToContact)
   	    values(@pmco, @project, @doctype, @document, @seq, @vendorgroup, @firmnumber, @contactcode)
   		end

	---- set output values
	select @source_guid = @guid
	select @new_document = @document
	select @new_keyid = KeyID
	from dbo.PMOD where PMCo=@pmco and Project=@project and DocType=@doctype and Document=@document
	if @@rowcount = 0 select @new_keyid = 0
   	select @rcode=0
   	
	---- insert record association TK-08858
	INSERT INTO dbo.PMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
	SELECT 'PMOD', @new_keyid, 'POHD', @POKeyID
	WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord b WHERE b.RecTableName = 'PMOD'
					AND b.RECID=@new_keyid AND b.LinkTableName='POHD' AND b.LINKID=@POKeyID)
	AND NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord c WHERE c.RecTableName='POHD'
					AND c.RECID=@POKeyID AND c.LinkTableName='PMOD' AND c.LINKID=@new_keyid)

   	END



 bspexit:
   	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspPMOtherPOInitialize] TO [public]
GO
