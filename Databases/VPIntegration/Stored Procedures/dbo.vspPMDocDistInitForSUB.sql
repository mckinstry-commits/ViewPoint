SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************************/
CREATE procedure [dbo].[vspPMDocDistInitForSUB]
/************************************************************************
* Created By:	GF 05/23/2007 6.x
* Modified By:	GF 02/20/2008 - issue #125959 Bcc and distribution audit
*				GF 04/29/2008 - issue #128085 need to verify we need a item query
*				GF 10/30/2008 - issue #130850 expand CCList to (max)
*				GF 02/14/2009 - issue #126932 attach document when create and send program closed.
*				GF 02/25/2009 - issue #132427 need to convert varchar(max) for SLIT notes.
*				GF 03/10/2009 - issue #131183 added TotalOrigTax and TotalCurrTax merge fields
*				GF 08/14/2009 - issue #24641 dynamic CC list, dynamic subject line, dynamic file name
*				GF 12/04/2009 - issue #136694
*				GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
*				GF 09/03/2010 - added default to table for created date time
*				GF 10/10/2010 - issue #141664 use HQCO.ReportDateFormat to specify the style for dates.
*				GF 11/12/2010 - issue #142083 change to use function for fax.
*				GF 03/28/2011 - TK-03298 COR
*				GF 06/18/2012 TK-15757 use fax function
*               AJW 10/2/12 TK-18201/144911 SUB can now have a word table
*
*
* Purpose of Stored Procedure is to create a distribution list for the
* document being created and sent. This SP will initialize a list for the
* PM Subcontract Document and load email, fax, CC addresses, header and query strings.
* Called from frmPMSLHeader form. If a subcontract template is used, could either
* have a word table or not depending on the template type.
* 'SUB' - no word table, 'SUBITEM' - word table
*
*
*
* Input parameters:
* PM Company
* Project
* Document Category	for Subcontract category will be 'SL'
* User Name
* SLCo					SL Company
* SL					Subcontract
* Document Template		there may not be a template
* FullFileName			there may not be a filename
*
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany, @project bProject, @doccategory varchar(10), @user bVPUserName,
 @slco bCompany, @sl VARCHAR(30), @template varchar(40) = null,
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
		@status varchar(6), @contract bContract, @attachtoparent char(1)

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
select @description=Description, @sourcekeyid=KeyID
from dbo.SLHD with (nolock) where SLCo=@slco and SL=@sl
if @@rowcount = 0
	begin
	select @msg = 'Invalid Subcontract', @rcode = 1
	goto bspexit
	end

---- get contract for project
select @contract = Contract
from dbo.JCJM with (nolock)
where JCCo=@pmco and Job=@project
if @@rowcount = 0 set @contract = null

---- get PMSS firm and contact
select @vendorgroup=VendorGroup, @senttofirm=SendToFirm, @senttocontact=SendToContact,
		@responsiblefirm=ResponsibleFirm, @responsibleperson=ResponsiblePerson
from dbo.PMSS with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco and SL=@sl
if @@rowcount = 0
	begin
	select @msg = 'Missing send to information, cannot continue.', @rcode = 1
	goto bspexit
	end

if @senttofirm is null
	begin
	select @msg = 'Missing Send To Firm, cannot continue.', @rcode = 1
	goto bspexit
	end

----if @senttocontact is null
----	begin
----	select @msg = 'Missing Send To Contact, cannot continue.', @rcode = 1
----	goto bspexit
----	end

---- get HQWD template type
select @templatetype='SUB'
if isnull(@template,'') <> ''
	begin
	select @templatetype=TemplateType
	from dbo.HQWD with (nolock) where TemplateName=@template
	if @@rowcount = 0
		begin
		select @msg = 'Error reading template information.', @rcode = 1
		goto bspexit
		end
	end

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
from dbo.PMCU with (nolock) where DocCat = @templatetype

---- check if filename is not empty
if isnull(@filename,'') = ''
	begin
	select @filename = null
	end

if ltrim(rtrim(isnull(@template,''))) = '' set @attachtoparent = 'N'

---- check if we have merge fields for the item word table
if not exists(select 1 from HQWF where TemplateName=@template and WordTableYN='Y')
	begin
	select @needitemquery = 'N'
	end


---- get information from PMPM for sent to firm contact
if isnull(@senttocontact,'') <> ''
	begin
	select @email=EMail, @prefmethod=PrefMethod
	from dbo.PMPM with (nolock) 
	where VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact
	end

---- TK-15757 use new function for fax address
SET @faxaddress = NULL
EXEC @faxaddress = dbo.vfFormatFaxForEmailWithServer @pmco, @vendorgroup, @senttofirm, @senttocontact


---- check prefmethod if 'T' then set to 'E'. 'T'ext only method is obsolete
if isnull(@prefmethod,'T') = 'T'
	begin
	select @prefmethod = 'E'
	end

select @headerstring = null, @querystring = null, @value = null

---- get next sequence
select @sequence = isnull(max(Sequence),0) + 1
from dbo.PMDZ where PMCo=@pmco and Project=@project and DocCategory=@doccategory

---- if there is a document template then build header and query strings
if ltrim(rtrim(isnull(@template,''))) <> ''
	begin

	---- build header string and column string from HQWF for template
	----#141664
	exec @rcode = dbo.bspHQWFMergeFieldBuild @template, @headerstring output, @querystring output, @msg OUTPUT, @slco
	if @rcode <> 0 goto bspexit

	---- build join clause from HQWO for template type
	exec @rcode = dbo.bspHQWDJoinClauseBuild @templatetype, 'N', 'Y', 'N', @joinstring output, @msg output
	if @rcode <> 0 goto bspexit

	---- add CCList and totals to header and query string, create group by clause
	---- #131183
	select @headerstring = @headerstring + ',CCList,TotalSubcontract,TotalOrigSL,TotalOrigSLProject,TotalOrigTax, TotalCurrTax'
	select @querystring = @querystring + ',PMDZ.CCList,PMSLTotal.TotalCurrSL,PMSLTotal.TotalOrigSL,PMSLTotal.TotalOrigSL,TotalOrigTax,TotalCurrTax'
	select @groupby = substring(@querystring ,8, datalength(@querystring))

	---- now build the query string for each firm and contact and update write to PMDZ
	select @value = @querystring + @joinstring

	---- add join to PMDZ so we only get one row
	select @value = @value + ' join PMDZ PMDZ with (nolock) on PMDZ.PMCo=' + convert(varchar(3),@pmco)
	select @value = @value + ' and PMDZ.Project=' + char(39) + @project + char(39)
	select @value = @value + ' and PMDZ.DocCategory=' + char(39) + @doccategory + char(39)
	select @value = @value + ' and PMDZ.UserName=' + char(39) + @user + char(39)
	select @value = @value + ' and PMDZ.VendorGroup=a.VendorGroup and PMDZ.Sequence=' + convert(varchar(10),@sequence)
	----select @value = @value + ' and PMDZ.SentToContact=' + convert(varchar(10),@senttocontact)

	---- add join to PMSLTotals for subcontract totals
	select @value = @value + ' left join PMSLTotal with (nolock) on PMSLTotal.SLCo=a.SLCo and PMSLTotal.SL=a.SL'

	---- add where condition
	select @value = @value + ' where a.SLCo = ' + convert(varchar(3),@slco)
	select @value = @value + ' and a.SL = ' + CHAR(39) + @sl + CHAR(39)
	select @value = @value + ' and a.VendorGroup=' + convert(varchar(6),@vendorgroup)

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

	if @needitemquery = 'Y' and @templatetype = 'SUBITEM'
		begin
		---- now build the mergefield, join clause for the Subcontract Items
		----#141664
		exec @rcode = dbo.bspHQWFMergeFieldBuildForTables @template, @itemsheader output, @itemsquery output, @msg OUTPUT, @slco
		if @rcode <> 0 goto bspexit
		   
		---- create items query for SLIT and replace values
		select @value = @itemsquery
		select @value = REPLACE(@value,'a.SLCo', 'i.SLCo')
		select @value = REPLACE(@value,'a.SL', 'i.SL')
		select @value = REPLACE(@value,'a.SLItemType', 'i.ItemType')
		select @value = REPLACE(@value,'a.SLItemDescription', 'i.Description')
		select @value = REPLACE(@value,'a.Units', 'i.OrigUnits')
		select @value = REPLACE(@value,'a.UnitCost', 'i.OrigUnitCost')
		select @value = REPLACE(@value,'a.Amount','i.OrigCost')
		select @value = REPLACE(@value,'a.PMCo','i.JCCo')
		select @value = REPLACE(@value,'a.Project','i.Job')
		select @value = REPLACE(@value,'a.SLAddon', 'i.Addon')
		select @value = REPLACE(@value,'a.SLAddonPct', 'i.AddonPct')
		select @value = REPLACE(@value,'a.PhaseGroup', 'i.PhaseGroup')
		select @value = REPLACE(@value,'a.Phase', 'i.Phase')
		select @value = REPLACE(@value,'a.CostType', 'i.JCCType')
		select @value = REPLACE(@value,'a.VendorGroup', 'i.VendorGroup')
		select @value = REPLACE(@value,'a.Supplier', 'i.Supplier')
		select @value = REPLACE(@value,'a.WCRetgPct', 'i.WCRetPct')
		select @value = REPLACE(@value,'a.SMRetgPct', 'i.SMRetPct')
		select @value = REPLACE(@value,'a.UM', 'i.UM')
		----#132427
		select @value = REPLACE(@value,'a.Notes', 'convert(varchar(max),i.Notes)')
		select @value = REPLACE(@value,'a.ud', 'i.ud')
		select @value = REPLACE(@value,'i.SLItemDescription', 'i.Description')
		select @value = REPLACE(@value,'a.SubCO','''''')
		select @value = REPLACE(@value,'PMSL a', 'SLIT i')
		select @value = REPLACE(@value,'a.','i.')
		  
		select @itemsquery = @itemsquery + ' where a.PMCo = ' + convert(varchar(3),@pmco)
		select @itemsquery = @itemsquery + ' and a.SLCo = ' + convert(varchar(3),@slco)
		select @itemsquery = @itemsquery + ' and a.SL = ' + CHAR(39) + @sl + CHAR(39)
		select @itemsquery = @itemsquery + ' and a.SLItemType in (1,4)'
		select @itemsquery = @itemsquery + ' and a.SendFlag = ' + CHAR(39) + 'Y' + CHAR(39)
		select @itemsquery = @itemsquery + ' and not exists(select * from SLIT c with (nolock)'
		select @itemsquery = @itemsquery + ' where c.SLCo=a.SLCo and c.SL=a.SL and c.SLItem=a.SLItem)'
		select @itemsquery = @itemsquery + ' UNION '
		   
		select @itemsquery = @itemsquery + @value
		select @itemsquery = @itemsquery + ' where i.SLCo = ' + convert(varchar(3),@slco)
		select @itemsquery = @itemsquery + ' and i.SL = ' + CHAR(39) + @sl + CHAR(39)
		select @itemsquery = @itemsquery + ' and i.ItemType in (1,4)'
			---- order by SLitem if found in query #29833
		if CHARINDEX('SLItem,',@value) <> 0
			begin
			select @itemsquery = @itemsquery + ' order by SLItem'
			end
		end
	  if @needitemquery = 'Y' and @templatetype = 'SUB'
			begin
		   exec @rcode = dbo.bspHQWFMergeFieldBuildForTables @template, @itemsheader output, @itemsquery output, @msg OUTPUT, @slco
	   			---- now build the query string for each firm and contact and update write to PMDZ
			select @value = @itemsquery

			---- add where condition
			select @value = @value + ' where a.PMCo = ' + convert(varchar(3),@pmco)
			select @value = @value + ' and a.SL = ' + CHAR(39) + @sl + CHAR(39)

			select @itemsquery = @value
			end
	end


PMDZ_Insert:

---- set the subject line text #24641
set @subjectline = null
if isnull(@usestdsubject,'Y') = 'Y'
	begin
	set @subjectline = 'SL: ' + isnull(@sl,'') + ' - ' + isnull(@description,'')
	end
else
	begin
	---- create the subject line text
	exec @retcode = dbo.vspPMDocCatSubjectLineCreate @slco, @doccategory, @ovrsubject, @project,
						----TK-03298
						null, @sl, null, null, null, null, @contract, @subjectline output
	if isnull(@subjectline,'') = '' set @subjectline = 'SL: ' + isnull(@sl,'') + ' - ' + isnull(@description,'')
	end

---- set the document file name text #24641
set @ovrdocfilename = null
if isnull(@usestdfilename,'Y') = 'N'
	begin
	---- create the file name text
	exec @retcode = dbo.vspPMDocCatFileNameCreate @pmco, @doccategory, @ovrfilename, @project,
					null, @sl, null, null, null, null, @vendorgroup, @senttofirm,
					@senttocontact, null, @contract, @ovrdocfilename output
	if isnull(@ovrdocfilename,'') = '' set @ovrdocfilename = null
	end

---- insert distribution row
insert PMDZ(PMCo, Project, DocCategory, UserName, VendorGroup, Sequence, SentToFirm, SentToContact,
			DocType, Document, Rev, PCO, SL, EMail, Fax, FaxAddress, PrefMethod,
			Subject, FullFileName, CCAddresses, CCList,
			HeaderString, QueryString, ItemQueryString, bCCAddresses, AttachDocument, OvrDocFileName)
select @pmco, @project, @doccategory, @user, @vendorgroup,  isnull(max(i.Sequence),0)+1,
		@senttofirm, @senttocontact, null, null, null, null, @sl, @email, @fax,
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
select 'SLHD', @sourcekeyid, @user, @vendorgroup, @senttofirm, @senttocontact,
		@email, @fax, @faxaddress,
		'SL: ' + isnull(@sl,'') + ' - ' + isnull(@description,''),
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


select @msg = 'Document Distribtution List has been successfully created.'


bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMDocDistInitForSUB] TO [public]
GO
