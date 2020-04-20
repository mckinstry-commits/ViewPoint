use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnJCPRGPivot' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mfnJCPRGPivot'
	DROP PROCEDURE mers.mfnJCPRGPivot
end
go

print 'CREATE PROCEDURE mers.mfnJCPRGPivot'
go

CREATE PROCEDURE [mers].[mfnJCPRGPivot]
(
	@JCCo		bCompany 
,	@Contract	bContract
)
as
-- ========================================================================
-- Object Name: mers.mfnJCPRGPivot
-- Author:		Ziebell, Jonathan
-- Create date: 07/28/2016
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	08/02/2016 Multiply by Margin
--				J.Ziebell	08/11/2016 Show Remaining Revenue if NULL WIP
--				J.Ziebell	08/15/2016 Add PRG Desc, JC Dept, Dept Desc
--				J.Ziebell   08/16/2016 Reorder of Department and PRG in Cost
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
	, @FinalDate Date
	, @CharMonth VARCHAR(10)
	, @LockMth Date

DECLARE @DisplayRange TABLE 
	(
	JCCo bCompany 
	, Contract bContract
	, StartDate Date
	, EndDate Date
	)
DECLARE	@JCIP_Sum TABLE
				( JCCo bCompany
				, Contract bContract
				, Department bDept
				, DeptDesc bDesc
				, udPRGNumber bJob
				, udPRGDescription bItemDesc
				, ProjDollars NUMERIC(38,8)
				)
DECLARE	@JCCP_Cost TABLE
				( JCCo bCompany
				, Contract bContract
				, Department bDept
				, udPRGNumber bJob
				, ProjectedCost NUMERIC(38,8)
				)

DECLARE @WIP_Rev TABLE 
				(JCCo bCompany
				, Contract bContract
				, Department varchar(10)
				, udPRGNumber bJob
				, JTDEarnedRev NUMERIC(38,8))

SELECT @dispMonth=max(Mth) from JCPR where JCCo=@JCCo and SUBSTRING(Job,1,7)= @Contract

SELECT @CutOffDate = SYSDATETIME();

select @LockMth = Max(LockMonth) from dbo.udWIPLockCalendar where CompanyCode=@JCCo
IF @LockMth < '01-MAY-2016'
	BEGIN
		SET @LockMth = '01-MAY-2016'
	END

