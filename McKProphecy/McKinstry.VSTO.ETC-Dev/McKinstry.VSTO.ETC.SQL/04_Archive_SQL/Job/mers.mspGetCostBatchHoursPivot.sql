use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspGetCostBatchHoursPivot' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspGetCostBatchHoursPivot'
	DROP PROCEDURE mers.mspGetCostBatchHoursPivot
end
go

print 'CREATE PROCEDURE mers.mspGetCostBatchHoursPivot'
go

CREATE PROCEDURE mers.mspGetCostBatchHoursPivot
(
	@JCCo		bCompany 
,	@Job		bJob
)
as
-- ========================================================================
-- Object Name: mers.mspGetCostBatchHoursPivot
-- Author:		Ziebell, Jonathan
-- Create date: 6/21/2016
-- Description: Cost Batch Hours Pivot Procedure - Selects all Job Cost Projection Batch Detail from JCPD with a > 0 Hours Value for a given Job. 
--              Pivots the resulting data so that the time periods (in weeks begining Mondays) are columns.
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   5/23/2016  Update to display NULLS for Phases without projections
-- ========================================================================
DECLARE @cols AS NVARCHAR(MAX)
    , @query  AS NVARCHAR(MAX)
	, @dispMonth bMonth
	, @tmpSQL varchar(255)
	, @StartDate Date
	, @EndDate Date
	, @DayStart INT

select @dispMonth=max(Mth) from JCCP where JCCo=@JCCo and Job=@Job

if @dispMonth is not null 
	select @tmpSQL= 'and PD.Mth = ''' + convert(varchar(10), @dispMonth, 120) + ''''
else 
	select @tmpSQL=''	
	
SELECT @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=@JCCo and Job= @Job 

		--Below statements used to set the Week Beginnings to Mondays
		SELECT @DayStart = DATEPART(dw, @StartDate)
		IF @DayStart = 1
			BEGIN
				 SET @StartDate = DATEADD(Day,-6,@StartDate)
			END
		ELSE
			BEGIN
				 SET @StartDate = DATEADD(Day,(2 - @DayStart),@StartDate)
			END

;with cte (JCCo, Job, datelist, maxdate) as
(
    select JCCo, Job, @StartDate AS datelist, max(coalesce(udProjEnd, getdate())) AS maxdate
    from JCJM
	where JCCo=@JCCo and Job=@Job
	group by JCCo, Job
    union all
    select JCCo, Job, dateadd(WEEK, 1, datelist), maxdate
    from cte
    where datelist <= dateadd(WEEK, -1 ,maxdate) and JCCo=@JCCo and Job=@Job
) 
select c.JCCo, c.Job, c.datelist
into #tempDates
from cte c

--***Code to handle Null Jobs
--if not exists ( select 1 from JCPR where JCCo=@JCCo and Job=@Job and Mth=@dispMonth)
--begin
--	insert udJCIPD ( Co, Contract, Item, Mth, FromDate, ToDate )
--	select distinct
--		jcci.JCCo, jcci.Contract, jcci.Item, @dispMonth, t.datelist, dateadd(day,-1,dateadd(month,1,t.datelist))
--	from #tempDates t join
--	JCCI jcci on t.JCCo=jcci.JCCo and t.Contract=jcci.Contract

--end

select @cols = STUFF((SELECT distinct ',' + QUOTENAME(convert(CHAR(10), datelist, 120)) 
                    from #tempDates
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

set @query = 'SELECT JCCo, Job, Month, PhaseGroup, Phase, CostType, Equipment, Craft, Class, UM, ' + @cols + ' from 
             (
                select d.JCCo AS JCCo, d.Job, ''' + convert(varchar(10), @dispMonth, 120) + ''' as Month, CH.PhaseGroup, CH.Phase, CH.CostType, PD.Equipment, PD.Craft, PD.Class, PD.UM, PD.Hours,
                    convert(CHAR(10), d.datelist, 120) PivotDate
                FROM #tempDates d 
					INNER JOIN JCCH CH
						ON d.JCCo = CH.JCCo
						AND d.Job = CH.Job 
						AND d.Job = CH.Job  
					LEFT OUTER JOIN JCPD PD  
						ON CH.JCCo = PD.Co
						AND CH.Job = PD.Job
						AND CH.PhaseGroup = PD.PhaseGroup
						AND CH.Phase = PD.Phase
						AND CH.CostType = PD.CostType 
						AND d.datelist between PD.FromDate and PD.ToDate
					' + @tmpSQL + ' 
            ) x
            pivot 
            (
                sum(Hours)
                for PivotDate in (' + @cols + ')
            ) p;'

print @query

execute(@query)

drop table #tempDates

go

