SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create  proc [dbo].[vspPMRFIExistsVal]
/***********************************************************
 * Created By:	DC 10/1/2010
 * Modified By:
 *
 * USAGE:
 * Validates PM RFI
 * An error is returned if any of the following occurs
 *
 * no company passed
 * no project passed
 * no RFI type passed
 * RFI found in PMRI  **  This procedure is checking to make sure the RFI entered does NOT exists
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
   	goto vspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto vspexit
   	end

if @rfitype is null
   	begin
   	select @msg = 'Missing RFI Type!', @rcode = 1
   	goto vspexit
   	end

if @rfi is null
   	begin
   	select @msg = 'Missing RFI!', @rcode = 1
   	goto vspexit
   	end


---- validate RFI
select @msg = Subject
from PMRI with (nolock) where PMCo = @pmco and Project = @project and RFIType=@rfitype and RFI=@rfi
if @@rowcount = 1
   	begin
   	select @msg = 'RFI already on file!', @rcode = 1
   	goto vspexit
   	end





vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMRFIExistsVal] TO [public]
GO
