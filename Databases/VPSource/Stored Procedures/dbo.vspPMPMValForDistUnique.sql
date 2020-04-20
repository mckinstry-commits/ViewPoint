SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPMValForDistUnique    Script Date: 04/12/2005 ******/
CREATE proc [dbo].[vspPMPMValForDistUnique]
/*************************************
 * Created By:	GF 07/24/2009
 * Modified By:	GP 09/15/2009 - 133966 added @EmailOption and select statement
 *				GF 10/24/2009 - issue #134090 added submittal and drawing log checks
 *				GF 10/01/2010 - issue #141553 added project issues TFS#791
 *				GP 02/14/2011 - added subcontract change order check
 *				DAN SO 03/26/2011 - TK-03028 - added COR parent table
 *				GF 04/22/2011 - TK-00000 problems with check for POCO and COR
 *				JG 05/02/2011 - TK-04388 CCO
 *				JG 05/04/2011 - TK-04386 - Updated for ACO
 *				JG 05/19/2011 - TK-04386 - Removed ACO
 *
 *
 *
 * validates PM Firm Contact, used in various PM Document Forms to validate sent to firm
 * and contact in the distribution table. This validation is for the new distribution grids
 * we are adding to existing PM Forms. We will pass in the partent table name and key id
 * to validate that the firm contact exists only once per document record. 
 * This has been added for the new distributions, existing distirbutions allowed firm contact
 * to be used more than once.
 *
 * Current PM Forms this validation is used in:
 * PM Test Logs, PM Inspection Logs, PM Submittals, PM Drawing Logs, PM Project Issues
 * 
 * Will add others in the future as we enable document create and send functionality
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * VendorGroup	AP Vendor Group
 * Firm			PM Firm
 * ContactSort  Contact or contact sort name to validate
 * ParentTable	PM document form table name
 * ParentKeyId	PM Document form record key id
 *
 * Returns:
 * ContactOut	Validated contact number
 * PrefMethod	Contact preferred method of contact
 * Email		Contact email address
 * Fax			Contact fax number
 * Exists		Flag to signify if firm/contact exists for project in PMPF
 *
 * Success returns:
 * ContactNumber and Contact Name
 *
 * Error returns:
 *  
 *	1 and error message
  **************************************/
(@pmco bCompany, @project bJob, @vendorgroup bGroup, @firm bFirm, @contactsort bSortName,
 @parenttable varchar(50), @parentkeyid bigint, @contactout bEmployee=null output,
 @prefmethod varchar(1) output, @email varchar(60) output, @fax varchar(20) output,
 @exists bYN output, @EmailOption char(1) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @exists = 'N'

if @pmco is null
  	begin
  	select @msg = 'Missing PM Company!', @rcode = 1
  	goto bspexit
  	end

if @project is null
  	begin
  	select @msg = 'Missing PM Project!', @rcode = 1
  	goto bspexit
  	end

if @firm is null
  	begin
  	select @msg = 'Missing Firm!', @rcode = 1
  	goto bspexit
  	end

if @contactsort is null
  	begin
  	select @msg = 'Missing Contact!', @rcode = 1
  	goto bspexit
  	end

if @parenttable is null
	begin
	select @msg = 'Missing Document Record Information!', @rcode = 1
  	goto bspexit
  	end

if @parentkeyid is null
	begin
	select @msg = 'Missing Document Record Key Id!', @rcode = 1
  	goto bspexit
  	end
  	

-- if contact is not numeric then assume a SortName
if dbo.bfIsInteger(@contactsort) = 1
	begin
  	if len(@contactsort) < 7
  		begin
  		-- validate firm to make sure it is valid to use
  		select @contactout = ContactCode, @prefmethod=PrefMethod, @email=EMail, @fax=Fax,
				@msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
  		from dbo.PMPM with (nolock) 
		where VendorGroup = @vendorgroup and FirmNumber = @firm and ContactCode = convert(int,convert(float, @contactsort))
  		end
  	end

-- -- -- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @contactout=ContactCode, @prefmethod=PrefMethod, @email=EMail, @fax=Fax,
			@msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
	from dbo.PMPM with (nolock) 
	where VendorGroup = @vendorgroup and FirmNumber = @firm and SortName = @contactsort
	-- -- -- if not found,  try to find closest
	if @@rowcount = 0
		begin
		set rowcount 1
		select @contactout=ContactCode, @prefmethod=PrefMethod, @email=EMail, @fax=Fax,
				@msg = isnull(FirstName,'') + ' ' + isnull(MiddleInit,'') + ' ' + isnull(LastName,'')
		from dbo.PMPM with (nolock) 
  		where VendorGroup = @vendorgroup and FirmNumber = @firm and SortName like @contactsort + '%'
		if @@rowcount = 0
			begin
			select @msg = 'Firm Contact ' + convert(varchar(15),isnull(@contactsort,'')) + ' not on file!', @rcode = 1
			goto bspexit
			end
		end
	end


-- -- check PMPF to see if firm/contact exists for project
select @EmailOption = EmailOption from dbo.PMPF with (nolock) where PMCo=@pmco and Project=@project
	and VendorGroup=@vendorgroup and FirmNumber=@firm and ContactCode=@contactout
if @@rowcount > 0
begin
	select @exists = 'Y'
end		


---- depending on parent table - validate that the firm contact is unique for the main document
-- TK-03028 --
if @parenttable = 'PMChangeOrderRequest'
	begin
	---- check for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where CORID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this Change Order Request.', @rcode = 1
		goto bspexit
		end
	end
	
else if @parenttable = 'PMContractChangeOrder'
	begin
	---- check for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where ContractCOID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this Contract Change Order.', @rcode = 1
		goto bspexit
		end
	end
	
else if @parenttable = 'PMSubcontractCO'
	begin
	---- check distribution for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where SubcontractCOID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this subcontract change order.', @rcode = 1
		goto bspexit
		end
	end

else if @parenttable = 'PMTL'
	begin
	---- check TEST logs for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where TestLogID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this test log.', @rcode = 1
		goto bspexit
		end
	end

else if @parenttable = 'PMIL'
	begin
	---- check INSPECTION logs for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where InspectionLogID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this inspection log.', @rcode = 1
		goto bspexit
		end
	end

else if @parenttable = 'PMSM'
	begin
	---- check Submittal for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where SubmittalID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this submittal.', @rcode = 1
		goto bspexit
		end
	end
	
else if @parenttable = 'PMDG'
	begin
	---- check Drawing Log for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where DrawingLogID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this drawing log.', @rcode = 1
		goto bspexit
		end
	end

else if @parenttable = 'POHDPM'
	begin
	---- check Purchase Orders for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where PurchaseOrderID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this purchase order.', @rcode = 1
		goto bspexit
		end
	end

----#141553  TFS#791
else if @parenttable = 'PMIM'
	begin
	---- check distribution for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where IssueID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this project issue.', @rcode = 1
		goto bspexit
		end
	end

----TK-00000
else if @parenttable = 'PMPOCO'
	begin
	---- check distribution for uniqueness
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where POCOID = @parentkeyid
				and VendorGroup=@vendorgroup and SentToFirm=@firm and SentToContact=@contactout)
		begin
		select @msg = 'Firm: ' + convert(varchar(8), isnull(@firm,'')) + ' Contact: ' + convert(varchar(8),isnull(@contactout,'')) + ' already exists in distribution grid for this PO change order.', @rcode = 1
		goto bspexit
		end
	end



bspexit:
  	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPMValForDistUnique] TO [public]
GO
