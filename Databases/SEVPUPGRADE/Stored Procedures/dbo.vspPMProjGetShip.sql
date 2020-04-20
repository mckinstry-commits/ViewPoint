SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************************/
CREATE proc [dbo].[vspPMProjGetShip]
/***********************************************************
 * Created By:	GF 04/14/2008 6.x
 * Modified By:
 *
 *
 * USAGE:
 * gets ship address for PM PO Header
 *
 * INPUT PARAMETERS
 * PMCo   		PM Co to validate against
 * Project    	Project to validate
 *
 * OUTPUT PARAMETERS
 * ShipAddress
 * ShipCity
 * ShipState
 * ShipZipCode
 * ShipAddress2
 * @msg      error message if error occurs 
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null,
 @shipaddress varchar(60) = null output, @shipcity varchar(30) = null output,
 @shipstate varchar(4) = null output, @shipzip bZip = null output,
 @shipaddress2 varchar(60) = null output, @shipcountry varchar(2) = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @pmco is null or @project = null
   	begin
   	goto bspexit
   	end


---- get job info
select @msg=Description, @shipaddress=ShipAddress, @shipcity=ShipCity,
		@shipstate=ShipState, @shipzip=ShipZip, @shipaddress2=ShipAddress2,
		@shipcountry=ShipCountry
from JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0
	begin
	select @msg = 'Project not on file!', @rcode = 1
	goto bspexit
	end








bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMProjGetShip] TO [public]
GO
