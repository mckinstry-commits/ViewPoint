SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
CREATE  procedure [dbo].[vspPMTransmittalAdd]
/************************************************************************
* Created By:	GF 12/05/2006 6.x
* Modified By:  Dan So 06/19/2008 - Issue: 127542 - allow for the PM Document to be assigned to an existing Transmittal.
*				GF 10/27/2009 - issue #134721, #134610 distribution for inspection and test logs
*				GF 10/27/2009 - issue #134090 distribution for submittal
*				GF 12/21/2010 - issue #141957 record linking
*				GF 06/22/2011 - D-02339 use view not tables for links
*
*
* Purpose of Stored Procedure is to create a transmittal from a source
* document. Currently called from PMTransmittalAdd with default values
* passed in. Need the source document information to assign to transmittal
* and get issue, responsible person when adding transmittal. 
*
* Then document category tells the SP where the source document is from.
* Current forms where a transmittal can be added from:
* PMACOS, PMPCOS, PMRFI, PMRFQ, PMOtherDocs, PMSubmittals
*
*
* A transmittal record (PMTM) will be added.
* A transmittal document record (PMTS) will be added for the source document.
* Distribution records (PMTC) will be added for the each source document
* distribution record where the send flag is 'Y'.
*
* Input parameters:
* PM Company
* Project
* Document Type
* Document
* Transmittal
* Subject
* Transmittal Date
* Date Sent
* Date Required
* Document Category
* Copy attachments
* Vendor Group
* Responsible Firm
* Responsible Person
* Revision
*
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany, @project bProject, @doctype bDocType = null, @document bDocument,
 @transmittal bDocument, @subject varchar(255) = null, @transdate bDate,
 @datesent bDate = null, @datedue bDate = null, @doccategory varchar(10) = null,
 @copyattachments bYN = 'N', @vendorgroup bGroup = null, @respfirm bVendor = null,
 @respperson bEmployee = null, @revision tinyint = 0, 
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @docdesc bItemDesc, @status varchar(6), @issue bIssue,
		@uniqueattchid uniqueidentifier, @guid uniqueidentifier, @hqat_desc bDesc,
		@docname varchar(255), @origfilename varchar(255), @addedby bVPUserName,
		@adddate bDate, @formname varchar(30), @tablename varchar(30), @keystring varchar(255),
		@ExistingTrans bYN,
		----#141957
		@RecTableName NVARCHAR(128), @LinkTableName NVARCHAR(128), @RECID BIGINT, @LINKID BIGINT

SET @rcode = 0
SET @LinkTableName = 'PMTM'

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

if @document is null
	begin
	select @msg = 'Missing source document', @rcode = 1
	goto bspexit
	end

if @transmittal is null
	begin
	select @msg = 'Missing transmittal', @rcode = 1
	goto bspexit
	end

if @transdate is null
	begin
	select @msg = 'Missing transmittal date', @rcode = 1
	goto bspexit
	end

-- ********************************* -- ********** --
-- CHECK FOR AN EXISTING TRANSMITTAL -- DEFAULT NO --
-- ********************************* -- ********** --
SET @ExistingTrans = 'N'
IF EXISTS(SELECT * FROM PMTM WHERE PMCo = @pmco AND Project = @project AND Transmittal = @transmittal)
	BEGIN
		SET @ExistingTrans = 'Y'
	END

---- if missing document category try to find
if isnull(@doccategory,'') = '' and isnull(@doctype,'') <> ''
	begin
	select @doccategory=DocCategory
	from PMDT where DocType=@doctype
	if @@rowcount = 0
		begin
		select @msg = 'Invalid Document Type', @rcode = 1
		goto bspexit
		end
	end

---- get source information using document category
if @doccategory = 'RFI'
	BEGIN
	----#141957
	SET @RecTableName = 'PMRI'
	select @docdesc=substring(Subject,1,60), @status=Status, @issue=Issue, 
			@vendorgroup=VendorGroup, @respfirm=ResponsibleFirm, @respperson=ResponsiblePerson,
			@uniqueattchid=UniqueAttchID, @RECID=KeyID
	from dbo.PMRI where PMCo=@pmco and Project=@project and RFIType=@doctype and RFI=@document
	if @@rowcount = 0
		begin
		select @msg = 'Error getting RFI information.', @rcode = 1
		goto bspexit
		end
	end

if @doccategory = 'OTHER'
	BEGIN
	----#141957
	SET @RecTableName = 'PMOD'
	select @docdesc=substring(Description,1,60), @status=Status, @issue=Issue, 
			@vendorgroup=VendorGroup, @respfirm=ResponsibleFirm, @respperson=ResponsiblePerson,
			@uniqueattchid=UniqueAttchID, @RECID=KeyID
	from dbo.PMOD where PMCo=@pmco and Project=@project and DocType=@doctype and Document=@document
	if @@rowcount = 0
		begin
		select @msg = 'Error getting Other Document information.', @rcode = 1
		goto bspexit
		end
	end

if @doccategory = 'INSPECT'
	BEGIN
	----#141957
	SET @RecTableName = 'PMIL'
	select @docdesc=substring(Description,1,60), @status=Status, @issue=Issue,
			@uniqueattchid=UniqueAttchID, @RECID=KeyID
	from dbo.PMIL where PMCo=@pmco and Project=@project and InspectionType=@doctype and InspectionCode=@document
	if @@rowcount = 0
		begin
		select @msg = 'Error getting Inspection information.', @rcode = 1
		goto bspexit
		end
	end

if @doccategory = 'TEST'
	BEGIN
	----#141957
	SET @RecTableName = 'PMTL'
	select @docdesc=substring(Description,1,60), @status=Status, @issue=Issue,
			@uniqueattchid=UniqueAttchID, @RECID=KeyID
	from dbo.PMTL where PMCo=@pmco and Project=@project and TestType=@doctype and TestCode=@document
	if @@rowcount = 0
		begin
		select @msg = 'Error getting Test information.', @rcode = 1
		goto bspexit
		end
	end

if @doccategory = 'SUBMIT'
	BEGIN
	----#141957
	SET @RecTableName = 'PMSM'
	select @docdesc=substring(Description,1,60), @status=Status, @issue=Issue, 
			@vendorgroup=VendorGroup, @respfirm=ResponsibleFirm, @respperson=ResponsiblePerson,
			@uniqueattchid=UniqueAttchID, @RECID=KeyID
	from dbo.PMSM where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@document and Rev=@revision
	if @@rowcount = 0
		begin
		select @msg = 'Error getting Submittal information.', @rcode = 1
		goto bspexit
		end
	end

if @doccategory = 'PCO'
	BEGIN
	----#141957
	SET @RecTableName = 'PMOP'
	select @docdesc=substring(Description,1,30), @issue=Issue, @uniqueattchid=UniqueAttchID, @RECID=KeyID
	from dbo.PMOP where PMCo=@pmco and Project=@project and PCOType=@doctype and PCO=@document
	if @@rowcount = 0
		begin
		select @msg = 'Error getting PCO information.', @rcode = 1
		goto bspexit
		end
	end

if @doccategory = 'ACO'
	BEGIN
	----#141957
	SET @RecTableName = 'PMOH'
	select @docdesc=substring(Description,1,30), @issue=Issue, @uniqueattchid=UniqueAttchID, @RECID=KeyID
	from dbo.PMOH where PMCo=@pmco and Project=@project and ACO=@document
	if @@rowcount = 0
		begin
		select @msg = 'Error getting ACO information.', @rcode = 1
		goto bspexit
		end
	end



BEGIN TRY

	begin
	---- for now only RFI, OTHER, PCO, INSPECT, TEST, SUBMIT create transmittals
	---- at some point in future will need to open for other source documents
	begin transaction

	---------
	-- RFI --
	---------
	if @doccategory = 'RFI'
		begin

		IF @ExistingTrans = 'N'
			BEGIN
				---- add transmittal to PMTM
				insert PMTM(PMCo, Project, Transmittal, Subject, TransDate, DateSent, DateDue, Issue,
							CreatedBy, VendorGroup, ResponsibleFirm, ResponsiblePerson, DateResponded)
				select @pmco, @project, @transmittal, @subject, @transdate, @datesent, @datedue, @issue,
							SUSER_SNAME(), @vendorgroup, @respfirm, @respperson, NULL
				
				SET @LINKID = SCOPE_IDENTITY()	
				---- INSERT RECORD LINK #141957	
				INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
				SELECT @RecTableName, @RECID, @LinkTableName, @LINKID
				WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@RecTableName
						AND v.RECID=@RECID AND v.LinkTableName=@LinkTableName AND v.LINKID=@LINKID)
			END

		---- add source document to PMTS
		insert PMTS(PMCo, Project, Transmittal, Seq, DocType, Document, DocumentDesc, CopiesSent, Status)
		select @pmco, @project, @transmittal, isnull(max(Seq),0)+1, @doctype, @document, @docdesc, 1, @status
		from PMTS where PMCo=@pmco and Project=@project and Transmittal=@transmittal
		---- add distributions to PMTC from source (PMRD)
		insert PMTC(PMCo, Project, Transmittal, Seq, VendorGroup, SentToFirm, SentToContact, Send, PrefMethod, CC, DateSent)
		select @pmco, @project, @transmittal, isnull(max(c.Seq),0) + ROW_NUMBER() OVER(ORDER BY c.PMCo ASC, c.Project ASC, c.Transmittal ASC),
				h.VendorGroup, h.SentToFirm, h.SentToContact, h.Send, h.PrefMethod, h.CC, @datesent
		from PMRD h with (nolock)
		left join PMTC c on c.PMCo=@pmco and c.Project=@project and c.Transmittal=@transmittal
		where h.PMCo=@pmco and h.Project=@project and h.RFIType=@doctype and h.RFI=@document and h.Send = 'Y'
		and not exists(select 1 from PMTC d where d.PMCo=@pmco and d.Project=@project and d.Transmittal=@transmittal
					and d.SentToFirm=h.SentToFirm and d.SentToContact=h.SentToContact)
		group by h.PMCo, h.Project, h.RFIType, h.RFI, c.PMCo, c.Project, c.Transmittal,
				 h.VendorGroup, h.SentToFirm, h.SentToContact, h.PrefMethod, h.Send, h.CC
		end

	-----------
	-- OTHER --
	-----------
	if @doccategory = 'OTHER'
		begin
		
		IF @ExistingTrans = 'N'
			BEGIN
				---- add transmittal to PMTM
				insert PMTM(PMCo, Project, Transmittal, Subject, TransDate, DateSent, DateDue, Issue,
							CreatedBy, VendorGroup, ResponsibleFirm, ResponsiblePerson, DateResponded)
				select @pmco, @project, @transmittal, @subject, @transdate, @datesent, @datedue, @issue,
							SUSER_SNAME(), @vendorgroup, @respfirm, @respperson, null

				SET @LINKID = SCOPE_IDENTITY()	
				---- INSERT RECORD LINK #141957	
				INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
				SELECT @RecTableName, @RECID, @LinkTableName, @LINKID
				WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@RecTableName
						AND v.RECID=@RECID AND v.LinkTableName=@LinkTableName AND v.LINKID=@LINKID)
			END

		---- add source document to PMTS
		insert PMTS(PMCo, Project, Transmittal, Seq, DocType, Document, DocumentDesc, CopiesSent, Status)
		select @pmco, @project, @transmittal, isnull(max(Seq),0)+1, @doctype, @document, @docdesc, 1, @status
		from PMTS where PMCo=@pmco and Project=@project and Transmittal=@transmittal
		---- add distributions to PMTC from source (PMOC)
		insert PMTC(PMCo, Project, Transmittal, Seq, VendorGroup, SentToFirm, SentToContact, Send, PrefMethod, CC, DateSent)
		select @pmco, @project, @transmittal, isnull(max(c.Seq),0) + ROW_NUMBER() OVER(ORDER BY c.PMCo ASC, c.Project ASC, c.Transmittal ASC),
				h.VendorGroup, h.SentToFirm, h.SentToContact, h.Send, h.PrefMethod, h.CC, @datesent
		from PMOC h with (nolock)
		left join PMTC c on c.PMCo=@pmco and c.Project=@project and c.Transmittal=@transmittal
		where h.PMCo=@pmco and h.Project=@project and h.DocType=@doctype and h.Document=@document and h.Send = 'Y'
		and not exists(select 1 from PMTC d where d.PMCo=@pmco and d.Project=@project and d.Transmittal=@transmittal
					and d.SentToFirm=h.SentToFirm and d.SentToContact=h.SentToContact)
		group by h.PMCo, h.Project, h.DocType, h.Document, c.PMCo, c.Project, c.Transmittal,
				 h.VendorGroup, h.SentToFirm, h.SentToContact, h.PrefMethod, h.Send, h.CC
		end

	------------
	-- SUBMIT --
	------------
	if @doccategory = 'SUBMIT'
		begin

		IF @ExistingTrans = 'N'
			BEGIN
				---- add transmittal to PMTM
				insert PMTM(PMCo, Project, Transmittal, Subject, TransDate, DateSent, DateDue, Issue,
							CreatedBy, VendorGroup, ResponsibleFirm, ResponsiblePerson, DateResponded)
				select @pmco, @project, @transmittal, @subject, @transdate, @datesent, @datedue, @issue,
							SUSER_SNAME(), @vendorgroup, @respfirm, @respperson, null

				SET @LINKID = SCOPE_IDENTITY()	
				---- INSERT RECORD LINK #141957	
				INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
				SELECT @RecTableName, @RECID, @LinkTableName, @LINKID
				WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@RecTableName
						AND v.RECID=@RECID AND v.LinkTableName=@LinkTableName AND v.LINKID=@LINKID)
			END

		---- add source document to PMTS
		insert PMTS(PMCo, Project, Transmittal, Seq, DocType, Document, DocumentDesc, CopiesSent, Status, Rev)
		select @pmco, @project, @transmittal, isnull(max(Seq),0)+1, @doctype, @document, @docdesc, 1, @status, @revision
		from PMTS where PMCo=@pmco and Project=@project and Transmittal=@transmittal
		
		---- add distributions to PMTC from source (PMDistribution)
		insert PMTC(PMCo, Project, Transmittal, Seq, VendorGroup, SentToFirm, SentToContact, Send, PrefMethod, CC, DateSent)
		select @pmco, @project, @transmittal, isnull(max(c.Seq),0) + ROW_NUMBER() OVER(ORDER BY c.PMCo ASC, c.Project ASC, c.Transmittal ASC),
				h.VendorGroup, h.SentToFirm, h.SentToContact, h.Send, h.PrefMethod, h.CC, @datesent
		from dbo.PMDistribution h with (nolock)
		left join PMTC c on c.PMCo=@pmco and c.Project=@project and c.Transmittal=@transmittal
		where h.PMCo=@pmco and h.Project=@project and h.SubmittalType=@doctype and h.Submittal=@document
		and h.Rev=@revision and h.Send = 'Y'
		and not exists(select 1 from PMTC d where d.PMCo=@pmco and d.Project=@project and d.Transmittal=@transmittal
					and d.SentToFirm=h.SentToFirm and d.SentToContact=h.SentToContact)
		group by h.PMCo, h.Project, h.SubmittalType, h.Submittal, h.Rev, c.PMCo, c.Project, c.Transmittal,
				 h.VendorGroup, h.SentToFirm, h.SentToContact, h.PrefMethod, h.Send, h.CC
		end

	-------------
	-- INSPECT --
	-------------
	if @doccategory = 'INSPECT'
		begin

		IF @ExistingTrans = 'N'
			BEGIN
				---- add transmittal to PMTM
				insert PMTM(PMCo, Project, Transmittal, Subject, TransDate, DateSent, DateDue, Issue,
							CreatedBy, VendorGroup, ResponsibleFirm, ResponsiblePerson, DateResponded)
				select @pmco, @project, @transmittal, @subject, @transdate, @datesent, @datedue, @issue,
							SUSER_SNAME(), @vendorgroup, @respfirm, @respperson, null

				SET @LINKID = SCOPE_IDENTITY()	
				---- INSERT RECORD LINK #141957	
				INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
				SELECT @RecTableName, @RECID, @LinkTableName, @LINKID
				WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@RecTableName
						AND v.RECID=@RECID AND v.LinkTableName=@LinkTableName AND v.LINKID=@LINKID)
			END

		---- add source document to PMTS
		insert PMTS(PMCo, Project, Transmittal, Seq, DocType, Document, DocumentDesc, CopiesSent, Status)
		select @pmco, @project, @transmittal, isnull(max(Seq),0)+1, @doctype, @document, @docdesc, 1, @status
		from PMTS where PMCo=@pmco and Project=@project and Transmittal=@transmittal
		
		---- add distributions to PMTC from source (PMDistribution)
		insert PMTC(PMCo, Project, Transmittal, Seq, VendorGroup, SentToFirm, SentToContact, Send, PrefMethod, CC, DateSent)
		select @pmco, @project, @transmittal, isnull(max(c.Seq),0) + ROW_NUMBER() OVER(ORDER BY c.PMCo ASC, c.Project ASC, c.Transmittal ASC),
				h.VendorGroup, h.SentToFirm, h.SentToContact, h.Send, h.PrefMethod, h.CC, @datesent
		from dbo.PMDistribution h with (nolock)
		left join PMTC c on c.PMCo=@pmco and c.Project=@project and c.Transmittal=@transmittal
		where h.PMCo=@pmco and h.Project=@project and h.InspectionType=@doctype and h.InspectionCode=@document and h.Send = 'Y'
		and not exists(select 1 from PMTC d where d.PMCo=@pmco and d.Project=@project and d.Transmittal=@transmittal
					and d.SentToFirm=h.SentToFirm and d.SentToContact=h.SentToContact)
		group by h.PMCo, h.Project, h.InspectionType, h.InspectionCode, c.PMCo, c.Project, c.Transmittal,
				 h.VendorGroup, h.SentToFirm, h.SentToContact, h.PrefMethod, h.Send, h.CC
		end

	----------
	-- TEST --
	----------
	if @doccategory = 'TEST'
		begin

		IF @ExistingTrans = 'N'
			BEGIN
				---- add transmittal to PMTM
				insert PMTM(PMCo, Project, Transmittal, Subject, TransDate, DateSent, DateDue, Issue,
							CreatedBy, VendorGroup, ResponsibleFirm, ResponsiblePerson, DateResponded)
				select @pmco, @project, @transmittal, @subject, @transdate, @datesent, @datedue, @issue,
							SUSER_SNAME(), @vendorgroup, @respfirm, @respperson, null

				SET @LINKID = SCOPE_IDENTITY()	
				---- INSERT RECORD LINK #141957	
				INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
				SELECT @RecTableName, @RECID, @LinkTableName, @LINKID
				WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@RecTableName
						AND v.RECID=@RECID AND v.LinkTableName=@LinkTableName AND v.LINKID=@LINKID)
			END

		---- add source document to PMTS
		insert PMTS(PMCo, Project, Transmittal, Seq, DocType, Document, DocumentDesc, CopiesSent, Status)
		select @pmco, @project, @transmittal, isnull(max(Seq),0)+1, @doctype, @document, @docdesc, 1, @status
		from PMTS where PMCo=@pmco and Project=@project and Transmittal=@transmittal
		
		---- add distributions to PMTC from source (PMDistribution)
		insert PMTC(PMCo, Project, Transmittal, Seq, VendorGroup, SentToFirm, SentToContact, Send, PrefMethod, CC, DateSent)
		select @pmco, @project, @transmittal, isnull(max(c.Seq),0) + ROW_NUMBER() OVER(ORDER BY c.PMCo ASC, c.Project ASC, c.Transmittal ASC),
				h.VendorGroup, h.SentToFirm, h.SentToContact, h.Send, h.PrefMethod, h.CC, @datesent
		from dbo.PMDistribution h with (nolock)
		left join PMTC c on c.PMCo=@pmco and c.Project=@project and c.Transmittal=@transmittal
		where h.PMCo=@pmco and h.Project=@project and h.TestType=@doctype and h.TestCode=@document and h.Send = 'Y'
		and not exists(select 1 from PMTC d where d.PMCo=@pmco and d.Project=@project and d.Transmittal=@transmittal
					and d.SentToFirm=h.SentToFirm and d.SentToContact=h.SentToContact)
		group by h.PMCo, h.Project, h.TestType, h.TestCode, c.PMCo, c.Project, c.Transmittal,
				 h.VendorGroup, h.SentToFirm, h.SentToContact, h.PrefMethod, h.Send, h.CC
		end

	---------
	-- ACO --
	---------
	if @doccategory = 'ACO'
		begin

		IF @ExistingTrans = 'N'
			BEGIN
				---- add transmittal to PMTM
				insert PMTM(PMCo, Project, Transmittal, Subject, TransDate, DateSent, DateDue, Issue,
							CreatedBy, VendorGroup, ResponsibleFirm, ResponsiblePerson, DateResponded)
				select @pmco, @project, @transmittal, @subject, @transdate, @datesent, @datedue, @issue,
							SUSER_SNAME(), @vendorgroup, @respfirm, @respperson, null

				SET @LINKID = SCOPE_IDENTITY()	
				---- INSERT RECORD LINK #141957	
				INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
				SELECT @RecTableName, @RECID, @LinkTableName, @LINKID
				WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@RecTableName
						AND v.RECID=@RECID AND v.LinkTableName=@LinkTableName AND v.LINKID=@LINKID)
			END
		END
		
	---------
	-- PCO --
	---------
	if @doccategory = 'PCO'
		begin

		IF @ExistingTrans = 'N'
			BEGIN
				---- add transmittal to PMTM
				insert PMTM(PMCo, Project, Transmittal, Subject, TransDate, DateSent, DateDue, Issue,
							CreatedBy, VendorGroup, ResponsibleFirm, ResponsiblePerson, DateResponded)
				select @pmco, @project, @transmittal, @subject, @transdate, @datesent, @datedue, @issue,
							SUSER_SNAME(), @vendorgroup, @respfirm, @respperson, null

				SET @LINKID = SCOPE_IDENTITY()	
				---- INSERT RECORD LINK #141957	
				INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
				SELECT @RecTableName, @RECID, @LinkTableName, @LINKID
				WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@RecTableName
						AND v.RECID=@RECID AND v.LinkTableName=@LinkTableName AND v.LINKID=@LINKID)
			END

		---- add source document to PMTS
		insert PMTS(PMCo, Project, Transmittal, Seq, DocType, Document, DocumentDesc, CopiesSent, Status)
		select @pmco, @project, @transmittal, isnull(max(Seq),0)+1, @doctype, @document, @docdesc, 1, null
		from PMTS where PMCo=@pmco and Project=@project and Transmittal=@transmittal
		---- add distributions to PMTC from source (PMCD)
		insert PMTC(PMCo, Project, Transmittal, Seq, VendorGroup, SentToFirm, SentToContact, Send, PrefMethod, CC, DateSent)
		select @pmco, @project, @transmittal, isnull(max(c.Seq),0) + ROW_NUMBER() OVER(ORDER BY c.PMCo ASC, c.Project ASC, c.Transmittal ASC),
				h.VendorGroup, h.SentToFirm, h.SentToContact, h.Send, h.PrefMethod, h.CC, @datesent
		from PMCD h with (nolock)
		left join PMTC c on c.PMCo=@pmco and c.Project=@project and c.Transmittal=@transmittal
		where h.PMCo=@pmco and h.Project=@project and h.PCOType=@doctype and h.PCO=@document and h.Send = 'Y'
		group by h.PMCo, h.Project, h.PCOType, h.PCO, c.PMCo, c.Project, c.Transmittal,
				 h.VendorGroup, h.SentToFirm, h.SentToContact, h.PrefMethod, h.Send, h.CC
		end


	commit transaction


	select @msg = 'Transmittal has been successfully added/updated.'
	end

END TRY

BEGIN CATCH
	begin
	IF @@TRANCOUNT > 0
		begin
		rollback transaction
		end
	select @msg = 'Transmittal insert/update failed. ' + ERROR_MESSAGE()
	select @rcode = 1
	end
END CATCH



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMTransmittalAdd] TO [public]
GO
