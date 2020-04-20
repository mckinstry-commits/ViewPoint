SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************/
CREATE function [dbo].[vfJCMthRevForecastAmt] 
	(@jcco tinyint = null, @contract varchar(10) = null, @forecastmonth bMonth = null, @revenuepct bPct = null)
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
* This function is used to return the the current revenue amount month forecast. Uses
* current numbers from JCIP and JCForecastMonth less prior Month amount if a prior month
* exists.
* Used in JCForecastTotalsRev view that is
* used in JC and PM Contract Forecast Month grids.
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

declare @mthrevenueamt numeric(20,2), @currmthrevenue numeric(20,2), @priormthrevenue numeric(20,2),
		@priorrevpct bPct, @priormonth bMonth

set @mthrevenueamt = 0

if @jcco is null or @contract is null or @forecastmonth is null goto bspexit

---- get current month forecast revenue amount
select @currmthrevenue = isnull(sum(p.ContractAmt),0) * isnull(@revenuepct,0)
from dbo.bJCIP p with (nolock)
where p.JCCo=@jcco and p.Contract=@contract and p.Mth <= @forecastmonth

---- define prior month
set @priormonth = dateadd(month,-1,@forecastmonth)

---- check if we have a prior forecast month and get revenue percentage
select @priorrevpct=isnull(f.RevenuePct,0)
from dbo.vJCForecastMonth f with (nolock)
where f.JCCo=@jcco and f.Contract=@contract and f.ForecastMonth = @priormonth
if @@rowcount = 0
	begin
	set @mthrevenueamt = isnull(@currmthrevenue,0)
	goto bspexit
	end
	
---- get prior month forecast revenue amount
select @priormthrevenue = isnull(sum(p.ContractAmt),0) * isnull(@priorrevpct,0)
from dbo.bJCIP p with (nolock)
where p.JCCo=@jcco and p.Contract=@contract and p.Mth <= @priormonth

---- calculate current month revenue amount forecast
set @mthrevenueamt = isnull(@currmthrevenue,0) - isnull(@priormthrevenue,0)





bspexit:
	return (isnull(@mthrevenueamt,0))
	end


GO
GRANT EXECUTE ON  [dbo].[vfJCMthRevForecastAmt] TO [public]
GO
