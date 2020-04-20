SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMOIACOItemDesc    Script Date: 11/15/2005 ******/
CREATE  proc [dbo].[vspPMOIACOItemDesc]
/*************************************
 * Created By:	GF 11/15/2005
 * Modified by:
 *
 * called from PMACOSItems to return ACO Item key description.
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * ACO			PM ACO
 * ACOItem		PM ACO Item
 *
 * Returns:
 * PMOLExists	PMOL Detail exists flag
 *
 * Success returns:
 *	0 and Description from PMOI
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @aco bACO, @acoitem bACOItem,
 @pmol_exists bYN = 'N' output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

-- -- -- get description from PMOI
if isnull(@acoitem,'') <> ''
	begin
	select @msg = Description
	from PMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
	if @@rowcount <> 0
		begin
		if exists(select top 1 1 from PMOL with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem)
			select @pmol_exists = 'Y'
		else
			select @pmol_exists = 'N'
		end
	end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMOIACOItemDesc] TO [public]
GO
