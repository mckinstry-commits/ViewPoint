SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--CREATE PROC [dbo].[vspPMDistInspectionLogsInit]
CREATE PROC [dbo].[vspPMDistPurchaseOrdersInit]
/*************************************
* Created By:		CHS	03/02/2009	- Issue #120252
* Modified By:		GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
*					SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent,DateReqd columns
*					SCOTTP 07/11/2013 TFS-54435 Remove code that disallows multiple "TO" Contacts 
* 
* Pass this a Firm contact and it will initialize an Purchase Order
* distribution line in the vPMDistribution table.
* 
* 
* Pass:
* PMCO				PM Company this Other Document is in
* Project			Project for the Other Document
* POCo				PM PO Company
* PO				PM PO
* SentToFirm		Sent to firm to initialize
* SentToContact		Contact to initialize to
* PurchaseOrderID	Purchase Order record KeyID
*
* Returns:
* MSG if Error
* Success returns:
* 0 on Success, 1 on ERROR
* 
* Error returns:
* 
*	1 and error message
**************************************/
(@PMCo bCompany = null, @Project bJob = null, @POCo bCompany = null, @PO varchar(30) = null,
 @SentToFirm bFirm = null, @SentToContact bEmployee = null, 
 @PurchaseOrderID bigint = null, 
 @msg varchar(255) = null output)

as
set nocount on
   
declare @rcode int, @VendorGroup bGroup, @Seq bTrans, @PrefMethod varchar(1),
		@EmailOption char(1), @vendor bVendor, @firm_vendor bVendor

select @rcode = 0

--Check for nulls
if @PMCo is null or @Project is null or @POCo is null or @PO is null or
   @SentToFirm is null or @SentToContact is null
	begin
	select @msg = 'Missing information!', @rcode = 1
	goto bspexit
	end

--Get VendorGroup
select @VendorGroup = h.VendorGroup
from dbo.bHQCO h with (nolock) join dbo.bPMCO p with (nolock) on h.HQCo = p.APCo
where p.PMCo = @PMCo

--Get Prefered Method
select @PrefMethod = PrefMethod
from dbo.bPMPM with (nolock) where VendorGroup = @VendorGroup and FirmNumber = @SentToFirm and ContactCode = @SentToContact
if isnull(@PrefMethod,'') = '' select @PrefMethod = 'M'

--Get EmailOption,
select @EmailOption = isnull(EmailOption,'N') from dbo.bPMPF with (nolock)
where PMCo=@PMCo and Project=@Project AND VendorGroup=@VendorGroup
and FirmNumber=@SentToFirm and ContactCode=@SentToContact

---- get vendor for PO
SELECT @vendor = Vendor FROM dbo.bPOHD WITH (NOLOCK) WHERE POCo=@POCo AND PO=@PO
IF @@ROWCOUNT = 0 SET @vendor = NULL
---- get firm vendor from Firm Master
SELECT @firm_vendor = Vendor FROM dbo.bPMFM (NOLOCK) WHERE VendorGroup = @VendorGroup AND FirmNumber = @SentToFirm
IF @@ROWCOUNT = 0 SET @firm_vendor = NULL
	
---- check if already in distribution table for test logs
IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution WITH (NOLOCK) WHERE PMCo=@PMCo 
						AND Project=@Project AND VendorGroup=@VendorGroup 
						AND SentToFirm=@SentToFirm AND SentToContact=@SentToContact
						AND POCo=@POCo AND PO=@PO)
	BEGIN
	
	--Get next Seq
	select @Seq = 1
	select @Seq = isnull(Max(Seq),0) + 1
	from vPMDistribution with (nolock) where PMCo = @PMCo and Project = @Project AND POCo=@POCo AND PO=@PO

	--Insert vPMDistribution record for Purchase Orders
	insert into vPMDistribution(PMCo, Project, POCo, PO, Seq, VendorGroup, SentToFirm, SentToContact, 
		PrefMethod, Send, CC, PurchaseOrderID)
	values(@PMCo, @Project, @POCo, @PO, @Seq, @VendorGroup, @SentToFirm, @SentToContact, 
		@PrefMethod, 'Y', @EmailOption, @PurchaseOrderID)
	if @@rowcount = 0
		begin
		select @msg = 'Nothing inserted!', @rcode=1
		goto bspexit
		end

	if @@rowcount > 1
		begin
		select @msg = 'Too many rows affected, insert aborted!', @rcode=1
		goto bspexit
		end
   
   END



bspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMDistPurchaseOrdersInit] TO [public]
GO
