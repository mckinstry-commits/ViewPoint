SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPMRFIVal]
/***********************************************************
 * Created By:	GF 06/05/2007
 * Modified By:
 *
 * USAGE:
 * Validates PM RFI
 * An error is returned if any of the following occurs
 *
 * no company passed
 * no project passed
 * no RFI type passed
 * no RFI found in PMRI
 *
 * INPUT PARAMETERS
 * PMCO- JC Company to validate against
 * PROJECT- project to validate against
 * RFITYPE - RFI Type to validate against
 * RFI - RFI to validate
 *
 * OUTPUT PARAMETERS
 * @msg - error message if error occurs otherwise Description of RFI in PMRI
 *  
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
*****************************************************/
(@pmco bCompany = null, @project bJob = null, @rfitype bDocType = null,
 @rfi bDocument = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @pmco is null
   	begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end

if @rfitype is null
   	begin
   	select @msg = 'Missing RFI Type!', @rcode = 1
   	goto bspexit
   	end

if @rfi is null
   	begin
   	select @msg = 'Missing RFI!', @rcode = 1
   	goto bspexit
   	end


---- validate RFI
select @msg = Subject
from PMRI with (nolock) where PMCo = @pmco and Project = @project and RFIType=@rfitype and RFI=@rfi
if @@rowcount = 0
   	begin
   	select @msg = 'RFI not on file!', @rcode = 1
   	goto bspexit
   	end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMRFIVal] TO [public]
GO
