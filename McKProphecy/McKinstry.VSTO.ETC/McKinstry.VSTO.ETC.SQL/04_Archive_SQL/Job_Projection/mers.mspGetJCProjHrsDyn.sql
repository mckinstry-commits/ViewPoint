use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspGetJCProjHrsDyn' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspGetJCProjHrsDyn'
	DROP PROCEDURE mers.mspGetJCProjHrsDyn
end
go

print 'CREATE PROCEDURE mers.mspGetJCProjHrsDyn'
go

CREATE PROCEDURE [mers].[mspGetJCProjHrsDyn]
(
	@JCCo		bCompany 
,	@Job		bJob
,	@Pivot      VARCHAR(5)
)
as
-- ========================================================================
-- Object Name: mers.mspGetJCProjHrsDyn
-- Author:		Ziebell, Jonathan
-- Create date: 6/30/2016
-- Description: Cost Batch Hours Pivot Procedure - Selects all Job Cost Projection Batch Detail from JCPD with a > 0 Hours Value for a given Job. 
--              Pivots the resulting data so that the time periods (in weeks begining Mondays) are columns.
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   5/23/2016  Update to display NULLS for Phases without projections
--              J.Ziebell   7/5/2016   Parent Phase Desc
--              J.Ziebell   7/11/2016  Parent Phase Mapping 
--              J.Ziebell   7/12/2016  Week Heading should be Week Ending Date
--              J.Ziebell	7/14/2016  Drop Early Months before Date Build
--              J.Ziebell   8/1/2016   Dynamic Period selection
--              J.Ziebell   8/3/2016   Display 1 Month for Past Closed Jobs
--              J.Ziebell   8/8/2016   Default Rate to Budget, Display Remaining Budget and Cost
-- ========================================================================
DECLARE @cols AS NVARCHAR(MAX)
    , @query  AS NVARCHAR(MAX)
	, @dispMonth bMonth
	, @tmpSQL varchar(255)
	, @StartDate Date
	, @EndDate Date
	, @DayStart INT
	, @Phase VARCHAR(20)
	, @CalcCol VARCHAR(6)
	, @ParentPhase VARCHAR(10)
	, @TextJCCo VARCHAR(5)
	, @CutOffDate Date

DECLARE @DisplayRange TABLE 
	(
	JCCo bCompany 
	, Job bJob
	, datelist Date
	, EndDate Date
	)

SELECT @dispMonth=max(Mth), @CutOffDate=MAX(ActualDate) from JCPB where Co=@JCCo and Job=@Job

