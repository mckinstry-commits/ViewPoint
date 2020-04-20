SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspJCForecastMthValForJCCM]
/*************************************
 * Created By:	GF 09/03/2009 - issue #129897
 * Modified By:	
 *
 *
 *
 * Returns Contract information for display in the contract master forecast grid.
 *
 * Pass:
 * @jcco		JC Company
 * @contract	JC Contract
 * @mth			JC Contract Forecast Month
 *
 * Success returns:
 * @CurrContract		JC Contract Current thru forecast month
 * @CurrEstimate		JC Contract Current Estimate thru forecast month
 * @BillToDate			JC Contract Billed to date thru forecast month
 * @ActualToDate		JC Contract Actual to Date thru forecast month
 * @IncludedCOAmount	JC Contract Included CO Amounts from PM
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@jcco bCompany = null, @contract bContract = null, @mth bMonth = null,
 @CurrContract bDollar = 0 output, @CurrEstimate bDollar = 0 output,
 @BillToDate bDollar = 0 output, @ActualToDate bDollar = 0 output,
 @IncludedCOAmount bDollar = 0 output, @msg varchar(255) output)
as 
set nocount on

declare @rcode int, @validatestatus bYN

select @rcode = 0, @CurrContract = 0, @CurrEstimate = 0, @BillToDate = 0,
	   @ActualToDate = 0, @IncludedCOAmount = 0

---- validate JC Company
if not exists(select top 1 1 from dbo.JCCO with (nolock) where JCCo=@jcco)
	begin
	select @msg = 'Invalid JC Company.', @rcode = 1
	goto bspexit
	end

---- validate contract
if not exists(select top 1 1 from dbo.JCCM with (nolock) where JCCo=@jcco and Contract=@contract)
	begin
	select @msg = 'Invalid JC Contract.', @rcode = 1
	goto bspexit
	end

if @mth is null
	begin
	select @msg = 'Missing Forecast Month.', @rcode = 1
	goto bspexit
	end


---------------------------
-- Get Totals for Labels --
---------------------------
select @CurrContract = isnull(sum(ContractAmt),0), @BillToDate = isnull(sum(BilledAmt),0)
from dbo.bJCIP with (nolock) 
where JCCo=@jcco and Contract=@contract and Mth<=@mth

select @ActualToDate = isnull(sum(p.ActualCost),0)
from dbo.bJCCP p with (nolock)
join dbo.bJCJM j with (nolock) on j.JCCo=p.JCCo and j.Job=p.Job
join dbo.bJCCM c with (nolock) on c.JCCo=j.JCCo and c.Contract=j.Contract
where p.JCCo=@jcco and c.Contract=@contract and p.Job=j.Job and p.Mth<=@mth

select @CurrEstimate = dbo.vfPMPendingCosts(@jcco,@contract,@mth) + isnull(sum(p.CurrEstCost),0)
from dbo.bJCCP p with (nolock)
join dbo.bJCJM j with (nolock) on j.JCCo=p.JCCo and j.Job=p.Job
join dbo.bJCCM c with (nolock) on c.JCCo=j.JCCo and c.Contract=j.Contract
where p.JCCo=@jcco and c.Contract=@contract and p.Job=j.Job and p.Mth<=@mth
and j.JobStatus <> 0

select @IncludedCOAmount = isnull(sum(ol.EstCost),0)
from dbo.bPMOL ol with (nolock)
join dbo.bPMOI oi with (nolock) on ol.PMCo=oi.PMCo and ol.Project=oi.Project
	and isnull(ol.PCOType,'')=isnull(oi.PCOType,'')
	and isnull(ol.PCO,'')=isnull(oi.PCO,'') and isnull(ol.PCOItem,'')=isnull(oi.PCOItem,'')
	and isnull(ol.ACO,'')=isnull(oi.ACO,'') and isnull(ol.ACOItem,'')=isnull(oi.ACOItem,'')
join dbo.bPMSC sc with (nolock) on sc.Status = oi.Status
left join dbo.bPMDT dt with (nolock) on dt.DocType = oi.PCOType
join dbo.bJCJM jm with (nolock) on jm.JCCo=oi.PMCo and jm.Job=ol.Project
join dbo.bJCCM cm with (nolock) on cm.JCCo=jm.JCCo and cm.Contract=jm.Contract
where oi.PMCo = @jcco and oi.Project = jm.Job and cm.Contract=@contract
	and ol.InterfacedDate is null
	and isnull(dt.IncludeInProj,'N') = 'Y' 
	and isnull(sc.IncludeInProj,'N') = 'C'

if @CurrContract is null set @CurrContract = 0
if @BillToDate is null set @BillToDate = 0
if @IncludedCOAmount is null set @IncludedCOAmount = 0
if @CurrEstimate is null set @CurrEstimate = 0
if @ActualToDate is null set @ActualToDate = 0



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCForecastMthValForJCCM] TO [public]
GO
