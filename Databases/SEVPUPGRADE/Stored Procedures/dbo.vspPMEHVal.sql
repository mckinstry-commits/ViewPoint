SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMEHVal    Script Date: 03/01/2007 ******/
CREATE  proc [dbo].[vspPMEHVal]
/*************************************
 * Created By:	GF 06/05/2007 6.x
 * Modified by:	
 *
 *
 * called from PM Change Order Items to validate the Budget No.
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
 *	0 and Description from PMEH
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @budgetno varchar(10), 
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

select @msg = Description
from PMEH with (nolock) where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
if @@rowcount = 0
	begin
	select @msg = 'Invalid Budget Number.', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMEHVal] TO [public]
GO
