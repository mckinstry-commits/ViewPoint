SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************************************/
CREATE procedure [dbo].[vspPMDocDistInitForPO]
/************************************************************************
* Created By:	GF 03/12/2010 - issue #120252
* Modified By:	GF 09/03/2010 - added default to table for created date time
*				GF 11/12/2010 - issue #142083 change to use function for fax
*				GF 03/28/2011 - TK-03298 COR
*				GF 01/21/2011 TK-11961 #145567
*				GF 06/18/2012 TK-15757 use fax function
*
*
*
* Purpose of Stored Procedure is to create a distribution list for the
* document being created and sent. This SP will initialize a list for the
* PM PO Document and load email, fax, CC addresses, and bCC addresses
* Called from frmPMPOHeader form.

* 'PURCHASE' - document type
*
* CURRENTLY WE ARE ONLY CREATING A DISTRIBUTION LIST. WORD TEMPLATE WILL FOLLOW LATER
*
* Input parameters:
* PM Company
* Project
* Document Category	for purchase category will be 'Purchase'
* User Name
* Document Type
* POCo		PO Company
* PO		Purchase Order
* Template	NOT USED
* FileName	NOT USED
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany, @project bProject, @doccategory varchar(10), @user bVPUserName,
@poco bCompany, @document bDocument, @keyid bigint,@template varchar(40) = null,
 @filename varchar(255) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int,  @opencursor int, @errmsg varchar(255),
		@vendorgroup bGroup, @senttofirm bVendor, @senttocontact bEmployee,
		@prefmethod varchar(1), @email varchar(60), @fax bPhone,
		@value nvarchar(max), @headerstring varchar(max), @querystring varchar(max),
		@joinstring varchar(max), @groupby varchar(max), @description bItemDesc,
		@itemsheader varchar(max), @itemsquery varchar(max), @ccnames varchar(max),
		@ccaddr varchar(max), @groupbylength bigint, @templatetype varchar(10),
		@responsiblefirm bVendor, @responsibleperson bEmployee, @sequence int,
		@faxaddress varchar(100),
		@bccaddr varchar(max), @pmdzkeyid bigint, @pmhikeyid bigint,
		@needitemquery bYN, @usestdcclist varchar(1), @ovrcclist varchar(max),
		@usestdsubject varchar(1), @ovrsubject varchar(500), @subjectline varchar(500),
		@usestdfilename varchar(1), @ovrfilename varchar(500), @ovrdocfilename varchar(250),
		@status varchar(6), @contract bContract, @attachtoparent char(1), @po varchar(30)

select @rcode = 0, @retcode = 0, @ccnames = '', @ccaddr = '', @bccaddr = '', @needitemquery = 'Y'

if @pmco is null
	begin
	select @msg = 'Missing PM Company', @rcode = 1
	goto bspexit
	end

if @project is null
	begin
	select @msg = 'Missing project', @rcode = 1
	goto bspexit
	end

if @doccategory is null
	begin
	select @msg = 'Missing Category', @rcode = 1
	goto bspexit
	end

if @user is null
	begin
	select @msg = 'Missing User Name', @rcode = 1
	goto bspexit
	end
	
---- get document data
select @description=Description, @po=PO
from dbo.POHD with (nolock) where POCo=@poco and KeyID=@keyid
if @@rowcount = 0
	begin
	select @msg = 'Invalid Purchase Order', @rcode = 1
	goto bspexit
	end

---- validate there is purchase order distribution in PMDistPOs
if not exists(select Seq from dbo.vPMDistribution WHERE PurchaseOrderID = @keyid
					AND Send='Y' AND CC='N')
			--where PMCo=@pmco and Project=@project
			--					and POCo=@poco and PO=@document and Send='Y' and CC='N')
	begin
	select @msg = 'There must be at least one firm contact flagged to send without being a CC in the distribution table.', @rcode = 1
	goto bspexit
	end

---- get contract for project
select @contract = Contract
from dbo.JCJM with (nolock)
where JCCo=@pmco and Job=@project
if @@rowcount = 0 set @contract = null

---- first remove any old records in PMDZ
delete from dbo.PMDZ
where PMCo=@pmco and Project=@project and DocCategory=@doccategory and UserName=@user

---- get document category information #24641
set @usestdcclist = 'Y'
set @usestdsubject = 'Y'
set @usestdfilename = 'Y'
set @attachtoparent = 'Y'
set @ovrcclist = null
set @ovrsubject = null
set @ovrfilename = null
select @usestdcclist=UseStdCCList, @ovrcclist=OvrCCList,
		@usestdsubject=UseStdSubject, @ovrsubject=OvrSubject,
		@usestdfilename=UseStdFileName, @ovrfilename=OvrFileName,
		@attachtoparent=AttachToParent
from dbo.PMCU with (nolock) where DocCat = @doccategory

---- check if filename is not empty
if isnull(@filename,'') = ''
	begin
	select @filename = null
	end

if ltrim(rtrim(isnull(@template,''))) = '' set @attachtoparent = 'N'

---- create cursor on PMDistPOs
declare bcPMDistPOs cursor LOCAL FAST_FORWARD
for select VendorGroup, SentToFirm, SentToContact, PrefMethod
from dbo.vPMDistribution
WHERE PurchaseOrderID = @keyid
AND Send='Y' AND CC='N'
----where PMCo=@pmco and Project=@project and POCo=@poco
----and PO=@document and Send='Y' and CC='N'

---- open bcPMDistPOs cursor
open bcPMDistPOs
select @opencursor = 1

---- loop through distribution list
PMDistPOs_loop:
fetch next from bcPMDistPOs into @vendorgroup, @senttofirm, @senttocontact, @prefmethod

if @@fetch_status = -1 goto PMDistPOs_end
if @@fetch_status <> 0 goto PMDistPOs_loop

---- first check if already in PMDZ, possible multiple preferred methods
if exists(select PMCo from dbo.PMDZ where PMCo=@pmco and Project=@project and DocCategory=@doccategory
			and UserName=@user and VendorGroup=@vendorgroup and SentToFirm=@senttofirm
			and SentToContact=@senttocontact and Document=@document)
	begin
	goto PMDistPOs_loop
	end

---- check prefmethod if 'T' then set to 'E'. 'T'ext only method is obsolete
if isnull(@prefmethod,'T') = 'T'
	begin
	select @prefmethod = 'E'
	end


select @ccaddr = '', @bccaddr = '', @ccnames = ''
---- create the @ccnames, @ccaddr, and @bccaddr #24641
exec @retcode = dbo.vspPMDocDistInitCCListBuild @pmco, @project, @doccategory, null, @document, NULL, @poco,
				----TK-11961
				@keyid, @ccnames output, @ccaddr output, @bccaddr output, @msg output
				

---- get information from PMPM firm contacts
select @email=EMail
from dbo.PMPM with (nolock) 
where VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact

---- TK-15757 use new function for fax address
SET @faxaddress = NULL
EXEC @faxaddress = dbo.vfFormatFaxForEmailWithServer @pmco, @vendorgroup, @senttofirm, @senttocontact


select @headerstring = null, @querystring = null, @value = null


---- set the subject line text #24641
set @subjectline = null
if isnull(@usestdsubject,'Y') = 'Y'
	begin
	set @subjectline = 'Document: ' + isnull(@po,'') + ' - ' + isnull(@description,'')
	end
else
	begin
	---- create the subject line text
	exec @retcode = dbo.vspPMDocCatSubjectLineCreate @pmco, @doccategory, @ovrsubject, @project,
						----TK-03298
						null, @po, null, @poco, null, null, @contract, @subjectline output
	if isnull(@subjectline,'') = '' set @subjectline = 'Purchase Order: ' + isnull(@po,'') + ' - ' + isnull(@description,'')
	end

---- set the document file name text #24641
set @ovrdocfilename = null
----if isnull(@usestdfilename,'Y') = 'N'
----	begin
----	---- create the file name text
----	exec @retcode = dbo.vspPMDocCatFileNameCreate @pmco, @doccategory, @ovrfilename, @project,
----				null, @document, null, null, null, null, @vendorgroup, @senttofirm,
----				@senttocontact, @status, @contract, @ovrdocfilename output
----	if isnull(@ovrdocfilename,'') = '' set @ovrdocfilename = null
----	end
	
---- insert distribution row
insert PMDZ(PMCo, Project, DocCategory, UserName, VendorGroup, Sequence, SentToFirm, SentToContact,
			DocType, Document, Rev, PCO, SL, EMail, Fax, FaxAddress, PrefMethod,
			Subject, FullFileName, CCAddresses, CCList,
			HeaderString, QueryString, ItemQueryString, bCCAddresses, AttachDocument, OvrDocFileName)
select @pmco, @project, @doccategory, @user, @vendorgroup, isnull(max(i.Sequence),0)+1,
		@senttofirm, @senttocontact, null, null, null, null, @po, @email, @fax,
		@faxaddress, @prefmethod, @subjectline,
		@filename, @ccaddr, @ccnames, @headerstring, @querystring, @itemsquery, @bccaddr,
		@attachtoparent, @ovrdocfilename
from dbo.PMDZ i where i.PMCo=@pmco and i.Project=@project and i.DocCategory=@doccategory
if @@rowcount = 0
	begin
	select @msg = 'Error occurred inserting PMDZ record.', @rcode = 1
	goto bspexit
	end

---- get PMDZ.KeyID
select @pmdzkeyid = SCOPE_IDENTITY()

---- insert PMHI (audit info) record #141031
insert PMHI(SourceTableName, SourceKeyId, CreatedBy, VendorGroup,
			SentToFirm, SentToContact, EMail, Fax, FaxAddress, Subject, CCAddresses,
			bCCAddresses)
select 'POHD', @keyid, @user, @vendorgroup, @senttofirm, @senttocontact,
		@email, @fax, @faxaddress, @subjectline, @ccaddr, @bccaddr
if @@rowcount = 0
	begin
	select @msg = 'Error occurred inserting Document audit record.', @rcode = 1
	goto bspexit
	end

---- get PMHI.KeyId
select @pmhikeyid = SCOPE_IDENTITY()

---- update PMDZ with audit key id
update dbo.PMDZ set PMHIKeyId = @pmhikeyid
where KeyID=@pmdzkeyid

goto PMDistPOs_loop


---- deallocate cursor
PMDistPOs_end:
	if @opencursor = 1
		begin
		close bcPMDistPOs
		deallocate bcPMDistPOs
		set @opencursor = 0
		end



select @msg = 'Document Distribtution List has been successfully created.'





bspexit:
	if @opencursor = 1
		begin
		close bcPMDistPOs
		deallocate bcPMDistPOs
		set @opencursor = 0
		end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocDistInitForPO] TO [public]
GO
