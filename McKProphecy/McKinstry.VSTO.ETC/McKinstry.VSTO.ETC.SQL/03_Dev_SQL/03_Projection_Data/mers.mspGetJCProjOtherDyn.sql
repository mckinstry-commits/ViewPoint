use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspGetJCProjOtherDyn' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE dbo.mspGetJCProjOtherDyn'
	DROP PROCEDURE dbo.mspGetJCProjOtherDyn
end
go

print 'CREATE PROCEDURE dbo.mspGetJCProjOtherDyn'
go


CREATE PROCEDURE [dbo].[mspGetJCProjOtherDyn]
(
	@JCCo		bCompany 
,	@Job		bJob
,	@Pivot      VARCHAR(5)
)
as
-- ========================================================================
-- Object Name: dbo.mspGetJCProjOtherDyn
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
--              J.Ziebell   8/18/2016  Column Header Changes
--				J.Ziebell   9/06/2016  Add MTD Actual Cost
--              J.Ziebell   10/06/2016 5 year cutoff window
--				J.Ziebell   11/08/2016 Include All Non-Closed Months in Projection Period
--				J.Ziebell   11/22/2016 Fix Incorrect End Date Logic/ Close Month table
--				L.Gurdian	12/01/2017 Now able to project on Projects exceeding 60 months or 100 weeks 
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
	, @Text_CostType VARCHAR(1)
	, @CutOffDate Date
	, @MaxDate Date
	, @Flat_Phase VARCHAR(20)
	, @Flat_Date Date
	, @Flat_CostType tinyint
	, @LockMth Date
	, @FirstMonth Date

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
			, CostType tinyint
			, MTDCost NUMERIC(11,2)
			)

SELECT @dispMonth=max(Mth), @CutOffDate=MAX(ActualDate) from JCPB where Co=@JCCo and Job=@Job

SELECT @LockMth = LastMthSubClsd from dbo.GLCO where GLCo = @JCCo
SET @FirstMonth = DATEADD(MONTH,1,@LockMth)

