SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************************************/
CREATE procedure [dbo].[vspPMDocDistInitForCOR]
/************************************************************************
* Created By:	GF 03/29/2011 TK-03298
* Modified By:	JG 05/06/2011 TK-04388
*				GF 08/24/2011 TK-02767
*				GF 01/21/2011 TK-11961 #145567
*				GF 06/18/2012 TK-15757 use fax function
*
*
* Purpose of Stored Procedure is to create a distribution list for the
* document being created and sent. This SP will initialize a list for the
* PM Change Order Request Document and load email, fax, CC addresses,
* header and query strings.
*
* Called from frmPMChangeOrderRequest form.
*
*
*
*
* Input parameters:
* PM Company
* Project
* Document Category	- will be 'COR'
* User Name
* COR_KeyID				COR record identifier
* Document Template		there may not be a template
* FullFileName			there may not be a filename
*
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany, @project bProject, @DocCategory varchar(10), @user bVPUserName,
 @CORID BIGINT = NULL, @template varchar(40) = null,
 @filename varchar(255) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @errmsg varchar(255),
		@vendorgroup bGroup, @senttofirm bVendor, @senttocontact bEmployee,
		@prefmethod varchar(1), @email varchar(60), @fax bPhone,
		@value nvarchar(max), @headerstring varchar(max), @querystring varchar(max),
		@joinstring varchar(max), @groupby varchar(max), @description bItemDesc,
		@itemsheader varchar(max), @itemsquery varchar(max), @ccnames varchar(max),
		@ccaddr varchar(max), @groupbylength bigint, @templatetype varchar(10),
		@responsiblefirm bVendor, @responsibleperson bEmployee, @sequence int,
		@faxaddress varchar(100),
		@bccaddr varchar(max), @pmdzkeyid bigint, @pmhikeyid bigint,
		@sourcekeyid bigint, @needitemquery bYN, @usestdcclist varchar(1), @ovrcclist varchar(max),
		@usestdsubject varchar(1), @ovrsubject varchar(500), @subjectline varchar(500),
		@usestdfilename varchar(1), @ovrfilename varchar(500), @ovrdocfilename varchar(250),
		@status varchar(6), @contract bContract, @attachtoparent char(1),
		@opencursor INT, @document VARCHAR(30), @SLCo TINYINT, @SL VARCHAR(30),
		@SubCO INT, @COR INT

select @rcode = 0, @retcode = 0, @ccnames = '', @ccaddr = '', @bccaddr = '', @needitemquery = 'Y'

if @pmco is null
	begin
	select @msg = 'Missing PM Company', @rcode = 1
	goto bspexit
	end

if @project is null
	begin
	select @msg = 'Missing Project', @rcode = 1
	goto bspexit
	end

if @DocCategory is null
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
SELECT @description=Description, @contract=Contract,
		@document=CONVERT(VARCHAR(10), COR),@COR=COR
FROM dbo.PMChangeOrderRequest WHERE KeyID=@CORID
if @@rowcount = 0
	begin
	select @msg = 'Invalid Change Order Request', @rcode = 1
	goto bspexit
	END
	

---- there must be at least one distribution with Send='Y' not a CC
if not exists(select Seq from dbo.PMDistribution where CORID = @CORID
						and Send='Y' and CC='N')
	begin
	select @msg = 'There must be at least one firm contact flagged to send without being a CC in the distribution table.', @rcode = 1
	goto bspexit
	END
	
---- first remove any old records in PMDZ
delete from dbo.PMDZ
where PMCo=@pmco and Project=@project and DocCategory=@DocCategory and UserName=@user

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

---- create cursor on distribution table
declare bcPMDistribution cursor LOCAL FAST_FORWARD
for select VendorGroup, SentToFirm, SentToContact, PrefMethod
from dbo.PMDistribution
where CORID=@CORID and Send='Y' and CC='N'

---- open cursor
open bcPMDistribution
select @opencursor = 1

---- loop through distribution list
PMDistribution_loop:
fetch next from bcPMDistribution into @vendorgroup, @senttofirm, @senttocontact, @prefmethod

if @@fetch_status = -1 goto PMDistribution_end
if @@fetch_status <> 0 goto PMDistribution_loop

---- first check if already in PMDZ, possible multiple preferred methods
if exists(select PMCo from dbo.PMDZ where PMCo=@pmco and Project=@contract and DocCategory=@DocCategory
			and UserName=@user and VendorGroup=@vendorgroup and SentToFirm=@senttofirm
			and SentToContact=@senttocontact and Document=@document)
	begin
	goto PMDistribution_loop
	end

---- check prefmethod if 'T' then set to 'E'. 'T'ext only method is obsolete
if isnull(@prefmethod,'T') = 'T'
	begin
	select @prefmethod = 'E'
	end

select @ccaddr = '', @bccaddr = '', @ccnames = ''
---- create the @ccnames, @ccaddr, and @bccaddr #24641
exec @retcode = dbo.vspPMDocDistInitCCListBuild @pmco, @project, @DocCategory, null, @document, NULL, NULL,
				----tk-11961
				@CORID, @ccnames output, @ccaddr output, @bccaddr output, @msg output

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
	---- #141664
	exec @rcode = dbo.bspHQWFMergeFieldBuild @template, @headerstring output, @querystring output, @msg OUTPUT, @pmco
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

	-- join to the JCJMPM to get the contract
	select @value = @value + ' join JCJMPM JCJMPM with (nolock) on JCJMPM.PMCo=a.PMCo and JCJMPM.Project=a.Project'
	---- add join to PMDZ so we only get one row TK-02767
	select @value = @value + ' join PMDZ PMDZ with (nolock) on PMDZ.PMCo=a.PMCo and PMDZ.Project=JCJMPM.Project'
	select @value = @value + ' and PMDZ.DocCategory=' + char(39) + @DocCategory + char(39)
	select @value = @value + ' and PMDZ.UserName=' + char(39) + @user + char(39)
	select @value = @value + ' and PMDZ.VendorGroup=a.VendorGroup and PMDZ.SentToFirm=a.SentToFirm and PMDZ.SentToContact=a.SentToContact'

	---- add where condition TK-02767
	select @value = @value + ' where a.PMCo = ' + convert(varchar(3),@pmco)
	select @value = @value + ' and JCJMPM.Contract = ' + CHAR(39) + @contract + CHAR(39)
	select @value = @value + ' and a.COR = ' + CONVERT(VARCHAR(20), @COR)
	select @value = @value + ' and a.VendorGroup=' + convert(varchar(6),@vendorgroup)
	select @value = @value + ' and a.SentToFirm=' + convert(varchar(10),@senttofirm)
	select @value = @value + ' and a.SentToContact=' + convert(varchar(10),@senttocontact)
	---- SEND FLAG MUST BE 'Y'
	select @value = @value + ' and a.Send = ' + CHAR(39) + 'Y' + CHAR(39)
	---- CC FLAG MUST BE 'N'
	select @value = @value + ' and a.CC = ' + CHAR(39) + 'N' + CHAR(39)
	---- add group by 
	select @value = @value + ' group by ' + @groupby

	select @querystring = @value

	if @needitemquery = 'Y'
		begin
		---- now build the merge fields and join clause for the transmittal documents
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
		select @value = @value + ' and a.Contract = ' + CHAR(39) + @contract + CHAR(39)
		select @value = @value + ' and a.COR = ' + CONVERT(VARCHAR(20), @COR)
		--SELECT @value = @value + ' and a.Project = ' + CHAR(39) + @project + CHAR(39)
		--select @value = @value + ' and a.PCOType = ' + CHAR(39) + @doctype + CHAR(39)
		--select @value = @value + ' and a.PCO = ' + CHAR(39) + @document + CHAR(39)

		---- add group by
		--if charindex('a.Seq', @groupby) > 0
		--	begin
		--	select @value = @value + ' group by a.Seq, a.SubCO, a.SLCo, a.SL, ' + @groupby
		--	end
		--else
			--begin
			select @value = @value + ' group by a.Project, a.PCOType, a.PCO, ' + @groupby
			--end

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


--SELECT @msg = dbo.vfToString(@CORID)
--SET @rcode = 1
--GOTO bspexit

---- set the subject line text
set @subjectline = null
if isnull(@usestdsubject,'Y') = 'Y'
	begin
	set @subjectline = 'COR: ' + isnull(@document,'') + ' - ' + isnull(@description,'')
	end
else
	begin
	---- create the subject line text
	exec @retcode = dbo.vspPMDocCatSubjectLineCreate @pmco, @DocCategory, @ovrsubject, @project,
						----TK-03298
						@SL, @document, null, null, null, null, @contract, @subjectline output
	if isnull(@subjectline,'') = '' set @subjectline = 'COR: ' + isnull(@document,'') + ' - ' + isnull(@description,'')
	end

---- set the document file name text #24641
set @ovrdocfilename = null
if isnull(@usestdfilename,'Y') = 'N'
	begin
	---- create the file name text
	exec @retcode = dbo.vspPMDocCatFileNameCreate @pmco, @DocCategory, @ovrfilename, @project,
				@SL, @document, null, null, null, null, @vendorgroup, @senttofirm,
				@senttocontact, null, @contract, @ovrdocfilename output
	if isnull(@ovrdocfilename,'') = '' set @ovrdocfilename = null
	end
	
---- insert distribution row
insert PMDZ(PMCo, Project, DocCategory, UserName, VendorGroup, Sequence, SentToFirm, SentToContact,
			DocType, Document, Rev, PCO, SL, EMail, Fax, FaxAddress, PrefMethod,
			Subject, FullFileName, CCAddresses, CCList,
			HeaderString, QueryString, ItemQueryString, bCCAddresses, AttachDocument, OvrDocFileName)
select @pmco, @project, @DocCategory, @user, @vendorgroup, isnull(max(i.Sequence),0)+1,
		@senttofirm, @senttocontact, null, @document, null, null, null, @email, @fax,
		@faxaddress, @prefmethod, @subjectline,
		@filename, @ccaddr, @ccnames, @headerstring, @querystring, @itemsquery, @bccaddr,
		@attachtoparent, @ovrdocfilename
from dbo.PMDZ i where i.PMCo=@pmco and i.Project=@project and i.DocCategory=@DocCategory
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
select 'PMChangeOrderRequest', @CORID, @user, @vendorgroup, @senttofirm, @senttocontact,
		@email, @fax, @faxaddress,
		'COR: ' + isnull(@document,'') + ' - ' + isnull(@description,''),
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

goto PMDistribution_loop


---- deallocate cursor
PMDistribution_end:
	if @opencursor = 1
		begin
		close bcPMDistribution
		deallocate bcPMDistribution
		set @opencursor = 0
		end



select @msg = 'Document Distribtution List has been successfully created.'


bspexit:
	if @opencursor = 1
		begin
		close bcPMDistribution
		deallocate bcPMDistribution
		set @opencursor = 0
		end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMDocDistInitForCOR] TO [public]
GO