if @dispMonth is not null 
	BEGIN
		select @tmpSQL= 'and PD.Mth = ''' + convert(varchar(10), @dispMonth, 120) + ''''
		SET @CharMonth = convert(varchar(10), @dispMonth, 120)
	END
ELSE 
	BEGIN
		select @tmpSQL=''
		SET @CharMonth = convert(varchar(10), @CutOffDate, 120)
	END

	BEGIN
		SELECT @StartDate = StartMonth, @FinalDate = ProjCloseDate from JCCM where JCCo=@JCCo and Contract= @Contract 

		If @StartDate < @CutOffDate
			BEGIN
				SET @StartDate = @CutOffDate
			END

				SELECT @StartDate = CONCAT(DATEPART(YYYY,@StartDate),'-',DATEPART(MM,@StartDate),'-01')
				SELECT @EndDate = DateAdd(Month, 1, @StartDate)
				SELECT @EndDate = DateAdd(Day, -1, @EndDate)

		;with cte (JCCo, Contract, StartDate, EndDate, FinalDate) as
		(
			SELECT JCCo, Contract, @StartDate AS StartDate, @EndDate AS EndDate, @FinalDate AS FinalDate
				FROM JCCM
					WHERE JCCo=@JCCo and Contract=@Contract
					GROUP BY JCCo, Contract
				UNION ALL
			SELECT JCCo, Contract, dateadd(MONTH, 1, StartDate), dateadd(Day,-1,(dateadd(MONTH, 2, StartDate))), FinalDate
				FROM cte
				WHERE StartDate < dateadd(day,( day(FinalDate) * -1 ) + 1 ,FinalDate) and JCCo=@JCCo and Contract=@Contract
		) 
		INSERT INTO @DisplayRange (JCCo, Contract, StartDate, EndDate)
			SELECT c.JCCo, c.Contract, c.StartDate, c.EndDate
			FROM cte c
	END

SELECT B.JCCo, B.Contract, B.StartDate, B.EndDate INTO #tempDates 
	FROM (SELECT JCCo, Contract, StartDate, EndDate
			FROM  @DisplayRange
			WHERE EndDate >= @CutOffDate) as B 


SELECT @cols = STUFF((SELECT distinct ',' + QUOTENAME(convert(CHAR(10), EndDate, 120)) 
                    from #tempDates
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

    Set @CalcCol = 'CALCME'
	Set @ParentPhase = 'NA - WIP'
	Set @TextJCCo = Convert(VARCHAR,@JCCo)

--DETERMINE PROJECTED MARGIN

DROP TABLE #tempDates
	BEGIN
		INSERT INTO @JCIP_Sum (JCCo, Contract, Department, DeptDesc, udPRGNumber, udPRGDescription, ProjDollars)
					SELECT CI.JCCo
						, CI.Contract
						, CI.Department
						, DM.Description AS DeptDesc
						, CI.udPRGNumber
						, MAX(CI.udPRGDescription)
						--, WIP.JTDEarnedRev
						, SUM(IP.ProjDollars)
				FROM JCCI CI
					INNER JOIN JCIP IP
						ON CI.JCCo = IP.JCCo
						AND CI.Contract = IP.Contract
						AND CI.Item = IP.Item
					LEFT OUTER JOIN	JCDM DM
						ON CI.JCCo = DM.JCCo
						AND CI.Department = DM.Department 
					WHERE CI.JCCo = @JCCo
						AND CI.Contract = @Contract
					GROUP BY  CI.JCCo
						, CI.Contract
						, CI.Department
						, DM.Description
						, CI.udPRGNumber
						--, WIP.JTDEarnedRev
	END

		BEGIN
			INSERT INTO @WIP_Rev (JCCo, Contract, Department, udPRGNumber, JTDEarnedRev)
						SELECT WIP.JCCo
							, WIP.Contract
							, WIP.JCCIDepartment
							, WIP.PRGNumber
							, MAX(WIP.JTDEarnedRev) AS JTDEarnedRev
						FROM mckWipArchiveJC3 WIP
						WHERE WIP.JCCo = @JCCo
							AND WIP.Contract = @Contract
							AND WIP.ThroughMonth = @LockMth
						GROUP BY  WIP.JCCo
							, WIP.Contract
							, WIP.JCCIDepartment
							, WIP.PRGNumber
		END

		--SELECT * FROM @WIP_Rev
		--EXECUTE(@query)

	BEGIN
		INSERT INTO @JCCP_Cost (JCCo, Contract, Department, udPRGNumber, ProjectedCost)
			SELECT 
				  JP.JCCo
				, CI.Contract
				, CI.Department
				, CI.udPRGNumber
				, sum(CP.ProjCost) AS ProjectedCost 
			FROM JCJP JP 
				INNER JOIN JCCP CP
					ON CP.JCCo = JP.JCCo 
					AND CP.Job = JP.Job 
					AND CP.PhaseGroup = JP.PhaseGroup 
					AND CP.Phase = JP.Phase
				INNER JOIN JCCI CI
					ON 	JP.JCCo = CI.JCCo
					AND JP.Contract = CI.Contract
					AND JP.Item = CI.Item
			WHERE JP.JCCo = @JCCo
				AND JP.Contract = @Contract
			GROUP BY  JP.JCCo
					, CI.Contract
					, CI.udPRGNumber
					, CI.Department
				--SELECT CP.JCCo, CP.Job AS udPRGnumber, sum(CP.ProjCost) AS ProjectedCost
				--	FROM JCCP CP
				--		INNER JOIN @JCIP_Sum S1
				--		ON CP.JCCo = S1.JCCo
				--		AND CP.Job = S1.udPRGNumber
				--	GROUP BY  CP.JCCo
				--			, CP.Job
		END				

SELECT B.JCCo, B.Contract, B.Department, B.DeptDesc, B.Job, B.udPRGDescription, B.StartDate, B.EndDate
						, B.RemainingRev, B.ProjDollars, B.ProjectedCost, B.ProjMargin INTO #tempDates2 
	FROM (SELECT A.JCCo, R.Contract, R.Department, R.DeptDesc, R.udPRGNumber as Job, R.udPRGDescription, StartDate, EndDate
	, CASE WHEN (W.JTDEarnedRev IS NULL) THEN R.ProjDollars
			ELSE (R.ProjDollars - W.JTDEarnedRev) END AS RemainingRev, R.ProjDollars, C.ProjectedCost, 
				CASE WHEN R.ProjDollars >0 THEN ((R.ProjDollars-C.ProjectedCost)//*CAST(*/R.ProjDollars/* as float)*/)
					ELSE -2 END as ProjMargin
			FROM  @DisplayRange A
			INNER JOIN @JCIP_Sum R
				ON A.JCCo = R.JCCo
				AND A.Contract = R.Contract
			LEFT OUTER JOIN @JCCP_Cost C
				ON A.JCCo = C.JCCo
				AND R.Contract = C.Contract
				AND R.Department = C.Department
				AND R.udPRGNumber = C.udPRGNumber
			LEFT OUTER JOIN @WIP_Rev W
				ON W.JCCo = A.JCCo
				AND W.Contract = A.Contract
				AND W.Department = R.Department
				AND W.udPRGNumber = R.udPRGNumber
			WHERE EndDate >= @CutOffDate) as B 

--SET @query = 'SELECT * FROM #tempDates2'

--EXECUTE(@query)

	--Set @FilterY = 'Y'
	--Set @FilterN = 'N'
--CASE WHEN (PD.Amount IS NULL) THEN ''' + @FilterN + '''
	--						WHEN (PD.Amount <> 0) THEN ''' + @FilterY + '''
	--''' + @CalcCol + ''' AS UsedFilter
	--, d.ProjDollars, d.ProjectedCost, d.ProjMargin
	--, p.ProjDollars, p.ProjectedCost, p.ProjMargin


set @query = 'SELECT p.Job AS PRG, p.udPRGDescription AS ''PRG Description'', p.Department as ''JC Dept''
			, p.DeptDesc AS ''JC Dept Description'', p.RemainingRev AS ''Remaining Revenue''
			, ''' + @CalcCol + ''' AS ''Remaining at Margin'', ''' + @CalcCol + ''' AS ''Margin Change CU''
			, ''' + @CalcCol + ''' AS ''Current Month CU'',' + @cols + ' FROM
             (SELECT d.Job, d.udPRGDescription, d.Department, d.DeptDesc, d.RemainingRev
				, ((1+d.ProjMargin)*(ISNULL(PR.Amount,0))) AS Amount
				, convert(CHAR(10), d.EndDate, 120) AS PivotDate
					FROM HQCO HQ
						INNER JOIN #tempDates2 d
								ON HQ.HQCo = d.JCCo
								AND ((HQ.udTESTCo =''N'') OR (HQ.udTESTCo IS NULL))
						LEFT OUTER JOIN JCPR PR
								ON PR.JCCo = d.JCCo
								AND PR.Job = d.Job
								AND PR.Mth = ''' + @CharMonth + '''
								AND ((PR.ToDate between d.StartDate and d.EndDate) 
								OR ((PR.ToDate IS NULL) AND (PR.FromDate IS NULL) AND (PR.DetMth between d.StartDate and d.EndDate)))
            ) x
            pivot 
            (
                sum(Amount)
                for PivotDate in (' + @cols + ')
            ) p 
			ORDER BY p.Job;'

--PRINT @query

EXECUTE(@query)

DROP TABLE #tempDates2