--select @LockMth = Max(LockMonth) from dbo.udWIPLockCalendar where CompanyCode=@JCCo
--IF @LockMth < '01-MAY-2016'
--	BEGIN
--		SET @LockMth = '01-MAY-2016'
--	END

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

		If @EndDate < @CutOffDate
			BEGIN
				SET @MaxDate = @CutOffDate
			END
		ELSE
			BEGIN
				SET @MaxDate = @EndDate
			END

		--IF DATEDIFF(WEEK,@StartDate,@MaxDate) >=99
		--	BEGIN
		--		SET @MaxDate = DATEADD(WEEK,98,@StartDate)
		--	END	

		SELECT @EndDate = DateAdd(Day, 6, @StartDate)

		;with cte (JCCo, Job, datelist, maxdate, EndDate) as
		(
			SELECT JCCo, Job, @StartDate AS datelist, @MaxDate as maxdate, @EndDate
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
			OPTION (MAXRECURSION 16367); -- Excel's column limit 16,384 - month/week start column - 1
	END
ELSE
IF @Pivot = 'MONTH'
	BEGIN
		SELECT @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=@JCCo and Job= @Job

		If @StartDate < @FirstMonth --@CutOffDate
			BEGIN
				SET @StartDate = @FirstMonth --@CutOffDate --DateAdd(DAY,-1, @CutOffDate)
			END

		SELECT @StartDate = CONCAT(DATEPART(YYYY,@StartDate),'-',DATEPART(MM,@StartDate),'-01')
				If @EndDate < @CutOffDate
					BEGIN
						--SET @EndDate = @CutOffDate
						SET @MaxDate = @CutOffDate
						SET @EndDate = CONCAT(DATEPART(YYYY,@StartDate),'-',DATEPART(MM,@StartDate),'-01')
						SET @EndDate = DateAdd(Month, 1,  @EndDate)
						SET @EndDate = DateAdd(Day, -1, @EndDate)
					END
				ELSE
					BEGIN
						SET @MaxDate = @EndDate
						SELECT @EndDate = DateAdd(Month, 1, @StartDate)
						SELECT @EndDate = DateAdd(Day, -1, @EndDate)
					END
		
		--IF DATEDIFF(MONTH,@StartDate,@MaxDate) >=60
		--	BEGIN
		--		SET @MaxDate = DATEADD(MONTH,59,@StartDate)
		--	END	

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
			OPTION (MAXRECURSION 16367); -- Excel's column limit 16,384 - month/week start column - 1
	END

SELECT B.JCCo, B.Job, B.datelist, B.EndDate INTO #tempDates 
	FROM (SELECT JCCo, Job, datelist, EndDate
			FROM  @DisplayRange
			WHERE EndDate >= @FirstMonth) as B 


SELECT @cols = STUFF((SELECT distinct ',' + QUOTENAME(convert(CHAR(10), EndDate, 120)) 
                    from #tempDates
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

--Rebuild #tempdates to indclude MTD Actual Cost
DROP TABLE #tempDates

	BEGIN
		INSERT INTO @JCCP_MTD (JCCo, Job, PhaseGroup, Phase, Description, CostType, MTDCost)
					SELECT    HQ.HQCo
							, JP.Job
							, JP.PhaseGroup
							, JP.Phase
							, JP.Description
							, CH.CostType
							, CP.ActualCost AS MTDCost
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
								AND CH.CostType <> 1
							LEFT OUTER JOIN JCCP CP 
								ON	CP.JCCo = JP.JCCo
								AND CP.Job = JP.Job 
								AND CP.PhaseGroup = JP.PhaseGroup
								AND CP.Phase = JP.Phase
								AND CP.CostType = CH.CostType
								--AND CP.Mth = '01-JUN-2016'
								AND CP.Mth = @dispMonth -- ONCAT(DATEPART(YYYY,SYSDATETIME()),'-',DATEPART(MM,SYSDATETIME()),'-01')
		END

SELECT B.JCCo, B.Job, B.PhaseGroup, B.Phase, B.Description, B.MTDCost, B.CostType, B.StartDate, B.EndDate INTO #tempDates2 
	FROM (SELECT A.JCCo, A.Job, M.PhaseGroup, M.Phase, M.Description, M.CostType, M.MTDCost, A.datelist AS StartDate, A.EndDate
			FROM  @DisplayRange A
			INNER JOIN @JCCP_MTD M
				ON A.JCCo = M.JCCo
				AND A.Job = M.Job
			WHERE A.EndDate >= @FirstMonth) as B 

SELECT TOP 1 @Flat_Phase = B1.Phase, @Flat_Date = B1.EndDate, @Flat_CostType = B1.CostType FROM  #tempDates2 B1

--set @query = 'Select * from #tempDates2'

--EXECUTE(@query)

    Set @CalcCol = 'X'
	Set @ParentPhase = 'NO PARENT'
	Set @TextJCCo = Convert(VARCHAR,@JCCo)
	Set @Text_CostType = Convert(VARCHAR,@Flat_CostType)

	--Set @FilterY = 'Y'
	--Set @FilterN = 'N'
--CASE WHEN (PD.Amount IS NULL) THEN ''' + @FilterN + '''
	--						WHEN (PD.Amount <> 0) THEN ''' + @FilterY + '''

set @query = 'SELECT ''' + @CalcCol + ''' AS Used, ParentPhase AS ''Parent Phase Group'', Phase AS ''Phase Code'', PhaseDesc AS ''Phase Desc''
				, CostType AS ''Cost Type'', Description
				, BudgetRemCost AS ''Budgeted Phase Cost Remaining'', BudgetRemCost AS ''Previous Remaining Cost'', Variance
				, BudgetRemCost AS ''Phase Open Committed'', ProjRemCost AS ''Remaining Cost'', MTDCost AS ''MTD Actual Cost'', ' + @cols + ' from 
             (SELECT ISNULL(PM2.Description, ''' + @ParentPhase + ''') AS ParentPhase, PB.Phase, REPLACE(d.Description,''"'',''-'') AS PhaseDesc
				, CT.Abbreviation as CostType, PD.Description, ''' + @CalcCol + ''' AS BudgetRemCost, ''' + @CalcCol + ''' AS Variance
				, d.MTDCost
				, ''' + @CalcCol + ''' AS ProjRemCost, ISNULL(PD.Amount,0) AS Amount, convert(CHAR(10), d2.EndDate, 120) PivotDate
				FROM JCPB PB 
				INNER JOIN #tempDates2 d
					ON PB.Job = ''' + @Job + '''
					AND PB.Co = ''' + @TextJCCo + '''
					AND d.EndDate = ''' + convert(varchar(10), @Flat_Date, 120) + '''
					AND PB.CostType = d.CostType
					' + @tmpSQL + '
					AND d.JCCo = PB.Co
					AND d.Job = PB.Job 
					AND d.CostType = PB.CostType
					AND d.PhaseGroup = PB.PhaseGroup
					AND d.Phase = PB.Phase
				INNER JOIN JCCT CT
					ON PB.PhaseGroup = CT.PhaseGroup
					AND PB.CostType = CT.CostType
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
										AND d2.CostType = ''' + @Text_CostType + '''
										AND PD.CostType <> 1
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
                sum(Amount)
                for PivotDate in (' + @cols + ')
            ) p ORDER BY Phase, CostType ;'

--PRINT @query

EXECUTE(@query)

DROP TABLE #tempDates2

GO

Grant EXECUTE ON dbo.mspGetJCProjOtherDyn TO [MCKINSTRY\Viewpoint Users]


