SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPADesc    Script Date: 04/29/2005 ******/
CREATE   proc [dbo].[vspPMPCGetInfo]
/*************************************
 * Created By:	GF 08/10/2010 - issue #134354
 * Modified by:	
 *
 *
 *
 *
 * called from PM PCO Item Markups to return PMPC (project markup) info
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * CostType		PM Cost Type
 *
 * Returns:
 * RoundAmount
 *
 *
 **************************************/
(@PMCo bCompany, @Project bJob, @CostType bJCCType, 
 @RoundAmount char(1) = 'N' output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if @PMCo is null or @Project is null or @CostType is null
	begin
	set @RoundAmount = 'N'
	goto vspexit
	end
	
	
---- get project markup info
select @RoundAmount = RoundAmount
from dbo.PMPC where PMCo=@PMCo and Project=@Project and CostType=@CostType
if @@rowcount = 0 set @RoundAmount = 'N'



vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCGetInfo] TO [public]
GO
