SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPMPFirmContactDistAdd]
   /*******************************************************************************
   * Created By:   GF 02/02/2002 - Adds PM Project Firm from distribution grids
   * Modified By:  
   *
   * Pass this SP all the info to add a firm and contact to PM Project Firms.
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *   PMCo          PM Company
   *   Project       Project
   *   VendorGroup   VendorGroup
   *   Firm 		  Firm to add
   *	Contact		  Contact to add
   *
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   ********************************************************************************/
(@pmco bCompany = null, @project bJob = null, @vendorgroup bGroup = null,
@firm bVendor = null, @contact bEmployee = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @seq int

select @rcode = 0

if @pmco is null goto bspexit
if @project is null goto bspexit
if @vendorgroup is null goto bspexit
if @firm is null goto bspexit
if @contact is null goto bspexit

-- initialize firm and contact into PMPF if needed
if not exists(select 1 from bPMPF with (nolock) where PMCo=@pmco and Project=@project
			and VendorGroup=@vendorgroup and FirmNumber=@firm and ContactCode=@contact)
	begin
	if exists(select top 1 1 from bPMPM with (nolock) where VendorGroup=@vendorgroup
			and FirmNumber=@firm and ContactCode=@contact)
		begin
		select @seq=1
		select @seq=isnull(Max(Seq),0)+1
		from bPMPF with (nolock) where PMCo=@pmco and Project=@project
		---- insert
		insert into bPMPF (PMCo, Project, Seq, VendorGroup, FirmNumber, ContactCode)
		select @pmco, @project, @seq, @vendorgroup, @firm, @contact
		end
	end



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPFirmContactDistAdd] TO [public]
GO
