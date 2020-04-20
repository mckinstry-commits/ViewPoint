SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************************************/
CREATE procedure [dbo].[vspPMDocDistInitCCListBuild]
/************************************************************************
* Created By:	GF 07/14/2009 - issue #24641
* Modified By:	GF 10/30/2009 - issue #134090 added submittals
*				GF 02/24/2010 - issue #135479 added drawing logs
*				GF 03/12/2010 - issue #120252 added purchase orders
*				GF 10/18/2010 - TFS #793 added project issues
*				GF 03/18/2011 - TK-02604
*				GF 04/22/2011 - ISSUE #143823 TK-04302
*				JG 05/06/2011 - TK-04388 CCO, COR
*				GF 01/21/2011 TK-11961 #145567 @DocumentID added
*
*
*
*
* Purpose of Stored Procedure is to create a list of Cc Addresses, Bcc Addresses, and CC Names
* that will appear in the document and email if used
*
*
*
* Input parameters:
* PM Company	Company
* Project		Project
* DocCat		Document Category
* DocType		Document Type
* Document		Document Code
* PCO			PCO for RFQ category
* ViewName		Distribution table to use
*
* Output parameters:
* @ccnames		Cc List information for document
* @ccaddr		Cc Addresses
* @bccaddr		Bcc Addresses
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany = null, @project bProject = null, @doccategory varchar(10) = null, 
 @doctype VARCHAR(30) = null, @document VARCHAR(30) = null, @pco VARCHAR(10) = NULL,
 @revision tinyint = null, @DocumentID BIGINT = NULL,
 @ccnames nvarchar(max) = null output,
 @ccaddr nvarchar(max) = null output, @bccaddr nvarchar(max) = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor int, @vendorgroup bGroup, @firm bVendor, @contact bEmployee,
		@value nvarchar(max), @usestdcclist varchar(1), @ovrcclist varchar(max), @cc varchar(1),
		@ccresult nvarchar(max)

select @rcode = 0, @opencursor = 0, @ccnames = '', @ccaddr = '', @bccaddr = '',
		@usestdcclist = 'Y', @ovrcclist = null


---- get document category information
select @usestdcclist=UseStdCCList, @ovrcclist=OvrCCList
from dbo.PMCU with (nolock) where DocCat = @doccategory

select @ccaddr = '', @bccaddr = '', @ccnames = ''
---- declare cursor on the distribution table that we will build CC information from
if @doccategory = 'OTHER'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.PMOC
	where PMCo=@pmco and Project=@project and DocType=@doctype
	and Document=@document and Send = 'Y' and CC in ('B','C')
	goto Cursor_Open
	end
if @doccategory = 'TEST'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	where PMCo=@pmco and Project=@project and TestType=@doctype
	and TestCode=@document and Send = 'Y' and CC in ('B','C')
	AND TestLogID IS NOT NULL
	goto Cursor_Open
	end
if @doccategory = 'INSPECT'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	where PMCo=@pmco and Project=@project and InspectionType=@doctype
	and InspectionCode=@document and Send = 'Y' and CC in ('B','C')
	AND InspectionLogID IS NOT NULL
	goto Cursor_Open
	end
if @doccategory = 'RFI'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.PMRD
	where PMCo=@pmco and Project=@project and RFIType=@doctype
	and RFI=@document and Send = 'Y' and CC in ('B','C')
	goto Cursor_Open
	END
if @doccategory = 'RFQ'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.PMQD
	where PMCo=@pmco and Project=@project and PCOType=@doctype
	and PCO=@pco AND RFQ=@document and Send = 'Y' and CC in ('B','C')
	goto Cursor_Open
	END
if @doccategory = 'PCO'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.PMCD
	where PMCo=@pmco and Project=@project and PCOType=@doctype
	and PCO=@document and Send = 'Y' and CC in ('B','C')
	goto Cursor_Open
	end
if @doccategory = 'TRANSMIT'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.PMTC
	where PMCo=@pmco and Project=@project and Transmittal=@document and Send = 'Y' and CC in ('B','C')
	goto Cursor_Open
	end
----#134090
if @doccategory = 'SUBMIT'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	where PMCo=@pmco and Project=@project and SubmittalType=@doctype
	and Submittal=@document and Rev=@revision and Send = 'Y' and CC in ('B','C')
	AND SubmittalID IS NOT NULL
	goto Cursor_Open
	end
----#135479
if @doccategory = 'DRAWING'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	where PMCo=@pmco and Project=@project and DrawingType=@doctype
	and Drawing=@document and Send = 'Y' and CC in ('B','C')
	AND DrawingLogID IS NOT NULL
	goto Cursor_Open
	end
----#120252
if @doccategory = 'PURCHASE'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	where PMCo=@pmco and Project=@project and POCo=@revision
	and PO=@document and Send = 'Y' and CC in ('B','C')
	AND PurchaseOrderID IS NOT NULL
	goto Cursor_Open
	end
----TFS #793
if @doccategory = 'ISSUE'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	where PMCo=@pmco and Project=@project and Issue=CONVERT(INT,@document)
	and Send = 'Y' and CC in ('B','C')
	AND IssueID IS NOT NULL
	goto Cursor_Open
	end

----TK-02604
if @doccategory = 'SUBCO'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	----TK-11961
	WHERE SubcontractCOID = @DocumentID
	----where PMCo=@pmco and Project=@project and SubCO=CONVERT(INT, @document)
	and Send = 'Y' and CC in ('B','C')
	----AND SubcontractCOID IS NOT NULL
	goto Cursor_Open
	END

if @doccategory = 'PURCHASECO'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	----TK-11961
	WHERE POCOID = @DocumentID
	----where PMCo=@pmco and Project=@project and POCONum=CONVERT(INT, @document)
	and Send = 'Y' and CC in ('B','C')
	----AND POCOID IS NOT NULL
	goto Cursor_Open
	END
	
----TK-04388
if @doccategory = 'CCO'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	where PMCo=@pmco and [Contract]=@project and ID=CONVERT(INT, @document)
	and Send = 'Y' and CC in ('B','C')
	AND ContractCOID IS NOT NULL
	goto Cursor_Open
	end
----TK-04388
if @doccategory = 'COR'
	begin
	declare bcCCInfo cursor LOCAL FAST_FORWARD for select VendorGroup, SentToFirm, SentToContact, CC
	from dbo.vPMDistribution
	where PMCo=@pmco and CORContract=@project and COR=CONVERT(INT, @document)
	and Send = 'Y' and CC in ('B','C')
	AND CORID IS NOT NULL
	goto Cursor_Open
	end	


goto clean_up

---- open bcCCInfo cursor
Cursor_Open:
open bcCCInfo
select @opencursor = 1

---- loop through distribution list
CCInfo_loop:
fetch next from bcCCInfo into @vendorgroup, @firm, @contact, @cc

if @@fetch_status = -1 goto CCInfo_end
if @@fetch_status <> 0 goto CCInfo_loop

---- build CC Names and CC Addresses
if @cc = 'C'
	begin
	if @usestdcclist = 'Y'
		begin
		select @ccaddr = @ccaddr + isnull(b.EMail,'') + '; ',
				@ccnames = @ccnames + isnull(b.FirstName,'') + ' ' +  isnull(b.LastName,'') + ' - ' + isnull(c.FirmName,'') + ' - Phone: ' + isnull(b.Phone,'') + ' - Fax: ' + isnull(b.Fax,'') + ', ' + CHAR(13) + CHAR(10)
		from dbo.PMPM b with (nolock)
		join dbo.PMFM c with (nolock) on c.VendorGroup=b.VendorGroup and c.FirmNumber=b.FirmNumber
		where b.VendorGroup = @vendorgroup and b.FirmNumber = @firm and b.ContactCode = @contact
		end
	else
		begin
		select @ccaddr = @ccaddr + isnull(b.EMail,'') + '; '
		from dbo.PMPM b with (nolock)
		join dbo.PMFM c with (nolock) on c.VendorGroup=b.VendorGroup and c.FirmNumber=b.FirmNumber
		where b.VendorGroup = @vendorgroup and b.FirmNumber = @firm and b.ContactCode = @contact
		end
	end

if @cc = 'B'
	begin
	select @bccaddr = @bccaddr + isnull(b.EMail,'') + '; '
	from dbo.PMPM b with (nolock)
	join dbo.PMFM c with (nolock) on c.VendorGroup=b.VendorGroup and c.FirmNumber=b.FirmNumber
	where b.VendorGroup = @vendorgroup and b.FirmNumber = @firm and b.ContactCode = @contact
	end
	

if isnull(@usestdcclist,'Y') = 'N' and @cc = 'C'
	begin
	set @ccresult = ''
	exec @rcode = dbo.vspPMDocCatCCListCreate @pmco, @doccategory, @ovrcclist, @vendorgroup, @firm, @contact, @ccresult output
	select @ccnames = @ccnames + isnull(@ccresult,'') + CHAR(13) + CHAR(10)
	end


goto CCInfo_loop

---- deallocate cursor
CCInfo_end:
	if @opencursor = 1
		begin
		close bcCCInfo
		deallocate bcCCInfo
		set @opencursor = 0
		end
		
		
clean_up:
----ISSUE #143823 TK-04302
SET @ccaddr = LTRIM(RTRIM(@ccaddr))
SET @bccaddr = LTRIM(RTRIM(@bccaddr))
SET @ccnames = LTRIM(RTRIM(@ccnames))

if isnull(@ccnames,'') = '' select @ccnames = null
if isnull(@ccaddr,'') = '' select @ccaddr = null
if isnull(@bccaddr,'') = '' select @bccaddr = null

if isnull(@ccaddr,'') <> ''
	begin
	select @ccaddr = left(@ccaddr, len(@ccaddr)- 1) -- remove last semi-colon
	end
if isnull(@bccaddr,'') <> ''
	begin
	select @bccaddr = left(@bccaddr, len(@bccaddr)- 1) -- remove last semi-colon
	end
if isnull(@ccnames,'') <> '' and @usestdcclist = 'Y'
	begin
	select @ccnames = left(@ccnames, len(@ccnames) - 4)  --remove last comma
	end




bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocDistInitCCListBuild] TO [public]
GO
