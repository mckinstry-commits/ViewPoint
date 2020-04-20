SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************/
CREATE function [dbo].[vfPMPendingCosts] 
	(@jcco tinyint = null, @contract varchar(10) = null, @forecastmonth bMonth = null)
returns numeric(20,2)
as
begin

/***********************************************************
* CREATED BY:	GF 09/15/2009 - issue #129897
* MODIFIED By:
*
*
*
* USAGE:
* This function is used to return the original cost from Cost Header
* for pending contracts only for a forecast month. Used in JCForecastTotalsCost view
* that is used in JC and PM Contract Forecast Month grids.
*
*
* INPUT PARAMETERS
* @jcco				JC Company
* @contract			JC Contract
* @forecastmonth	JC Contract Forecast month
*
*
* OUTPUT PARAMETERS
* Original Cost from JCCH
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/

declare @origcost numeric(20,2)

set @origcost = 0

if @jcco is null or @contract is null or @forecastmonth is null goto bspexit

---- get Pending Cost from JCCH for Pending Contracts
select @origcost = isnull(sum(h.OrigCost),0)
from bJCCH h with (nolock)
left join bJCJM j with (nolock) on j.JCCo=h.JCCo and j.Job=h.Job
left join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.Phase=h.Phase
left join bJCCI i with (nolock) on i.JCCo=p.JCCo and i.Contract=p.Contract and i.Item=p.Item
where h.JCCo = @jcco and j.JobStatus = 0 and p.Contract = @contract
and i.StartMonth <= @forecastmonth




bspexit:
	return (isnull(@origcost,0))
	end

GO
GRANT EXECUTE ON  [dbo].[vfPMPendingCosts] TO [public]
GO
