SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMOtherSubInitialize    Script Date: 8/28/99 9:36:25 AM ******/
CREATE  procedure [dbo].[bspPMOtherSubInitialize]
/*******************************************************************************
 * Modified By:	GF 10/15/2002 - Issue #18992 need to get next seq for bPMOC.
 *				GF 03/19/2003 - problem w/related firm when vendor is different
 *				GF 12/09/2003 - #23212 - check error messages, wrap concatenated values with isnull
 *				GF 02/07/2005 - issue #22095 - allow daily log copy on all Job Status
 *				GF 06/11/2007 - issue #124803 - format PO to the bDocument data type.
 *				GF 06/30/2010 - issue #135813 expanded subcontract to 30 characters
 *				GF 10/03/2011 TK-00000 initialize either using PO or next number. add related record.
 *
 *
 * Pass this SP all the info to initialize document for Subcontract based on selected 
 * Subcontract, and selected document type to initialize.
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 * If there is an error it will display the error message.
 *
 * Pass In
 *   Connection    Connection to do query on
 *   PMCo          PM Company to initialize in
 *   Project       Project to initialize Document for
 *   VendorGroup   VendorGroup the vendors are in
 *   subcontract   subcontract to initialize
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
 @contact bEmployee, @subcontract VARCHAR(30), @doctype bDocType,
 @new_document bDocument = null output, @source_guid uniqueidentifier = null output,
 @new_keyid bigint = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @status bStatus, @description bDesc, @location varchar(10), @seq int,
   		@vendor bVendor, @document bDocument, @jobstatus tinyint, @firmnumber bFirm,
   		@contactcode bEmployee, @docmask varchar(30), @doclength varchar(10),
   		@firmtype bFirmType, @emsg varchar(255), @guid UNIQUEIDENTIFIER,
   		---- TK-08858
		@docnumber bDocument, @errmsg VARCHAR(255), @SLKeyID BIGINT

select @rcode=1, @firmtype=null, @msg='Error Initializing!', @new_document = '', @new_keyid = 0

select @jobstatus = JobStatus from JCJM where JCCo=@pmco and Job=@project
if @@rowcount = 0 
	begin
	select @msg='Project ' + isnull(@project,'') + ' not setup, cannot initialize!',@rcode=1
	goto bspexit
   	end

if @subcontract is null
   	begin
	select @msg='Subcontract must not be null, cannot initialize!',@rcode=1
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
if @docmask in ('R','L') set @docmask = @doclength + @docmask + 'N'

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

---- get subcontract data from SLHD
select @description=Description, @vendor=Vendor, @guid=UniqueAttchID,
		@SLKeyID = KeyID
from dbo.SLHD where SLCo=@apco and SL=@subcontract
if @@rowcount=0
   	begin
	select @msg='Unable to locate subcontract in SLHD, cannot initialize!',@rcode=1
	goto bspexit
   	end

if @description is null
   	begin
	select @description='Document from Subct ' + isnull(@subcontract,'') + ' .'
   	end

---- initialize vendor into PMFM if needed
if @vendor is not null
   	begin
	exec bspPMFirmInitialize @vendorgroup, @vendor, @vendor, @firmtype, @msg
   	end
     
   -- get firm and contact from PMPF if valid
   select @firmnumber=min(FirmNumber) from PMFM where VendorGroup=@vendorgroup and Vendor=@vendor
   if @@rowcount <> 0
   	begin
   	select @contactcode=min(ContactCode) 
   	from PMPF where PMCo=@pmco and Project=@project and VendorGroup=@vendorgroup and FirmNumber=@firmnumber
   	end

---- Convert SL to document format
select @subcontract = ltrim(rtrim(@subcontract))

---- TK-08858
IF LEN(@subcontract) > 10
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
	SET @subcontract = @docnumber
	END

---- now format the subcontract or next other document number
exec bspHQFormatMultiPart @subcontract, @docmask, @document OUTPUT

---- insert document into PMOD if not already exists
if not exists (select * from PMOD where PMCo=@pmco and Project=@project and DocType=@doctype and Document=@document)
   	begin		 
   	insert into PMOD(PMCo, Project, DocType, Document, Description,
   				VendorGroup, RelatedFirm, Status, ResponsibleFirm, ResponsiblePerson)
   	values(@pmco, @project, @doctype, @document, @description,
   				@vendorgroup, @firmnumber, @status, @ourfirm, @contact)

	if @firmnumber is not null and @contactcode is not null
   		begin
   		select @seq=1
   		select @seq=isnull(Max(Seq),0)+1 from PMOC
		where PMCo=@pmco and Project=@project and DocType=@doctype and Document=@document
   	    insert into PMOC(PMCo, Project, DocType, Document, Seq, VendorGroup, SentToFirm, SentToContact)
   	    values(@pmco, @project, @doctype, @document, @seq, @vendorgroup, @firmnumber, @contactcode)
   		end
   
	---- set output values
	select @source_guid = @guid
	select @new_document = @document
	select @new_keyid = KeyID
	from PMOD where PMCo=@pmco and Project=@project and DocType=@doctype and Document=@document
	if @@rowcount = 0 select @new_keyid = 0
   	select @rcode=0	
   	
	---- insert record association TK-08858
	INSERT INTO dbo.PMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
	SELECT 'PMOD', @new_keyid, 'SLHD', @SLKeyID
	WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord b WHERE b.RecTableName = 'PMOD'
					AND b.RECID=@new_keyid AND b.LinkTableName='SLHD' AND b.LINKID=@SLKeyID)
	AND NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord c WHERE c.RecTableName='SLHD'
					AND c.RECID=@SLKeyID AND c.LinkTableName='PMOD' AND c.LINKID=@new_keyid)
   	
   	END





bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMOtherSubInitialize] TO [public]
GO
