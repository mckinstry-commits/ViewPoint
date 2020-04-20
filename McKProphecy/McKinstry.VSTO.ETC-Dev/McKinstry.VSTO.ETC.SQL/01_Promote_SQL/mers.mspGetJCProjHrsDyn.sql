use Viewpoint
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
--				J.Ziebell   8/18/2016  Updated Column Headers AND Week Cutoff
--				J.Ziebell   8/25/2016  Better End Date on Cutoff
--				J.Ziebell   8/30/2016  Previous Remaining Cost Label
--				J.Ziebell   8/31/2016  MTD Actuals
--				J.Ziebell   9/14/2016  Cut off Past Months
--              J.Ziebell   9/22/2016  Change to Orig Budget Rate from Curr Estimate
--              J.Ziebell   10/06/2016 Cut off month/week display at 60/99.
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
	, @MaxDate Date
	, @Flat_Phase VARCHAR(20)
	, @Flat_Date Date

DECLARE @DisplayRange TABLE 
	(
	JCCo bCompany 
	, Job bJob
	, datelist Date
	, EndDate Date
	)

DECLARE	@JCCP_MTD TABLE
				( JCCo bCompany
				, Job bJob
				, PhaseGroup bGroup
				, Phase bPhase
				, Description bItemDesc
				, MTDCost NUMERIC(11,2)
				, MTDHours NUMERIC(11,2)
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

SELECT @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=@JCCo and Job= @Job 
--print @dispMonth
	
IF @Pivot = 'WK'
	BEGIN
		---- @StartDate
		--print @EndDate
		--MTD Change
		--SET @CutOffDate = DateAdd(DAY,-3,@CutOffDate)

		SET @CutOffDate = CONCAT(DATEPART(YYYY,@CutOffDate),'-',DATEPART(MM,@CutOffDate),'-01')

		If @StartDate <= @CutOffDate
			BEGIN
				SET @StartDate = @CutOffDate
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

		
		If @EndDate < @CutOffDate
			BEGIN
				SET @MaxDate = @CutOffDate
			END
		ELSE
			BEGIN
				SET @MaxDate = @EndDate
			END

		IF DATEDIFF(WEEK,@StartDate,@MaxDate) >=99
			BEGIN
				SET @MaxDate = DATEADD(WEEK,98,@StartDate)
			END	

		SELECT @EndDate = DateAdd(Day, 6, @StartDate)

		;with cte (JCCo, Job, datelist, maxdate, EndDate) as
		(
			SELECT JCCo, Job, @StartDate AS datelist, @MaxDate AS maxdate, @EndDate
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

		If @StartDate < @CutOffDate
			BEGIN
				SET @StartDate = @CutOffDate --DateAdd(DAY,-1, @CutOffDate)
			END

		SELECT @StartDate = CONCAT(DATEPART(YYYY,@StartDate),'-',DATEPART(MM,@StartDate),'-01')

		If @EndDate < @CutOffDate
			BEGIN
				SET @MaxDate = @CutOffDate
				--SET @EndDate = @CutOffDate
				SET @EndDate = CONCAT(DATEPART(YYYY,@CutOffDate),'-',DATEPART(MM,@CutOffDate),'-01')
				SET @EndDate = DateAdd(Month, 1,  @EndDate)
				SET @EndDate = DateAdd(Day, -1, @EndDate)
			END
		ELSE
			BEGIN
				SET @MaxDate = @EndDate
				SELECT @EndDate = DateAdd(Month, 1, @StartDate)
				SELECT @EndDate = DateAdd(Day, -1, @EndDate)
			END
		
		IF DATEDIFF(MONTH,@StartDate,@MaxDate) >=60
			BEGIN
				SET @MaxDate = DATEADD(MONTH,59,@StartDate)
			END	


		;with cte (JCCo, Job, datelist, maxdate, EndDate) as
		(
			SELECT JCCo, Job, @StartDate AS datelist, @MaxDate AS maxdate, @EndDate
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

--Rebuild #tempdates to indclude MTD Actual Cost
DROP TABLE #tempDates

	BEGIN
		INSERT INTO @JCCP_MTD (JCCo, Job, PhaseGroup, Phase, Description, MTDCost, MTDHours)
					SELECT    HQ.HQCo
							, JP.Job
							, JP.PhaseGroup
							, JP.Phase
							, JP.Description
							, CP.ActualCost AS MTDCost
							, CP.ActualHours AS MTDHours
					FROM HQCO HQ
							INNER JOIN JCJP JP
								ON HQ.HQCo = JP.JCCo
								AND ((HQ.udTESTCo ='N') OR (HQ.udTESTCo IS NULL))
								AND JP.Job = @Job
								AND JP.JCCo = @JCCo
							INNER JOIN JCCH CH
								ON HQ.HQCo = CH.JCCo
								AND JP.Job = CH.Job 
								AND JP.PhaseGroup = CH.PhaseGroup
								AND JP.Phase = CH.Phase
								AND CH.CostType = 1
							LEFT OUTER JOIN JCCP CP 
								ON	CP.JCCo = JP.JCCo
								AND CP.Job = JP.Job 
								AND CP.PhaseGroup = JP.PhaseGroup
								AND CP.Phase = JP.Phase
								AND CP.CostType = 1
								--AND CP.Mth = '01-JUN-2016'
								AND CP.Mth = CONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01')
		END

SELECT B.JCCo, B.Job, B.PhaseGroup, B.Phase, B.Description, B.MTDCost, B.MTDHours, B.StartDate, B.EndDate INTO #tempDates2 
	FROM (SELECT A.JCCo, A.Job, M.PhaseGroup, M.Phase, M.Description, M.MTDCost, M.MTDHours, A.datelist AS StartDate, A.EndDate
			FROM  @DisplayRange A
			INNER JOIN @JCCP_MTD M
				ON A.JCCo = M.JCCo
				AND A.Job = M.Job
			WHERE A.EndDate >= @CutOffDate) as B 

SELECT TOP 1 @Flat_Phase = B1.Phase, @Flat_Date = B1.EndDate FROM  #tempDates2 B1

--set @query = 'Select * from #tempDates2'

--EXECUTE(@query)



--		set @Phase = '9300-0000-      -   '
	Set @CalcCol = 'CALCME'
	Set @ParentPhase = 'NO PARENT'
	Set @TextJCCo = Convert(VARCHAR,@JCCo)

set @query = 'SELECT ''' + @CalcCol + ''' AS Used, ParentPhase AS ''Parent Phase Group'', Phase as ''Phase Code'', PhaseDesc AS ''Phase Desc''
				, Employee AS ''Employee ID'', Description, ProjRemHours AS ''Remaining Hours'', RemCost AS ''Remaining Cost''
				, ''' + @CalcCol + ''' AS ''Budgeted Phase Hours Remaining'', ''' + @CalcCol + ''' AS ''Budgeted Phase Cost Remaining''
				, StartRemHours AS ''Previous Remaining Cost'', Variance
				, PhaseActualRt AS ''Phase Actual Rate'', Rate, MTDCost AS ''MTD Actual Cost'', MTDHours AS ''MTD Actual Hours'',' + @cols + ' from 
             (SELECT ISNULL(PM2.Description, ''' + @ParentPhase + ''') AS ParentPhase, PB.Phase, REPLACE(d.Description,''"'',''-'') AS PhaseDesc
				, PD.Employee, PD.Description, ''' + @CalcCol + ''' AS ProjRemHours, ''' + @CalcCol + ''' AS StartRemHours
				, ''' + @CalcCol + ''' AS Variance, ''' + @CalcCol + ''' AS PhaseActualRt
				, CASE WHEN (PD.Rate IS NOT NULL) THEN PD.Rate
					   WHEN (PB.OrigEstHours IS NULL) THEN 0
				       WHEN (PB.OrigEstHours <= 0) THEN 0 
				  ELSE (PB.OrigEstCost/PB.OrigEstHours)	END AS Rate
				, ''' + @CalcCol + ''' AS RemCost
				, d.MTDCost
				, d.MTDHours
				, ISNULL(PD.Hours,0) AS Hours, convert(CHAR(10), d2.EndDate, 120) PivotDate
				FROM JCPB PB 
					INNER JOIN #tempDates2 d
						ON PB.Job = ''' + @Job + '''
						AND PB.Co = ''' + @TextJCCo + '''
						AND PB.CostType = 1
						AND d.EndDate = ''' + convert(varchar(10), @Flat_Date, 120) + '''
						' + @tmpSQL + '
						AND d.JCCo = PB.Co
						AND d.Job = PB.Job 
					    AND d.PhaseGroup = PB.PhaseGroup
						AND d.Phase = PB.Phase
					LEFT OUTER JOIN (JCPM PM
										INNER JOIN JCPM PM2
											ON PM.PhaseGroup = PM2.PhaseGroup
											AND PM.udParentPhase = PM2.Phase)
						ON PB.PhaseGroup = PM.PhaseGroup
						AND SUBSTRING(PB.Phase,1,10) = SUBSTRING(PM.Phase,1,10)
					LEFT OUTER JOIN (#tempDates2 d2 
										INNER JOIN JCPD PD 
											ON d2.JCCo = PD.Co
											AND d2.Job = PD.Job
											AND d2.Phase = ''' + @Flat_Phase + '''
											--AND d2.PhaseGroup = PD.PhaseGroup
											--AND d2.Phase = PD.Phase
											AND PD.TransType<>''D''
										    AND ((PD.ToDate between d2.StartDate and d2.EndDate) 
												OR ((PD.ToDate IS NULL) 
													AND (PD.DetMth between d2.StartDate and d2.EndDate))))
						ON d2.JCCo = PB.Co
						AND d2.Job = PB.Job 
						AND PB.BatchId = PD.BatchId
						AND PB.BatchSeq = PD.BatchSeq
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

drop table #tempDates2

GO

Grant EXECUTE ON mers.mspGetJCProjHrsDyn TO [MCKINSTRY\Viewpoint Users]

