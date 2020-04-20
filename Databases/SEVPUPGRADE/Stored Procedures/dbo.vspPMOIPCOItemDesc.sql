SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMOIPCOItemDesc    Script Date: 10/13/2005 ******/
CREATE  proc [dbo].[vspPMOIPCOItemDesc]
/*************************************
 * Created By:	GF 10/13/2005
 * Modified by:	GP/GPT	06/28/2011 - TK-06226 Added @PMSLExists and @PMMFExists output params
 *
 * called from PMPCOSItems to return PCO Item key description.
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * PCOType		PM PCO Type
 * PCO			PM PCO
 * PCOItem		PM PCO Item
 *
 * Returns:
 * PMOLExists	PMOL Detail exists flag
 *
 * Success returns:
 *	0 and Description from PMOP
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO,
 @pcoitem bPCOItem, @pmol_exists bYN = 'N' output, @PMSLExists bYN = 'N' output, @PMMFExists bYN = 'N' output, 
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

-- -- -- get description from PMOI
if isnull(@pcoitem,'') <> ''
begin
	select @msg = Description
	from PMOI with (nolock) 
	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
	if @@rowcount <> 0
	begin
		if exists(select top 1 1 from PMOL with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem)
			select @pmol_exists = 'Y'
		else
			select @pmol_exists = 'N'
	end
	
	--check for subcontract and material detail
	if exists (select top 1 1 from dbo.PMSL where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem)
	begin
		set @PMSLExists = 'Y'
	end
	
	if exists (select top 1 1 from dbo.PMMF where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem)
	begin
		set @PMMFExists = 'Y'
	end
end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMOIPCOItemDesc] TO [public]
GO
