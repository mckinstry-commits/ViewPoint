SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPMSLFirmContactInit]
   /*******************************************************************************
   * Created By:   GF 05/03/2000
   * Modified By:  GF 08/25/2000 use firm once initialized
   *               GF 08/31/2000 if error occurs, don't return error
   *               GF 10/24/2001 - added sequence to PMPF
   *
   * Pass this SP all the info to initialize a vendor from AP Vendor Master into
   * PM Firm Master, PM Firm Contacts, and PM Project Firms.
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *   PMCo          PM Company
   *   Project       Project
   *   VendorGroup   VendorGroup the vendor is in
   *   Vendor        Vendor to initialize
   *
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   ********************************************************************************/
   (@pmco bCompany = null, @project bJob = null, @vendorgroup bGroup = null,
    @vendor bVendor = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @retcode int, @validcnt int, @firmtype bFirmType,
           @retmsg varchar(150), @contactcode bEmployee, @contactname bDesc,
           @description bDesc, @firm bFirm, @seq int
   
   select @rcode = 0, @firmtype = null
   
   if @pmco is null goto bspexit
   
   if @project is null goto bspexit
   
   if @vendorgroup is null goto bspexit
   
   if @vendor is null goto bspexit
   
   -- initialize vendor into PMFM if needed
   select @validcnt=count(*) from bPMFM with (nolock) 
   where VendorGroup=@vendorgroup and Vendor=@vendor
   if @validcnt = 0
       begin
       exec @retcode = bspPMFirmInitialize @vendorgroup,@vendor,@vendor,@firmtype, @retmsg output
       end
   
   select @firm=FirmNumber from bPMFM with (nolock) 
   where VendorGroup=@vendorgroup and Vendor=@vendor
   if @firm is null goto bspexit
   
   -- initialize contact into PMPM if needed
   select @validcnt=count(*) from bPMPM with (nolock) 
   where VendorGroup=@vendorgroup and FirmNumber=@firm
   if @validcnt = 0
       begin
       insert into bPMPM(VendorGroup,FirmNumber,ContactCode,SortName,LastName,FirstName,
                         MiddleInit,PrefMethod)
       select @vendorgroup, @firm, 1, 'NOTSPECIFIED', 'Specified', 'Not', Null, 'M'
       if @@rowcount = 0 goto bspexit
       end
   
   -- initialize firm and contact into PMPF if needed
   select @validcnt=count(*) from bPMPF with (nolock) 
   where PMCo=@pmco and Project=@project and VendorGroup=@vendorgroup and FirmNumber=@firm
   if @validcnt = 0
       begin
       select @contactcode=min(ContactCode) from bPMPM with (nolock) 
       where VendorGroup=@vendorgroup and FirmNumber=@firm
       if @@rowcount = 0 goto bspexit
   
       select @seq=1
       select @seq=isnull(Max(Seq),0)+1
       from bPMPF with (nolock) where PMCo=@pmco and Project=@project
       -- insert
       insert into bPMPF(PMCo,Project,Seq,VendorGroup,FirmNumber,ContactCode)
       select @pmco,@project,@seq,@vendorgroup,@firm,@contactcode
       if @@rowcount = 0 goto bspexit
       end
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSLFirmContactInit] TO [public]
GO
