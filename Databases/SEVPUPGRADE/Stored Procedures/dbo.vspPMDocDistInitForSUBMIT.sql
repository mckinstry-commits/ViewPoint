SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************************************/
CREATE procedure [dbo].[vspPMDocDistInitForSUBMIT]
/************************************************************************
* Created By:	GF 05/24/2007 6.x
* Modified By:	GF 02/20/2008 - issue #125959 Bcc and distribution audit
*				GF 04/29/2008 - issue #128085 need to verify we need a item query
*				GF 09/16/2008 - issue #129926 added order by for a.Item
*				GF 10/30/2008 - issue #130850 expand CCList to (max)
*				GF 02/14/2009 - issue #126932 attach document when create and send program closed.
*				GF 08/14/2009 - issue #24641 dynamic CC list, dynamic subject line, dynamic file name
*				GF 10/30/2009 - issue #134090 added distribution to submittals
*				GF 12/04/2009 - issue #136694
*				GF 09/03/2010 - added default to table for created date time
*				GF 10/10/2010 - issue #141664 use HQCO.ReportDateFormat to specify the style for dates.
*				GF 11/12/2010 - issue #142083 change to use function for fax.
*				GF 03/28/2011 - TK-03298 COR
*				GF 01/21/2011 TK-11961 #145567
*				GF 06/18/2012 TK-15757 use fax function
*
*
* Purpose of Stored Procedure is to create a distribution list for the
* document being created and sent. This SP will initialize a list for the
* PM Submitall Document and load email, fax, CC addresses, header and query strings.
* Called from frmPMSubmittal form.
*
*
*
* Input parameters:
* PM Company
* Project
* Document Category	for PCO category should be 'PCO'
* User Name
* Document Type
* Document
* Document Description
* Document Template if any
* FullFileName if any
* Revision	PM Submittal Revision
*
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany, @project bProject, @doccategory varchar(10), @user bVPUserName,
 @doctype bDocType, @document bDocument, @template varchar(40) = null,
 @filename varchar(255) = null, @revision tinyint,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @opencursor int, @errmsg varchar(255),
		@vendorgroup bGroup, @senttofirm bVendor, @senttocontact bEmployee,
		@prefmethod varchar(1), @email varchar(60), @fax bPhone,
		@value nvarchar(max), @headerstring varchar(max), @querystring varchar(max),
		@joinstring varchar(max), @groupby varchar(max), @description bItemDesc,
		@itemsheader varchar(max), @itemsquery varchar(max), @ccnames varchar(max),
		@ccaddr varchar(max), @groupbylength bigint, @subfirm bVendor, @archengfirm bVendor,
		@subcontact bEmployee, @archengcontact bEmployee, @submethod varchar(1),
		@subemail varchar(60), @subfax bPhone, @archmethod varchar(1), @archemail varchar(60),
		@archfax bPhone, @faxaddress varchar(100),
		@sequence int, @bccaddr varchar(max), @pmdzkeyid bigint, @pmhikeyid bigint,
		@sourcekeyid bigint, @needitemquery bYN, @usestdcclist varchar(1), @ovrcclist varchar(max),
		@usestdsubject varchar(1), @ovrsubject varchar(500), @subjectline varchar(500),
		@usestdfilename varchar(1), @ovrfilename varchar(500), @ovrdocfilename varchar(250),
		@status varchar(6), @contract bContract, @attachtoparent char(1)

select @rcode = 0, @retcode = 0, @opencursor = 0, @ccnames = '', @ccaddr = '', @bccaddr = '',
		@needitemquery = 'Y'

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

---- validate document type
if not exists(select DocType from dbo.PMDT where DocType=@doctype)
	begin
	select @msg = 'Invalid document type', @rcode = 1
	goto bspexit
	end

---- get document data
select @description=Description, @vendorgroup=VendorGroup, @subfirm=SubFirm,
		@subcontact=SubContact, @archengfirm=ArchEngFirm, @archengcontact=ArchEngContact,
		@sourcekeyid=KeyID, @status=Status
from dbo.PMSM with (nolock)
where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@document and Rev=@revision
if @@rowcount = 0
	begin
	select @msg = 'Invalid Submittal', @rcode = 1
	goto bspexit
	END
	
---- validate there is submittal document distribution in PMDistSubmittals
if not exists(select Seq from dbo.vPMDistribution WHERE SubmittalID = @sourcekeyid
					AND Send = 'Y' AND CC = 'N')
					--where PMCo=@pmco and Project=@project
					--and SubmittalType=@doctype and Submittal=@document and Rev=@revision
					--and Send='Y' and CC='N')
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
delete from PMDZ
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

---- check if we have merge fields for the item word table
if not exists(select 1 from dbo.HQWF where TemplateName=@template and WordTableYN='Y')
	begin
	select @needitemquery = 'N'
	end


---- create cursor on PMDistSubmittals
declare bcPMDistSubmittals cursor LOCAL FAST_FORWARD
	for select VendorGroup, SentToFirm, SentToContact, PrefMethod
from dbo.vPMDistribution
WHERE SubmittalID = @sourcekeyid
AND Send = 'Y' AND CC = 'N'
--where PMCo=@pmco and Project=@project and SubmittalType=@doctype
--and Submittal=@document and Rev=@revision and Send='Y' and CC='N'

---- open cursor
open bcPMDistSubmittals
select @opencursor = 1

---- loop through distribution list
PMDistSubmittals_loop:
fetch next from bcPMDistSubmittals into @vendorgroup, @senttofirm, @senttocontact, @prefmethod

if @@fetch_status = -1 goto PMDistSubmittals_end
if @@fetch_status <> 0 goto PMDistSubmittals_loop

---- first check if already in PMDZ, possible multiple preferred methods
if exists(select PMCo from dbo.PMDZ where PMCo=@pmco and Project=@project and DocCategory=@doccategory
			and UserName=@user and VendorGroup=@vendorgroup and SentToFirm=@senttofirm
			and SentToContact=@senttocontact and DocType=@doctype and Document=@document)
	begin
	goto PMDistSubmittals_loop
	end

---- check prefmethod if 'T' then set to 'E'. 'T'ext only method is obsolete
if isnull(@prefmethod,'T') = 'T'
	begin
	select @prefmethod = 'E'
	end


select @ccaddr = '', @bccaddr = '', @ccnames = ''
---- create the @ccnames, @ccaddr, and @bccaddr #24641
exec @retcode = dbo.vspPMDocDistInitCCListBuild @pmco, @project, @doccategory, @doctype, @document, NULL, @revision,
				----TK-11961
				@sourcekeyid, @ccnames output, @ccaddr output, @bccaddr output, @msg output
				

---- get information from PMPM firm contacts
select @email=EMail
from dbo.PMPM with (nolock) 
where VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact

---- TK-15757 use new function for fax address
SET @faxaddress = NULL
EXEC @faxaddress = dbo.vfFormatFaxForEmailWithServer @pmco, @vendorgroup, @senttofirm, @senttocontact


select @headerstring = null, @querystring = null, @value = null
select @itemsheader = null, @itemsquery = null
---- if there is a document template then build header and query strings
if ltrim(rtrim(isnull(@template,''))) <> ''
	begin
	---- build header string and column string from HQWF for template
	----#141664
	exec @rcode = dbo.bspHQWFMergeFieldBuild @template, @headerstring output, @querystring output, @msg OUTPUT, @pmco
	if @rcode <> 0 goto bspexit

	---- build join clause from HQWO for template type
	exec @rcode = dbo.bspHQWDJoinClauseBuild 'SUBMIT', 'N', 'Y', 'N', @joinstring output, @msg output
	if @rcode <> 0 goto bspexit

	---- add CCList to header and query string, create group by clause
	select @headerstring = @headerstring + ',CCList'
	select @querystring = @querystring + ',PMDZ.CCList'
	select @groupby = substring(@querystring ,8, datalength(@querystring))

	---- now build the query string for each firm and contact and update write to PMDZ
	select @value = @querystring + @joinstring

	---- add join to PMDZ so we only get one row
	select @value = @value + ' join PMDZ PMDZ with (nolock) on PMDZ.PMCo=aa.PMCo and PMDZ.Project=aa.Project'
	select @value = @value + ' and PMDZ.DocType=aa.SubmittalType and PMDZ.Document=aa.Submittal and PMDZ.Rev=aa.Rev'
	select @value = @value + ' and PMDZ.DocCategory=' + char(39) + @doccategory + char(39)
	select @value = @value + ' and PMDZ.UserName=' + char(39) + @user + char(39)

	---- add where condition
	select @value = @value + ' where aa.PMCo = ' + convert(varchar(3),@pmco)
	select @value = @value + ' and aa.Project = ' + CHAR(39) + @project + CHAR(39)
	select @value = @value + ' and aa.SubmittalType = ' + CHAR(39) + @doctype + CHAR(39)
	select @value = @value + ' and aa.Submittal = ' + CHAR(39) + @document + CHAR(39)
	select @value = @value + ' and aa.Rev = ' + convert(varchar(3),@revision)
	select @value = @value + ' and aa.VendorGroup=' + convert(varchar(6),@vendorgroup)
	select @value = @value + ' and aa.SentToFirm=' + convert(varchar(10),@senttofirm)
	select @value = @value + ' and aa.SentToContact=' + convert(varchar(10),@senttocontact)

	---- SEND FLAG MUST BE 'Y'
	select @value = @value + ' and aa.Send = ' + CHAR(39) + 'Y' + CHAR(39)
	---- CC FLAG MUST BE 'N'
	select @value = @value + ' and aa.CC = ' + CHAR(39) + 'N' + CHAR(39)
	---- add group by 
	select @value = @value + ' group by ' + @groupby

	-------- lets execute query statement to check for syntax errors
	----BEGIN TRY
	----	begin
	----	execute sp_executesql @value
	----	end
	----END TRY
	----
	----BEGIN CATCH
	----	begin
	----	select @msg = 'Other Document Query failed. ' + ERROR_MESSAGE(), @rcode = 1
	----	goto bspexit
	----	end
	----END CATCH

	select @querystring = @value

	if @needitemquery = 'Y'
		begin
		---- now build the merge fields and join clause for the items
		----#141664
		exec @rcode = dbo.bspHQWFMergeFieldBuildForTables @template, @itemsheader output, @itemsquery output, @msg OUTPUT, @pmco
		if @rcode <> 0 goto bspexit

		select @groupbylength = patindex('%from%',@itemsquery)
		if @groupbylength <> 0
			begin
			select @groupby = substring(@itemsquery, 8, @groupbylength - 9)
			end
		else
			begin
			select @groupby = substring(@itemsquery, 8, datalength(@itemsquery))
			end

		---- now build the query string for each firm and contact and update write to PMDZ
		select @value = @itemsquery

		---- add where condition
		select @value = @value + ' where a.PMCo = ' + convert(varchar(3),@pmco)
		select @value = @value + ' and a.Project = ' + CHAR(39) + @project + CHAR(39)
		select @value = @value + ' and a.SubmittalType = ' + CHAR(39) + @doctype + CHAR(39)
		select @value = @value + ' and a.Submittal = ' + CHAR(39) + @document + CHAR(39)
		select @value = @value + ' and a.Rev = ' + convert(varchar(3),@revision)
		select @value = @value + ' and a.Send = ' + CHAR(39) + 'Y' + CHAR(39)

		---- add group by 
		select @value = @value + ' group by a.Item, ' + @groupby

		-------- lets execute query statement to check for syntax errors
		----BEGIN TRY
		----	begin
		----	execute sp_executesql @value
		----	end
		----END TRY
		----
		----BEGIN CATCH
		----	begin
		----	select @msg = 'Other Document Query failed. ' + ERROR_MESSAGE(), @rcode = 1
		----	goto bspexit
		----	end
		----END CATCH

		select @itemsquery = @value
		end
	end


---- set the subject line text #24641
set @subjectline = null
if isnull(@usestdsubject,'Y') = 'Y'
	begin
	set @subjectline = 'Submittal: ' + isnull(@document,'') + ' - ' + isnull(@description,'')
	end
else
	begin
	---- create the subject line text
	exec @retcode = dbo.vspPMDocCatSubjectLineCreate @pmco, @doccategory, @ovrsubject, @project,
						----TK-03298
						@doctype, @document, null, @revision, null, null, @contract, @subjectline output
	if isnull(@subjectline,'') = '' set @subjectline = 'Submittal: ' + isnull(@document,'') + ' - ' + isnull(@description,'')
	end

---- set the document file name text #24641
set @ovrdocfilename = null
if isnull(@usestdfilename,'Y') = 'N'
	begin
	---- create the file name text
	exec @retcode = dbo.vspPMDocCatFileNameCreate @pmco, @doccategory, @ovrfilename, @project,
				@doctype, @document, null, @revision, null, null, @vendorgroup, @senttofirm,
				@senttocontact, @status, @contract, @ovrdocfilename output
	if isnull(@ovrdocfilename,'') = '' set @ovrdocfilename = null
	end

---- insert distribution row
insert PMDZ(PMCo, Project, DocCategory, UserName, VendorGroup, Sequence, SentToFirm, SentToContact,
			DocType, Document, Rev, PCO, SL, EMail, Fax, FaxAddress, PrefMethod,
			Subject, FullFileName, CCAddresses, CCList,
			HeaderString, QueryString, ItemQueryString, bCCAddresses, AttachDocument, OvrDocFileName)
select @pmco, @project, @doccategory, @user, @vendorgroup,  isnull(max(i.Sequence),0)+1,
		@senttofirm, @senttocontact, @doctype, @document, @revision, null, null, @email,
		@fax, @faxaddress, @prefmethod, @subjectline,
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
select 'PMSM', @sourcekeyid, @user, @vendorgroup, @senttofirm, @senttocontact,
		@email, @fax, @faxaddress,
		'Submittal: ' + isnull(@document,'') + ' - ' + isnull(@description,''),
		@ccaddr, @bccaddr
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

goto PMDistSubmittals_loop


---- deallocate cursor
PMDistSubmittals_end:
	if @opencursor = 1
		begin
		close bcPMDistSubmittals
		deallocate bcPMDistSubmittals
		set @opencursor = 0
		end


select @msg = 'Document Distribtution List has been successfully created.'



bspexit:
	if @opencursor = 1
		begin
		close bcPMDistSubmittals
		deallocate bcPMDistSubmittals
		set @opencursor = 0
		end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMDocDistInitForSUBMIT] TO [public]
GO
