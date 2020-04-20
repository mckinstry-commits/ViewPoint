SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWPhaseVal    Script Date: 8/28/99 9:35:23 AM ******/
CREATE proc [dbo].[bspPMWPhaseVal]
/*************************************
 * validates PMWP Phase
 * Modified By:	 GF 05/26/2006 - #27996 - 6.x changes
 *
 * Pass:
 *	PM Import Id, Phase
 *
 * Success returns:
 *	0 and Description
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany = null, @importid varchar(10) = null, @phase bPhase = null, @msg varchar(255) output)
 as 
set nocount on

declare @rcode int

select @rcode = 0

if @importid is null
	begin
	select @msg='Missing Import Id', @rcode=1
	goto bspexit
	end

if @phase is null
	begin
	select @msg='Missing Phase', @rcode=1
	goto bspexit
	end


select distinct @msg=Description 
from bPMWP where PMCo=@pmco and ImportId=@importid and Phase=@phase
if @@rowcount = 0 
	begin
	select @msg='Invalid Phase', @rcode=1
	goto bspexit
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWPhaseVal] TO [public]
GO
