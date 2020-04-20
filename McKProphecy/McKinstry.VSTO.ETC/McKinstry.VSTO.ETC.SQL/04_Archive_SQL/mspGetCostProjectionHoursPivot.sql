﻿use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspGetCostProjectionHoursPivot' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspGetCostProjectionHoursPivot'
	DROP PROCEDURE mers.mspGetCostProjectionHoursPivot
end
go

print 'CREATE PROCEDURE mers.mspGetCostProjectionHoursPivot'
go

CREATE PROCEDURE mers.mspGetCostProjectionHoursPivot
(
	@JCCo		bCompany 
,	@Job		bJob
)
as
-- ========================================================================
-- Cost Projection Hours Pivot Procedure
-- Author:		Ziebell, Jonathan
-- Create date: 05/17/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX),
	@dispMonth bMonth,
	@tmpSQL varchar(255)
	, @StartDate Date
	, @EndDate Date
	, @DayStart INT
	--, @DayEnd INT

select @dispMonth=max(Mth) from JCCP where JCCo=@JCCo and Job=@Job

if @dispMonth is not null 
	select @tmpSQL= 'and PR.Mth = ''' + convert(varchar(10), @dispMonth, 120) + ''''
else 
	select @tmpSQL=''	

--print @tmpSQL

SELECT @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=1 and Job= @Job --' 10187-002'

		SELECT @DayStart = DATEPART(dw, @StartDate)
		IF @DayStart = 1
			BEGIN
				 SET @StartDate = DATEADD(Day,-6,@StartDate)
			END
		ELSE
			BEGIN
				 SET @StartDate = DATEADD(Day,(2 - @DayStart),@StartDate)
			END
		--SELECT @DayEnd  = DATEPART(dw, @EndDate)

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
                select PR.JCCo, PR.Job, PR.Mth as Month, PR.PhaseGroup, PR.Phase, PR.CostType, PR.Equipment, PR.Craft, PR.Class, PR.UM, PR.Hours,
                    convert(CHAR(10), d.datelist, 120) PivotDate
                FROM #tempDates d 
					JOIN JCPR PR  
						ON d.JCCo = PR.JCCo
						AND d.Job = PR.Job
						AND d.datelist between PR.FromDate and PR.ToDate
						AND PR.Hours > 0
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

declare @JCCo bCompany
declare @Job bJob
declare @Month bMonth

select
	@JCCo=1
,	@Job=' 10187-002'

--select max(Mth) from JCIP where JCCo=@JCCo and Contract=@Contract

exec mers.mspGetCostProjectionHoursPivot @JCCo=@JCCo, @Job=@Job
--select * from udJCIPD where Co=@JCCo and Contract=@Contract

select @Job=' 14345-'
exec mers.mspGetCostProjectionHoursPivot @JCCo=@JCCo, @Job=@Job
go


