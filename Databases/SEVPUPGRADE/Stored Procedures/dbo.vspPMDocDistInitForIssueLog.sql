SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/***********************************************************************/
CREATE procedure [dbo].[vspPMDocDistInitForIssueLog]
/************************************************************************
* Created By:	GF 10/18/2010 - TFS #793
* Modified By:	GF 01/06/2011 - issue #142728
*				GF 03/28/2011 - TK-03298 COR
*				GF 01/21/2011 TK-11961 #145567
*				GF 06/18/2012 TK-15757 use fax function
*
*
*
* Purpose of Stored Procedure is to create a distribution list for the
* document being created and sent. This SP will initialize a list for the
* PM Issue Log Document and load email, fax, CC addresses, header and query strings.
* Called from frmPMTestLogsform.
*
*
*
* Input parameters:
* PM Company
* Project
* Document Category	for Other Documents category should be 'TEST'
* User Name
* Document Type
* Document
* Document Template if any
* FullFileName if any
*
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@PMCo bCompany = null, @Project bProject = null, @DocCategory varchar(10) = null,
 @User bVPUserName = null, @DocType bDocType = null, @Document bDocument = null,
 @Template varchar(40) = null, @FileName varchar(255) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @opencursor int, @errmsg varchar(255),
		@vendorgroup bGroup, @senttofirm bVendor, @senttocontact bEmployee,
		@prefmethod varchar(1), @email varchar(60), @fax bPhone,
		@value nvarchar(max), @headerstring varchar(max), @querystring varchar(max),
		@joinstring varchar(max), @groupby varchar(max), @description bItemDesc,
		@itemsquery varchar(max), @ccnames varchar(max), @ccaddr varchar(max),
		@faxaddress varchar(100), @sequence int,
		@bccaddr varchar(max), @pmdzkeyid bigint, @pmhikeyid bigint,
		@sourcekeyid bigint, @usestdcclist varchar(1), @ovrcclist varchar(max),
		@usestdsubject varchar(1), @ovrsubject varchar(500), @subjectline varchar(500),
		@usestdfilename varchar(1), @ovrfilename varchar(500), @ovrdocfilename varchar(250),
		@status varchar(6), @contract bContract, @attachtoparent char(1),
		@Issue INTEGER
		

select @rcode = 0, @retcode = 0, @opencursor = 0, @ccnames = '', @ccaddr = '', @bccaddr = ''

if @PMCo is null
	begin
	select @msg = 'Missing PM Company', @rcode = 1
	goto bspexit
	end

if @Project is null
	begin
	select @msg = 'Missing project', @rcode = 1
	goto bspexit
	end

if @DocCategory is null
	begin
	select @msg = 'Missing Category', @rcode = 1
	goto bspexit
	end

if @User is null
	begin
	select @msg = 'Missing User Name', @rcode = 1
	goto bspexit
	end

---- validate doc type
--IF @DocType IS NOT NULL
--	begin
--	if not exists(select DocType from dbo.PMDT where DocType=@DocType)
--		begin
--		select @msg = 'Invalid Issue Type', @rcode = 1
--		goto bspexit
--		end
--	END
	

---- get document data
SET @Issue = CONVERT(INT,@Document)
select @description=Description, @sourcekeyid = KeyID,
		@status = case when @status <> 0 then 'Closed' else 'Open' end
from dbo.PMIM with (nolock)
where PMCo=@PMCo and Project=@Project and Issue = @Issue
if @@rowcount = 0
	begin
	select @msg = 'Invalid Project Issue', @rcode = 1
	goto bspexit
	end
	
---- validate there is other document distribution in PMDistIssueLogs
if not exists(select Seq from dbo.vPMDistribution where IssueID=@sourcekeyid and Send='Y' and CC='N')
	begin
	select @msg = 'There must be at least one firm contact flagged to send without being a CC in the distribution table.', @rcode = 1
	goto bspexit
	end

---- get contract for project
select @contract = Contract
from dbo.JCJM with (nolock)
where JCCo=@PMCo and Job=@Project
if @@rowcount = 0 set @contract = null

---- first remove any old records in PMDZ
delete from dbo.PMDZ
where PMCo=@PMCo and Project=@Project and DocCategory=@DocCategory and UserName=@User

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
from dbo.PMCU with (nolock) where DocCat = @DocCategory

---- check if filename is not empty
if isnull(@FileName,'') = ''
	begin
	select @FileName = null
	end

if ltrim(rtrim(isnull(@Template,''))) = '' set @attachtoparent = 'N'

---- create cursor on distribution table
declare bcPMDistributionList cursor LOCAL FAST_FORWARD
for select VendorGroup, SentToFirm, SentToContact, PrefMethod
from dbo.PMDistribution
where IssueID = @sourcekeyid
AND Send='Y' and CC='N'

---- open distribution cursor
open bcPMDistributionList
select @opencursor = 1

---- loop through distribution list
PMDistristibutionList_loop:
fetch next from bcPMDistributionList into @vendorgroup, @senttofirm, @senttocontact, @prefmethod

if @@fetch_status = -1 goto PMDistributionList_end
if @@fetch_status <> 0 goto PMDistristibutionList_loop

---- first check if already in PMDZ, possible multiple preferred methods
if exists(select PMCo from dbo.PMDZ where PMCo=@PMCo and Project=@Project and DocCategory=@DocCategory
			and UserName=@User and VendorGroup=@vendorgroup and SentToFirm=@senttofirm
			and SentToContact=@senttocontact and Document=@Document)
	begin
	goto PMDistristibutionList_loop
	end

---- check prefmethod if 'T' then set to 'E'. 'T'ext only method is obsolete
if isnull(@prefmethod,'T') = 'T'
	begin
	select @prefmethod = 'E'
	end


select @ccaddr = '', @bccaddr = '', @ccnames = ''
---- create the @ccnames, @ccaddr, and @bccaddr #24641
exec @retcode = dbo.vspPMDocDistInitCCListBuild @PMCo, @Project, @DocCategory, @DocType, @Document, NULL, NULL,
				----TK-11961
				@sourcekeyid, @ccnames output, @ccaddr output, @bccaddr output, @msg output
				

---- get information from PMPM firm contacts
select @email=EMail
from dbo.PMPM with (nolock) 
where VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact

---- TK-15757 use new function for fax address
SET @faxaddress = NULL
EXEC @faxaddress = dbo.vfFormatFaxForEmailWithServer @PMCo, @vendorgroup, @senttofirm, @senttocontact



select @headerstring = null, @querystring = null, @value = null
---- if there is a document template then build header and query strings
if ltrim(rtrim(isnull(@Template,''))) <> ''
	begin
	---- build header string and column string from HQWF for template
	----#141664
	exec @rcode = dbo.bspHQWFMergeFieldBuild @Template, @headerstring output, @querystring output, @msg OUTPUT, @PMCo
	if @rcode <> 0 goto bspexit

	---- build join clause from HQWO for template type
	exec @rcode = dbo.bspHQWDJoinClauseBuild @DocCategory, 'N', 'Y', 'N', @joinstring output, @msg output
	if @rcode <> 0 goto bspexit

	---- add CCList to header and query string, create group by clause
	select @headerstring = @headerstring + ',CCList'
	select @querystring = @querystring + ',PMDZ.CCList'
	select @groupby = substring(@querystring ,8, datalength(@querystring))

	---- now build the query string for each firm and contact and update write to PMDZ
	select @value = @querystring + @joinstring

	---- add join to PMDZ so we only get one row
	select @value = @value + ' join PMDZ PMDZ with (nolock) on PMDZ.PMCo=a.PMCo and PMDZ.Project=a.Project'
	select @value = @value + ' and PMDZ.DocCategory=' + char(39) + @DocCategory + char(39)
	select @value = @value + ' and PMDZ.UserName=' + char(39) + @User + char(39)
	select @value = @value + ' and PMDZ.VendorGroup=a.VendorGroup and PMDZ.SentToFirm=a.SentToFirm and PMDZ.SentToContact=a.SentToContact'

	---- add where condition
	select @value = @value + ' where a.PMCo = ' + convert(varchar(3),@PMCo)
	select @value = @value + ' and a.Project = ' + CHAR(39) + @Project + CHAR(39)
	select @value = @value + ' and a.Issue = ' + CONVERT(VARCHAR(10), @Issue)
	select @value = @value + ' and a.VendorGroup=' + convert(varchar(6),@vendorgroup)
	select @value = @value + ' and a.SentToFirm=' + convert(varchar(10),@senttofirm)
	select @value = @value + ' and a.SentToContact=' + convert(varchar(10),@senttocontact)
	---- SEND FLAG MUST BE 'Y'
	select @value = @value + ' and a.Send = ' + CHAR(39) + 'Y' + CHAR(39)
	---- CC FLAG MUST BE 'N'
	select @value = @value + ' and a.CC = ' + CHAR(39) + 'N' + CHAR(39)
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

	select @querystring=@value
	end


---- set the subject line text #24641
set @subjectline = null
if isnull(@usestdsubject,'Y') = 'Y'
	begin
	set @subjectline = 'Document: ' + isnull(@Document,'') + ' - ' + isnull(@description,'')
	end
else
	begin
	---- create the subject line text
	exec @retcode = dbo.vspPMDocCatSubjectLineCreate @PMCo, @DocCategory, @ovrsubject, @Project,
						----TK-03298
						@DocType, @Document, null, null, null, null, @contract, @subjectline output
	if isnull(@subjectline,'') = '' set @subjectline = 'Document: ' + isnull(@Document,'') + ' - ' + isnull(@description,'')
	end

---- set the document file name text #24641
set @ovrdocfilename = null
if isnull(@usestdfilename,'Y') = 'N'
	begin
	---- create the file name text
	exec @retcode = dbo.vspPMDocCatFileNameCreate @PMCo, @DocCategory, @ovrfilename, @Project,
				@DocType, @Document, null, null, null, null, @vendorgroup, @senttofirm,
				@senttocontact, @status, @contract, @ovrdocfilename output
	if isnull(@ovrdocfilename,'') = '' set @ovrdocfilename = null
	end

---- insert distribution row
insert PMDZ(PMCo, Project, DocCategory, UserName, VendorGroup, Sequence, SentToFirm,
			SentToContact, DocType, Document, Rev, PCO, SL, EMail, Fax, FaxAddress,
			PrefMethod, Subject, FullFileName, CCAddresses, CCList, HeaderString,
			QueryString, bCCAddresses, AttachDocument, OvrDocFileName)
select @PMCo, @Project, @DocCategory, @User, @vendorgroup, isnull(max(i.Sequence),0)+1,
			@senttofirm, @senttocontact, @DocType, @Document, null, null, null, @email,
			@fax, @faxaddress, @prefmethod, @subjectline,
			@FileName, @ccaddr, @ccnames, @headerstring, @querystring, @bccaddr,
			@attachtoparent, @ovrdocfilename
from PMDZ i where i.PMCo=@PMCo and i.Project=@Project and i.DocCategory=@DocCategory
if @@rowcount = 0
	begin
	select @msg = 'Error occurred inserting PMDZ record.', @rcode = 1
	goto bspexit
	end

---- get PMDZ.KeyID
select @pmdzkeyid = SCOPE_IDENTITY()

---- insert PMHI (audit info) record
insert PMHI(SourceTableName, SourceKeyId, CreatedBy, VendorGroup,
			SentToFirm, SentToContact, EMail, Fax, FaxAddress, Subject, CCAddresses,
			bCCAddresses)
----#142728
select 'PMIM', @sourcekeyid, @User, @vendorgroup, @senttofirm, @senttocontact,
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


goto PMDistristibutionList_loop


---- deallocate cursor
PMDistributionList_end:
	if @opencursor = 1
		begin
		close bcPMDistributionList
		deallocate bcPMDistributionList
		set @opencursor = 0
		end


select @msg = 'Document Distribtution List has been successfully created.'





bspexit:
	if @opencursor = 1
		begin
		close bcPMDistributionList
		deallocate bcPMDistributionList
		set @opencursor = 0
		end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMDocDistInitForIssueLog] TO [public]
GO
