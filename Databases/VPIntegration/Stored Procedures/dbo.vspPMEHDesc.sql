SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMEHDesc    Script Date: 03/01/2007 ******/
CREATE   proc [dbo].[vspPMEHDesc]
/*************************************
 * Created By:	GF 03/01/2007 6.x
 * Modified by:	
 *
 *
 * called from PMProjectEstimates to return project budget key description.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * Estimate		PM Project Budget No
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

if isnull(@budgetno,'') <> ''
	begin
	-- -- -- get project estimate description
	select @msg = Description
	from PMEH with (nolock) where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMEHDesc] TO [public]
GO
