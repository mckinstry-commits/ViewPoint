use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspGetCostProjectionPivot' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspGetCostProjectionPivot'
	DROP PROCEDURE mers.mspGetCostProjectionPivot
end
go

print 'CREATE PROCEDURE mers.mspGetCostProjectionPivot'
go

CREATE PROCEDURE [mers].[mspGetCostProjectionPivot_Dyn]
(
	@JCCo		bCompany 
,	@Job		bJob
,   @Pivot      VARCHAR(5)
)
as
-- ========================================================================
-- Cost Projection Pivot Procedure
-- Author:		Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	Cost Projection Pivot Procedure - Selects all Job Cost Projection Detail with for a given Job. 
--              Pivots the resulting data so that the time periods (in weeks begining Mondays) are columns.
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   5/23/2016  Update to display NULLS for Phases without projections
--				J.Ziebell   5/31/2016  Update to allow for dynamic spread period and to properly display data from variable periods
--              J.Ziebell   6/17/2016  Update to allow for no pre-existing detailed batch
-- ========================================================================
DECLARE @cols AS NVARCHAR(MAX)
	,	@query  AS NVARCHAR(MAX)
	,	@dispMonth bMonth
	,	@tmpSQL varchar(255)
	,	@StartDate Date
	,	@EndDate Date
	,	@DayStart INT

DECLARE @DisplayRange TABLE 
	(
	JCCo bCompany 
	, Job bJob
	, datelist Date
	, EndDate Date
	)

select @dispMonth=max(Mth) from JCPR where JCCo=@JCCo and Job=@Job

if @dispMonth is not null 
	select @tmpSQL= 'and PR.Mth = ''' + convert(varchar(10), @dispMonth, 120) + ''''
else 
	BEGIN
		select @tmpSQL=' ' --'and PR.Mth = PR.Mth'	
		select @dispMonth = udProjStart from JCJM where JCCo=1 and Job= @Job
	END
--print @tmpSQL

IF @Pivot = 'WEEK'
	BEGIN
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

	SELECT @EndDate = DateAdd(Day, 6, @StartDate)
		;with cte (JCCo, Job, datelist, maxdate, EndDate) as
		(
			select JCCo, Job, @StartDate AS datelist, max(coalesce(udProjEnd, getdate())) AS maxdate, @EndDate
			from JCJM
			where JCCo=@JCCo and Job=@Job
			group by JCCo, Job
			union all
			select JCCo, Job, dateadd(WEEK, 1, datelist), maxdate, dateadd(Day,6,(dateadd(Week, 1, datelist)))
			from cte
			where datelist <= dateadd(WEEK, -1 ,maxdate) and JCCo=@JCCo and Job=@Job
		) 
		INSERT INTO @DisplayRange (JCCo, Job, datelist, EndDate)
			SELECT c.JCCo, c.Job, c.datelist, c.EndDate
			FROM cte c
	END
ELSE
IF @Pivot = 'MONTH'
	BEGIN
		SELECT @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=1 and Job= @Job --' 10187-002'

				SELECT @StartDate = CONCAT(DATEPART(YYYY,@StartDate),'-',DATEPART(MM,@StartDate),'-01')
				SELECT @EndDate = DateAdd(Month, 1, @StartDate)
				SELECT @EndDate = DateAdd(Day, -1, @EndDate)

		;with cte (JCCo, Job, datelist, maxdate, enddate) as
		(
			select JCCo, Job, @StartDate AS datelist, max(coalesce(udProjEnd, getdate())) AS maxdate, @EndDate
			from JCJM
			where JCCo=@JCCo and Job=@Job
			group by JCCo, Job
			union all
			select JCCo, Job, dateadd(MONTH, 1, datelist), maxdate, dateadd(Day,-1,(dateadd(MONTH, 2, datelist)))
			from cte
			where datelist < dateadd(day,( day(maxdate) * -1 ) + 1 ,maxdate) and JCCo=@JCCo and Job=@Job
		) 
		INSERT INTO @DisplayRange (JCCo, Job, datelist, EndDate)
			SELECT c.JCCo, c.Job, c.datelist, c.enddate
			FROM cte c
	END

		select B.JCCo, B.Job, B.datelist, B.EndDate into #tempDates FROM 
		(Select JCCo, Job, datelist, EndDate
			from  @DisplayRange) as B 


select @cols = STUFF((SELECT distinct ',' + QUOTENAME(convert(CHAR(10), datelist, 120)) 
                    from #tempDates --@DisplayRange --
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

set @query = 'SELECT JCCo, Job, Month, PhaseGroup, Phase, CostType, Equipment, Craft, Class, UM, ' + @cols + ' from 
             (
                select d.JCCo, d.Job, ''' + convert(varchar(10), @dispMonth, 120) + ''' as Month, CH.PhaseGroup, CH.Phase, CH.CostType, PR.Equipment, PR.Craft, PR.Class, PR.UM, PR.Amount,
                    convert(CHAR(10), d.datelist, 120) PivotDate
                FROM #tempDates d 
					INNER JOIN JCCH CH
						ON d.JCCo = CH.JCCo
						AND d.Job = CH.Job  
					LEFT OUTER JOIN JCPR PR  
						ON CH.JCCo = PR.JCCo
						AND CH.Job = PR.Job
						AND CH.PhaseGroup = PR.PhaseGroup
						AND CH.Phase = PR.Phase
						AND CH.CostType = PR.CostType
						AND ((PR.ToDate between d.datelist and d.EndDate) OR ((PR.ToDate IS NULL) AND (PR.FromDate IS NULL) AND (PR.DetMth between d.datelist and d.EndDate)))
					' + @tmpSQL + ' 
            ) x
            pivot 
            (
                sum(Amount)
                for PivotDate in (' + @cols + ')
            ) p;'

--print @query

execute(@query)

drop table #tempDates