if @dispMonth is not null 
	select @tmpSQL= 'and PB.Mth = ''' + convert(varchar(10), @dispMonth, 120) + ''''
else 
	select @tmpSQL=''

SELECT @CutOffDate = SYSDATETIME();

--print @dispMonth
	
IF @Pivot = 'WK'
	BEGIN
		SELECT @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=@JCCo and Job= @Job 
		---- @StartDate
		--print @EndDate

		If @StartDate < @CutOffDate
			BEGIN
				SET @StartDate = DateAdd(DAY,-8, @CutOffDate)
			END

		If @EndDate < @CutOffDate
			BEGIN
				SET @EndDate = @CutOffDate
			END

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
IF @Pivot = 'MTH'
	BEGIN
		SELECT @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=@JCCo and Job= @Job 

		If @StartDate < @CutOffDate
			BEGIN
				SET @StartDate = DateAdd(DAY,-1, @CutOffDate)
			END

		If @EndDate < @CutOffDate
			BEGIN
				SET @EndDate = @CutOffDate
			END

				SELECT @StartDate = CONCAT(DATEPART(YYYY,@StartDate),'-',DATEPART(MM,@StartDate),'-01')
				If @EndDate < @CutOffDate
					BEGIN
						SET @EndDate = @CutOffDate
					END
				ELSE
					BEGIN
						SELECT @EndDate = DateAdd(Month, 1, @StartDate)
						SELECT @EndDate = DateAdd(Day, -1, @EndDate)
					END
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
			FROM  @DisplayRange
			WHERE EndDate >= @CutOffDate) as B 

SELECT @cols = STUFF((SELECT distinct ',' + QUOTENAME(convert(CHAR(10), EndDate, 120)) 
                    from #tempDates
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

--print @cols

--		set @Phase = '9300-0000-      -   '
	Set @CalcCol = 'CALCME'
	Set @ParentPhase = 'NO PARENT'
	Set @TextJCCo = Convert(VARCHAR,@JCCo)


--set @query = 'SELECT ISNULL(PM2.Description, ''' + @ParentPhase + ''') AS ParentPhase, PB.Phase, REPLACE(JP.Description,''"'',''-'') AS PhaseDesc
--				, PD.Employee, PD.Description, ''' + @CalcCol + ''' AS ProjRemHours, ''' + @CalcCol + ''' AS StartRemHours
--				, ''' + @CalcCol + ''' AS Variance, ''' + @CalcCol + ''' AS PhaseActualRt
--				, CASE WHEN (PD.Rate IS NOT NULL) THEN PD.Rate
--					   WHEN (PB.CurrEstHours IS NULL) THEN 0
--				       WHEN (PB.CurrEstHours <= 0) THEN 0 
--				  ELSE (PB.CurrEstCost/PB.CurrEstHours)	END AS Rate
--				, ''' + @CalcCol + ''' AS RemCost
--				, ISNULL(PD.Hours,0) AS Hours, convert(CHAR(10), d.EndDate, 120) PivotDate
--				FROM HQCO HQ
--					INNER JOIN JCPB PB 
--						ON HQ.HQCo = PB.Co
--						AND PB.CostType = 1
--						AND PB.Phase IN (''0131-1530-      -   '',''0131-1505-      -   '',''0131-1040-      -   '')
--					INNER JOIN JCJP JP
--						ON	PB.Co = JP.JCCo
--						AND PB.Job = JP.Job 
--						AND PB.PhaseGroup = JP.PhaseGroup
--						AND PB.Phase = JP.Phase
--						AND JP.Job = ''' + @Job + '''
--						AND JP.JCCo = ''' + @TextJCCo + '''
--					LEFT OUTER JOIN (JCPM PM
--										INNER JOIN JCPM PM2
--											ON PM.PhaseGroup = PM2.PhaseGroup
--											AND PM.udParentPhase = PM2.Phase)
--						ON PB.PhaseGroup = PM.PhaseGroup
--						AND SUBSTRING(PB.Phase,1,10) = SUBSTRING(PM.Phase,1,10)
--					LEFT OUTER JOIN (#tempDates d 
--										INNER JOIN JCPD PD 
--											ON d.JCCo = PD.Co
--											AND d.Job = PD.Job
--											AND PD.TransType<>''D''
--										    AND ((PD.ToDate between d.datelist and d.EndDate) 
--												OR ((PD.ToDate IS NULL) 
--													AND (PD.DetMth between d.datelist and d.EndDate))))
--						ON d.JCCo = PB.Co
--						AND d.Job = PB.Job 
--					    AND PD.PhaseGroup = PB.PhaseGroup
--						AND PD.Phase = PB.Phase
--						AND PD.CostType = PB.CostType;'


set @query = 'SELECT ''' + @CalcCol + ''' AS UsedFilter, ParentPhase, Phase, PhaseDesc, Employee, Description, ProjRemHours, RemCost
				, ''' + @CalcCol + ''' AS ''Budgeted Hours'', ''' + @CalcCol + ''' AS ''Budgeted Cost'', StartRemHours, Variance
				, PhaseActualRt, Rate,' + @cols + ' from 
             (SELECT ISNULL(PM2.Description, ''' + @ParentPhase + ''') AS ParentPhase, PB.Phase, REPLACE(JP.Description,''"'',''-'') AS PhaseDesc
				, PD.Employee, PD.Description, ''' + @CalcCol + ''' AS ProjRemHours, ''' + @CalcCol + ''' AS StartRemHours
				, ''' + @CalcCol + ''' AS Variance, ''' + @CalcCol + ''' AS PhaseActualRt
				, CASE WHEN (PD.Rate IS NOT NULL) THEN PD.Rate
					   WHEN (PB.CurrEstHours IS NULL) THEN 0
				       WHEN (PB.CurrEstHours <= 0) THEN 0 
				  ELSE (PB.CurrEstCost/PB.CurrEstHours)	END AS Rate
				, ''' + @CalcCol + ''' AS RemCost
				, ISNULL(PD.Hours,0) AS Hours, convert(CHAR(10), d.EndDate, 120) PivotDate
				FROM HQCO HQ
					INNER JOIN JCPB PB 
						ON HQ.HQCo = PB.Co
						AND PB.Job = ''' + @Job + '''
						AND PB.Co = ''' + @TextJCCo + '''
						' + @tmpSQL + '
						AND PB.CostType = 1
					INNER JOIN JCJP JP
						ON	PB.Co = JP.JCCo
						AND PB.Job = JP.Job 
						AND PB.PhaseGroup = JP.PhaseGroup
						AND PB.Phase = JP.Phase
					LEFT OUTER JOIN (JCPM PM
										INNER JOIN JCPM PM2
											ON PM.PhaseGroup = PM2.PhaseGroup
											AND PM.udParentPhase = PM2.Phase)
						ON PB.PhaseGroup = PM.PhaseGroup
						AND SUBSTRING(PB.Phase,1,10) = SUBSTRING(PM.Phase,1,10)
					LEFT OUTER JOIN (#tempDates d 
										INNER JOIN JCPD PD 
											ON d.JCCo = PD.Co
											AND d.Job = PD.Job
											AND PD.TransType<>''D''
										    AND ((PD.ToDate between d.datelist and d.EndDate) 
												OR ((PD.ToDate IS NULL) 
													AND (PD.DetMth between d.datelist and d.EndDate))))
						ON d.JCCo = PB.Co
						AND d.Job = PB.Job 
					    AND PD.PhaseGroup = PB.PhaseGroup
						AND PD.Phase = PB.Phase
						AND PD.CostType = PB.CostType
            ) x
            pivot 
            (
                sum(Hours)
                for PivotDate in (' + @cols + ')
            ) p ORDER BY Phase;'

--print @query

execute(@query)

drop table #tempDates