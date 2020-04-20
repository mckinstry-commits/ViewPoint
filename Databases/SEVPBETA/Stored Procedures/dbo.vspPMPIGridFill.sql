SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE   procedure [dbo].[vspPMPIGridFill]
/************************************************************************
 * Created By:	GF 06/21/2005    
 * Modified By:    
 *
 * Purpose of Stored Procedure
 * Get list of punch list items from PMPI for from punch list for copying into to punch list
 *    
 *           
 * Notes about Stored Procedure
 * 
 *
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 *************************************************************************/
(@pmco bCompany, @project bJob, @punchlist bDocument, @unfinished_only bYN)
as
set nocount on

declare @rcode int
  
select @rcode = 0

-- -- -- if @unfinished_only = 'Y' then PMPI.FinDate must be null
if @unfinished_only = 'Y'
	begin
	select PMPI.Item, PMPI.Description
	from PMPI with (nolock)
	where PMPI.PMCo=@pmco and PMPI.Project=@project and PMPI.PunchList=@punchlist and PMPI.FinDate is null
	order by PMPI.Item, PMPI.Description
	end
else
	begin
	select PMPI.Item, PMPI.Description
	from PMPI with (nolock)
	where PMPI.PMCo=@pmco and PMPI.Project=@project and PMPI.PunchList=@punchlist
	order by PMPI.Item, PMPI.Description
	end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPIGridFill] TO [public]
GO
