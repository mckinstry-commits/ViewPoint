use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspGetCostBatchPivot_Dyn' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspGetCostBatchPivot_Dyn'
	DROP PROCEDURE mers.mspGetCostBatchPivot_Dyn
end
go

print 'CREATE PROCEDURE mers.mspGetCostBatchPivot_Dyn'
go


CREATE PROCEDURE [mers].[mspGetCostBatchPivot_Dyn]
(
	@JCCo		bCompany 
,	@Job		bJob
,	@Pivot      VARCHAR(5)
)
as
-- ========================================================================
-- Object Name: mers.mspGetCostBatchPivot_Dyn
-- Author:		Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description: Cost Batch Pivot Procedure - Selects all Job Cost Projection Detail from JCPD Batch Table with a > 0 Amount Value for a given Job. 
--              Pivots the resulting data so that the time periods (in weeks begining Mondays) are columns.
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
DECLARE @cols AS NVARCHAR(MAX)
    , @query  AS NVARCHAR(MAX)
	, @dispMonth bMonth
	, @tmpSQL varchar(255)
	, @hrs varchar(3)
	, @StartDate Date
	, @EndDate Date
	, @DayStart INT

DECLARE @DisplayRange TABLE 
	(
	JCCo bCompany 
	, Job bJob
	, datelist Date
	, EndDate Date
	)

SELECT @dispMonth=max(Mth) from JCPB where Co=@JCCo and Job=@Job

IF @dispMonth is not null 
	SELECT @tmpSQL= 'and PD.Mth = ''' + convert(varchar(10), @dispMonth, 120) + ''''
ELSE 
	SELECT @tmpSQL=''	


IF @Pivot = 'WEEK'
	BEGIN
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

		SELECT @EndDate = DateAdd(Day, 6, @StartDate)

		;with cte (JCCo, Job, datelist, maxdate, EndDate) as
		(
			SELECT JCCo, Job, @StartDate AS datelist, max(coalesce(udProjEnd, getdate())) AS maxdate, @EndDate
				FROM JCJM
					WHERE JCCo=@JCCo and Job=@Job
					GROUP BY JCCo, Job
				UNION ALL
			SELECT JCCo, Job, dateadd(WEEK, 1, datelist), maxdate, dateadd(Day,6,(dateadd(Week, 1, datelist)))
				FROM cte
				WHERE datelist <= dateadd(WEEK, -1 ,maxdate) and JCCo=@JCCo and Job=@Job
		) 
		INSERT INTO @DisplayRange (JCCo, Job, datelist, EndDate)
			SELECT c.JCCo, c.Job, c.datelist, c.EndDate
			FROM cte c
	END
ELSE
IF @Pivot = 'MONTH'
	BEGIN
		SELECT @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=1 and Job= @Job 

				SELECT @StartDate = CONCAT(DATEPART(YYYY,@StartDate),'-',DATEPART(MM,@StartDate),'-01')
				SELECT @EndDate = DateAdd(Month, 1, @StartDate)
				SELECT @EndDate = DateAdd(Day, -1, @EndDate)

		;with cte (JCCo, Job, datelist, maxdate, EndDate) as
		(
			SELECT JCCo, Job, @StartDate AS datelist, max(coalesce(udProjEnd, getdate())) AS maxdate, @EndDate
				FROM JCJM
					WHERE JCCo=@JCCo and Job=@Job
					GROUP BY JCCo, Job
				UNION ALL
			SELECT JCCo, Job, dateadd(MONTH, 1, datelist), maxdate, dateadd(Day,-1,(dateadd(MONTH, 2, datelist)))
				FROM cte
				WHERE datelist < dateadd(day,( day(maxdate) * -1 ) + 1 ,maxdate) and JCCo=@JCCo and Job=@Job
		) 
		INSERT INTO @DisplayRange (JCCo, Job, datelist, EndDate)
			SELECT c.JCCo, c.Job, c.datelist, c.EndDate
			FROM cte c
	END

SELECT B.JCCo, B.Job, B.datelist, B.EndDate INTO #tempDates 
	FROM (SELECT JCCo, Job, datelist, EndDate
			FROM  @DisplayRange) as B 

--***Code to handle Null Jobs
--if not exists ( select 1 from JCPR where JCCo=@JCCo and Job=@Job and Mth=@dispMonth)
--begin
--	insert udJCIPD ( Co, Contract, Item, Mth, FromDate, ToDate )
--	select distinct
--		jcci.JCCo, jcci.Contract, jcci.Item, @dispMonth, t.datelist, dateadd(day,-1,dateadd(month,1,t.datelist))
--	from #tempDates t join
--	JCCI jcci on t.JCCo=jcci.JCCo and t.Contract=jcci.Contract

--end

SELECT @cols = STUFF((SELECT distinct ',' + QUOTENAME(convert(CHAR(10), datelist, 120)) 
                    from #tempDates
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

		set @hrs = 'HRS'

set @query = 'SELECT JCCo, Job, Month, PhaseGroup, Phase, CostType, Equipment, Craft, Class, UM, ' + @cols + ' from 
             (
                select d.JCCo AS JCCo, d.Job, ''' + convert(varchar(10), @dispMonth, 120) + ''' as Month, CH.PhaseGroup, CH.Phase, CH.CostType, PD.Equipment, PD.Craft, PD.Class, ''' + @hrs + ''' as UM, PD.Amount,
                    convert(CHAR(10), d.datelist, 120) PivotDate
                FROM #tempDates d 
					INNER JOIN JCCH CH
						ON d.JCCo = CH.JCCo
						AND d.Job = CH.Job 
					LEFT OUTER JOIN JCPD PD  
						ON CH.JCCo = PD.Co
						AND CH.Job = PD.Job
						AND CH.PhaseGroup = PD.PhaseGroup
						AND CH.Phase = PD.Phase
						AND CH.CostType = PD.CostType 
						AND ((PD.ToDate between d.datelist and d.EndDate) 
							OR ((PD.ToDate IS NULL) AND (PD.FromDate IS NULL) AND (PD.DetMth between d.datelist and d.EndDate)))
					' + @tmpSQL + ' 
            ) x
            pivot 
            (
                sum(Amount)
                for PivotDate in (' + @cols + ')
            ) p;'

--set @query = ' select d.JCCo AS JCCo, d.Job, ''' + convert(varchar(10), @dispMonth, 120) + ''' as Month, CH.PhaseGroup, CH.Phase, CH.CostType, PD.Equipment, PD.Craft, PD.Class, PD.UM, PD.Amount,
--                    convert(CHAR(10), d.datelist, 120) PivotDate
--                FROM #tempDates d 
--					INNER JOIN JCCH CH
--						ON d.JCCo = CH.JCCo
--						AND d.Job = CH.Job 
--					INNER JOIN JCPD PD  
--						ON CH.JCCo = PD.Co
--						AND CH.Job = PD.Job
--						AND CH.PhaseGroup = PD.PhaseGroup
--						AND CH.Phase = PD.Phase
--						AND CH.CostType = PD.CostType 
--						AND ((PD.ToDate between d.datelist and d.EndDate) 
--							OR ((PD.ToDate IS NULL) AND (PD.FromDate IS NULL) AND (PD.DetMth between d.datelist and d.EndDate)))
--					' + @tmpSQL + ';'

PRINT @query

EXECUTE(@query)

DROP TABLE #tempDates

GO