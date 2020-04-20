SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPAFixedACOItemVal    Script Date: 04/20/2005 ******/
CREATE proc [dbo].[vspPMPAFixedACOItemVal ]
/*************************************
 * Created By:	GF 05/12/2008
 * Modified by:
 *
 * called from PMProjectAddons to validate the fixed ACO Item for re-directing
 * revenue is not already assigned to another add-on.
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * AddOn		PM Company Addon
 * RevItem		PM Revenue contract item
 * ACOItem		PM ACO Item
 * RevUseItem	PM Addon Create ACO Item option
 *
 *
 * Success returns:
 *	0 and Description from PMPA
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @addon tinyint, @revitem bContractItem = null,
 @acoitem bACOItem = null, @revuseitem char(1) = 'U', @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if isnull(@project,'') = '' goto bspexit
if isnull(@addon,0) = 0 goto bspexit
if isnull(@acoitem,'') = '' goto bspexit
if isnull(@revuseitem,'U') <> 'F' goto bspexit


---- validate ACO Item not already assigned to a different addon where the revenue items are different
if exists(select PMCo from PMPA with (nolock) where PMCo=@pmco and Project=@project
		and RevFixedACOItem=@acoitem and AddOn <> @addon and RevUseItem = 'F' and RevItem <> @revitem)
	begin
	select @msg = 'Invalid ACO Item. In use on another Add-on with a different revenue contract item.', @rcode = 1
	goto bspexit
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPAFixedACOItemVal ] TO [public]
GO
