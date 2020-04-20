SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspJCPurgeContractsJobs]
/****************************************************************************
 * Created By:	DANF 09/20/2006
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to popoulate Purge Contract and Job List
 *
 * INPUT PARAMETERS:
 * JC Company
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@jcco bCompany = null, @contract bContract = null, @month bMonth = null)
as
set nocount on

declare @rcode int,@phasegroup bGroup

select @rcode = 0

if @jcco is null or (@contract is null and @month is null)
	begin
		goto bspexit
	end

if isnull(@contract,'') = '' 
	begin
		Select '  C' as Purge, JCCM.JCCo as Company, JCCM.Contract as Contract, '' as Job,  JCCM.Description as Description, '' as Message
		from JCCM JCCM with (nolock)
		where JCCM.JCCo = @jcco and JCCM.MonthClosed <= @month and JCCM.ContractStatus = 3
		union
		Select '  J', JCJM.JCCo, JCJM.Contract, JCJM.Job, JCJM.Description, '' Note
		from JCJM JCJM with (nolock)
		join JCCM JCCM with (nolock)
		on JCJM.JCCo = JCCM.JCCo and JCJM.Contract = JCCM.Contract and JCCM.MonthClosed <= @month and JCCM.ContractStatus = 3
		where JCJM.JCCo = @jcco
		order by JCCM.JCCo, JCCM.Contract
	end
	else
	begin
		Select '  C' as Purge, JCCM.JCCo as Company, JCCM.Contract as Contract, '' as Job,  JCCM.Description as Description, '' as Message
		from JCCM JCCM with (nolock)
		where JCCM.JCCo = @jcco and JCCM.Contract = @contract
		union
		Select '  J', JCJM.JCCo, JCJM.Contract, JCJM.Job, JCJM.Description, '' Note
		from JCJM JCJM with (nolock)
		where JCJM.JCCo = @jcco and JCJM.Contract = @contract
	end


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPurgeContractsJobs] TO [public]
GO
