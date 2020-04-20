SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE  proc [dbo].[bspPMCOPMOICheck]
/***********************************************************
 * Created By:	GF 04/10/2007 6.x 
 * Modified By:
 *
 * USAGE:
 * Called from the PM Change Orders to check if change order items
 * exist in PMOI before allowing delete.
 *
 *
 * INPUT PARAMETERS
 * PMCO			- PM Company
 * Project		- Project
 * COTypeFlag	- flag to indicate if deleting PCO or ACO (P or A)
 * PCOType		- PCO Type
 * PCO			- PCO
 * ACO			- ACO
 *
 *
 *
 * OUTPUT PARAMETERS
 *   @msg - error message if change order item exists in PMOI
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @cotypeflag varchar(1) = 'A', 
 @pcotype bDocType = null, @pco bPCO = null, @aco bACO = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

---- check PMOI for pending items
if isnull(@cotypeflag,'') = 'P'
	begin
	if exists(select PMCo from PMOI with (nolock) where PMCo=@pmco and Project=@project
				and PCOType=@pcotype and PCO=@pco)
		begin
		select @msg = 'Pending change order items exist, cannot delete.', @rcode = 1
		goto bspexit
		end
	end

---- check PMOI for approved items
if isnull(@cotypeflag,'') = 'A'
	begin
	if exists(select PMCo from PMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco)
		begin
		select @msg = 'Approved change order items exist, cannot delete.', @rcode = 1
		goto bspexit
		end
	end



bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMCOPMOICheck] TO [public]
GO
