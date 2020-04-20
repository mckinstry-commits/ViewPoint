SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMSSVal]
/*************************************
 * Created By:	GF 05/22/2007
 * Modified By:  DC 06/30/10 - #135813 - expand subcontract number
 *
 *
 * validates that a PMSS send to firm contact are setup for subcontract
 * Called from frmPMSLHeader before running document tools.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * SLCo			SL Company
 * SL			SL
 *
 * Error returns:
 *	1 and error message
  **************************************/
(@pmco bCompany, @project bJob, @slco bCompany, @sl VARCHAR(30),
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @senttofirm bVendor, @senttocontact bEmployee

select @rcode = 0

---- get send to firm and contact
select @senttofirm=SendToFirm, @senttocontact=SendToContact
from PMSS with (nolock) where PMCo=@pmco and Project=@project and SLCo=@slco and SL=@sl
if @@rowcount = 0
	begin
	select @msg = 'Missing send to information.', @rcode = 1
	goto bspexit
	end

if @senttofirm is null
	begin
	select @msg = 'Missing Send To Firm.', @rcode = 1
	goto bspexit
	end

----if @senttocontact is null
----	begin
----	select @msg = 'Missing Send To Contact.', @rcode = 1
----	goto bspexit
----	end



bspexit:
  	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSSVal] TO [public]
GO
