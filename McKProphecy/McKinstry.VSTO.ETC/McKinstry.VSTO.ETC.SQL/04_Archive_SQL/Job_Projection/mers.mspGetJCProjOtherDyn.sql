use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspGetJCProjOtherDyn' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspGetJCProjOtherDyn'
	DROP PROCEDURE mers.mspGetJCProjOtherDyn
end
go

print 'CREATE PROCEDURE mers.mspGetJCProjOtherDyn'
go

CREATE PROCEDURE [mers].[mspGetJCProjOtherDyn]
(
	@JCCo		bCompany 
,	@Job		bJob
,	@Pivot      VARCHAR(5)
)
as
-- ========================================================================
-- Object Name: mers.mspGetJCProjOtherDyn
-- Author:		Ziebell, Jonathan
-- Create date: 07/01/2016
-- Description: Cost Batch Pivot Procedure - Selects all Job Cost Projection Detail from JCPD Batch Table with a > 0 Amount Value for a given Job. 
--              Pivots the resulting data so that the time periods (in weeks ending Sundays) are columns.
-- Update Hist: USER--------DATE-------DESC-----------
--              J.Ziebell   7/5/2016   Parent Phase Desc
--              J.Ziebell   7/8/2016   Add Filter Field
--              J.Ziebell   7/11/2016  Parent Phase Grouping
--              J.Ziebell   7/12/2016  Week Heading should be Week Ending Date
--              J.Ziebell   7/15/2016  Change Cost Type to Abbreviation
--              J.Ziebell   8/3/2016   Display 1 Month for Past Closed Jobs
--              J.Ziebell   8/8/2016   Display Remaining Budget and Cost
-- ========================================================================
DECLARE @cols AS NVARCHAR(MAX)
    , @query  AS NVARCHAR(MAX)
	, @dispMonth bMonth
	, @tmpSQL varchar(255)
	, @StartDate Date
	, @EndDate Date
	, @DayStart INT
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
	BEGIN
		select @tmpSQL= 'and PB.Mth = ''' + convert(varchar(10), @dispMonth, 120) + ''''
		SELECT @CutOffDate = SYSDATETIME();
	END
else 
	BEGIN
		select @tmpSQL=''
		SELECT @CutOffDate = SYSDATETIME();
	END

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
		SELECT @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=@JCCo and Job= @Job

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

    Set @CalcCol = 'CALCME'
	Set @ParentPhase = 'NO PARENT'
	Set @TextJCCo = Convert(VARCHAR,@JCCo)

	--Set @FilterY = 'Y'
	--Set @FilterN = 'N'
--CASE WHEN (PD.Amount IS NULL) THEN ''' + @FilterN + '''
	--						WHEN (PD.Amount <> 0) THEN ''' + @FilterY + '''

set @query = 'SELECT ''' + @CalcCol + ''' AS UsedFilter, ParentPhase, Phase, PhaseDesc, CostType AS ''Cost Type'', Description
				, BudgetRemCost AS ''Budgeted Remaining Cost'', BudgetRemCost AS ''Starting Projected Cost'', Variance
				, BudgetRemCost AS ''PHASE Open Committed'', ProjRemCost AS ''Remaining Cost'', ' + @cols + ' from 
             (SELECT ISNULL(PM2.Description, ''' + @ParentPhase + ''') AS ParentPhase, PB.Phase, REPLACE(JP.Description,''"'',''-'') AS PhaseDesc
				, CT.Abbreviation as CostType, PD.Description, ''' + @CalcCol + ''' AS BudgetRemCost, ''' + @CalcCol + ''' AS Variance
				, ''' + @CalcCol + ''' AS ProjRemCost, ISNULL(PD.Amount,0) AS Amount, convert(CHAR(10), d.EndDate, 120) PivotDate
                FROM HQCO HQ
					INNER JOIN JCPB PB
						ON HQ.HQCo = PB.Co
						AND PB.Job = ''' + @Job + '''
						AND PB.Co = ''' + @TextJCCo + '''
						AND PB.CostType <> 1
						' + @tmpSQL + '
					INNER JOIN JCJP JP
						ON	PB.Co = JP.JCCo
						AND PB.Job = JP.Job 
						AND PB.PhaseGroup = JP.PhaseGroup
						AND PB.Phase = JP.Phase
					INNER JOIN JCCT CT
						ON PB.PhaseGroup = CT.PhaseGroup
						AND PB.CostType = CT.CostType
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
											AND PD.CostType <> 1
											AND PD.TransType<>''D''
										    AND ((PD.ToDate between d.datelist and d.EndDate) 
												OR ((PD.ToDate IS NULL) 
													AND (PD.DetMth between d.datelist and d.EndDate))))
						ON d.JCCo = PB.Co
						AND d.Job = PB.Job
						AND PB.PhaseGroup = PD.PhaseGroup
						AND PB.Phase = PD.Phase
						AND PB.BatchId = PD.BatchId
						AND PB.BatchSeq = PD.BatchSeq
						AND PB.CostType = PD.CostType
            ) x
            pivot 
            (
                sum(Amount)
                for PivotDate in (' + @cols + ')
            ) p ORDER BY Phase, CostType ;'

--PRINT @query

EXECUTE(@query)

DROP TABLE #tempDates






--set @query = 'SELECT ''' + @CalcCol + ''' AS UsedFilter, ParentPhase, Phase, PhaseDesc, CostType AS ''Cost Type'', Description, BudgetRemCost, Variance, ProjRemCost, ' + @cols + ' from 
--             (SELECT ISNULL(PM2.Description, ''' + @ParentPhase + ''') AS ParentPhase, CH.Phase, REPLACE(JP.Description,''"'',''-'') AS PhaseDesc
--				, CT.Abbreviation as CostType, PD.Description, ''' + @CalcCol + ''' AS BudgetRemCost, ''' + @CalcCol + ''' AS Variance
--				, ''' + @CalcCol + ''' AS ProjRemCost, ISNULL(PD.Amount,0) AS Amount, convert(CHAR(10), d.EndDate, 120) PivotDate
--                FROM JCCH CH
--					INNER JOIN JCJP JP
--						ON	CH.JCCo = JP.JCCo
--						AND CH.Job = JP.Job 
--						AND CH.PhaseGroup = JP.PhaseGroup
--						AND CH.Phase = JP.Phase
--						AND JP.Job = ''' + @Job + '''
--						AND JP.JCCo = ''' + @TextJCCo + '''
--						AND CH.CostType <> 1
--					INNER JOIN JCCT CT
--						ON CH.PhaseGroup = CT.PhaseGroup
--						AND CH.CostType = CT.CostType
--					LEFT OUTER JOIN (JCPM PM
--										INNER JOIN JCPM PM2
--											ON PM.PhaseGroup = PM2.PhaseGroup
--											AND PM.udParentPhase = PM2.Phase)
--						ON CH.PhaseGroup = PM.PhaseGroup
--						AND SUBSTRING(CH.Phase,1,10) = SUBSTRING(PM.Phase,1,10)
--					LEFT OUTER JOIN (#tempDates d 
--										INNER JOIN JCPD PD 
--											ON d.JCCo = PD.Co
--											AND d.Job = PD.Job
--											AND PD.TransType <>''D''
--										INNER JOIN JCPB PB 
--											ON PD.Co = PB.Co
--											AND PD.Job = PB.Job
--											AND PD.PhaseGroup = PB.PhaseGroup
--											AND PD.Phase = PB.Phase
--											AND PD.BatchId = PB.BatchId
--											AND PD.BatchSeq = PB.BatchSeq
--											AND PD.CostType = PB.CostType
--											AND PB.CostType <> 1)
--						ON CH.CostType = PD.CostType
--						AND CH.JCCo = PD.Co
--						AND CH.Job = PD.Job
--						AND CH.PhaseGroup = PD.PhaseGroup
--						AND CH.Phase = PD.Phase
--						AND ((PD.ToDate between d.datelist and d.EndDate) 
--							OR ((PD.ToDate IS NULL) AND (PD.FromDate IS NULL) AND (PD.DetMth between d.datelist and d.EndDate)))
--					' + @tmpSQL + ' 

