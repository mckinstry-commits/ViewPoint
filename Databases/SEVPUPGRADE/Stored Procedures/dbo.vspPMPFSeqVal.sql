SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPFSeqVal    Script Date: 08/22/2005 ******/
CREATE proc [dbo].[vspPMPFSeqVal]
/*************************************
 * Created By:	GF 10/16/2007
 * Modified By:
 *
 *
 * validates PM Project Firm/Contact is unique for the project in PMPF.
 * Called from PMProjectFirms
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * Firm			PM Project Firm
 * Contact		PM Project Firm Contact
 * Seq			PM Project Sequence
 *
 * Returns:
 * Seq_out		new sequence number if needed
 *
 * Success returns:
 *
 *
 * Error returns:
 *  
 *	1 and error message
  **************************************/
(@pmco bCompany, @project bJob, @firm bVendor, @contact bEmployee = null, @seq int = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @seq is null select @seq = -1

if @pmco is null or @project is null or @firm is null or @contact is null goto bspexit

---- check PMPF for duplicates
if @seq > 0
	begin
	if exists(select FirmNumber from PMPF where PMCo=@pmco and Project=@project and FirmNumber=@firm
			and ContactCode=@contact and Seq<>@seq)
		begin
		select @msg = 'Firm and Contact already exists in Project Firms for this project.', @rcode = 1
		goto bspexit
		end
	end
else
	begin
	if exists(select FirmNumber from PMPF where PMCo=@pmco and Project=@project and FirmNumber=@firm
			and ContactCode=@contact)
		begin
		select @msg = 'Firm and Contact already exists in Project Firms for this project.', @rcode = 1
		goto bspexit
		end
	end




bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPFSeqVal] TO [public]
GO
