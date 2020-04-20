SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMECDesc    Script Date: 02/02/2006 ******/
CREATE proc [dbo].[vspPMECDesc]
/*************************************
 * Created By:	GF 05/24/2007 6.x
 * Modified By:
 *
 *
 * USAGE: checks budget code and returns description if any
 *
 *
 * INPUT PARAMETERS
 * @pmco			PM Company
 * @estcode			PM Budget Code to validate
 *
 *
 *
 * Success returns:
 * 0 and Description from PMEC
 *
 * Error returns:
 * 1 and error message
 **************************************/
(@pmco bCompany, @budgetcode varchar(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@budgetcode,'') <>''
	begin
	select @msg=Description
	from dbo.PMEC with (nolock) where PMCo=@pmco and BudgetCode=@budgetcode
	end




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMECDesc] TO [public]
GO
