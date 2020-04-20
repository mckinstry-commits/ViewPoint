SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   procedure [dbo].[bspPMSSInitialize]
/*******************************************************************
* Created By:	GF 01/18/2002
* Modified By:	GF 06/28/2010 - issue #135813 SL expanded to 30 characters
*				SCOTTP 10/08/2013 TFS-62495 Update insert into PMSS to set
*									Seq, Send, CC, and PrefMethod fields
*				AJW 11/1/13 TFS-64229 670 hotfix merge
*
* Used to initialize PMSS SL Send to firm information
*
* PASS IN:
* PMCo		PM Company
* Project	PM Project
* SLCo		SL Company
* SL		SL Subcontract
*
*
* Returns 0 and message if successful
* Returns 1 and error message if error
********************************************************************/
(@pmco bCompany, @project bJob, @slco bCompany, @sl VARCHAR(30), @msg varchar(255) output)
as
set nocount on
   
   declare @rcode int, @vendorgroup bGroup, @ourfirm bFirm, @responsiblefirm bFirm,
   		@responsibleperson bEmployee, @sendtofirm bFirm, @sendtocontact bEmployee,
   		@vendor bVendor, @vendorfirm bFirm, @oldvendor bVendor, @prefmethod varchar(1)
   
   select @rcode = 0
   
   -- get information from bPMCO
   select @vendorgroup=VendorGroup from bPMCO with (nolock) where PMCo=@pmco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid PM Company', @rcode = 1
   	goto bspexit
   	end
   
   -- get vendor for subcontract
   select @vendor=Vendor from bSLHD with (nolock) where SLCo=@slco and SL=@sl
   if @@rowcount = 0
   	begin
   	select @msg = 'Missing SL subcontract', @rcode = 1
   	goto bspexit
   	end
   
   -- get vendor firm for subcontract vendor
   select @vendorfirm=FirmNumber
   from bPMFM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
   if @@rowcount = 0
   	begin
   	select @vendorfirm = null, @sendtocontact = null
   	end
   
   -- get our firm from bJCJM
   select @ourfirm=OurFirm from bJCJM with (nolock) where JCCo=@pmco and Job=@project
   if isnull(@ourfirm,0) = 0
   	begin
   	select @ourfirm=OurFirm from bPMCO with (nolock) where PMCo=@pmco
   	end
   
   -- validate in bPMSS
   select @responsiblefirm=ResponsibleFirm, @sendtofirm=SendToFirm
   from bPMSS with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco and SL=@sl
   if @@rowcount = 1
   		begin
   		-- update if OurFirm has changed
   		if @responsiblefirm <> @ourfirm
   			begin
   			Update bPMSS set VendorGroup=@vendorgroup, ResponsibleFirm=@ourfirm
   			where PMCo=@pmco and Project=@project and SLCo=@slco and SL=@sl
   			end
	   	
   		-- update if SendToFirm if needed
   		select @oldvendor=Vendor from bPMFM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@sendtofirm
   		if @@rowcount = 0 select @oldvendor = null
   		if isnull(@oldvendor,'') <> isnull(@vendor,'')
   			begin
   			Update bPMSS set SendToFirm=@vendorfirm
   			where PMCo=@pmco and Project=@project and SLCo=@slco and SL=@sl
   			end
	   
   		goto bspexit
   	end
   	
   -- find responsible person
   select @responsibleperson=min(ContactCode)
   from bPMPF with (nolock) where PMCo=@pmco and Project=@project and VendorGroup=@vendorgroup and FirmNumber=@ourfirm
   if @@rowcount = 0
   	begin
   	select @responsibleperson=min(ContactCode)
   	from bPMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@ourfirm
   	if @@rowcount = 0 select @responsibleperson=null
   	end
        
   -- find Send To Contact
   if isnull(@vendorfirm,0) <> 0
   	begin
   	select @sendtocontact=min(ContactCode)
   	from bPMPF with (nolock) where PMCo=@pmco and Project=@project and VendorGroup=@vendorgroup and FirmNumber=@vendorfirm
   	if @@rowcount = 0
   		begin
   		select @sendtocontact=min(ContactCode)
   		from bPMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@vendorfirm
   		if @@rowcount = 0 select @sendtocontact = null
   		end
   	end
   
	-- get PrefMethod for Contact
	if isnull(@vendorfirm,0) <> 0 AND isnull(@sendtocontact,0) <> 0
	begin
		select @prefmethod = PrefMethod
			from bPMPM
			where VendorGroup = @vendorgroup AND FirmNumber = @vendorfirm AND ContactCode = @sendtocontact	 
	end
	if isnull(@prefmethod,'') = '' set @prefmethod = 'M'
	  
   -- insert send to information into bPMSS
   insert bPMSS(PMCo, Project, SLCo, SL, VendorGroup, ResponsibleFirm, ResponsiblePerson, SendToFirm, SendToContact, Seq, [Send], PrefMethod, CC)
   select @pmco, @project, @slco, @sl, @vendorgroup, @ourfirm, @responsibleperson, @vendorfirm, @sendtocontact, 1, 'Y', @prefmethod, 'N'
      
   bspexit:
   	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSSInitialize] TO [public]
GO
