SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMEDSeqGet]
/*************************************
 * Created By:	GF 05/24/2007
 * Modified By:
 *
 *
 * USAGE:
 * Called from PM Project Budget costs grid to get the next sequential number
 *
 *
 * INPUT PARAMETERS
 * @pmco			PM Company
 * @project			PM Project
 * @budgetno		PM Budget No
 *
 * Success returns:
 *	0 and Next PMED sequence
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany = null, @project bJob = null, @budgetno varchar(10) = null,
 @next_seq int = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- get next sequence from PMED
select @next_seq = max(Seq) + 1
from PMED where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
if isnull(@next_seq,0) = 0 select @next_seq = 1



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMEDSeqGet] TO [public]
GO
