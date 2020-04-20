SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMEHDestVal]
/*************************************
 * Created By:	GF 06/12/2007 6.x
 * Modified by:	
 *
 *
 * called from PM Project Budget Copy form to verify destination budget does not exist.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * BudgetNo		PM Project Budget No
 *
 * Returns:
 *
 *
 * Success returns:
 *	0
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @budgetno varchar(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- verify budget does not exist
if exists(select PMCo from PMEH where PMCo=@pmco and Project=@project and BudgetNo=@budgetno)
	begin
	select @msg = 'Destination budget exists for project, cannot copy into.', @rcode = 1
	goto bspexit
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMEHDestVal] TO [public]
GO
