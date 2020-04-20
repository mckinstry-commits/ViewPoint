use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspGetRevProjBatchPivot' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspGetRevProjBatchPivot'
	DROP PROCEDURE mers.mspGetRevProjBatchPivot
end
go

print 'CREATE PROCEDURE mers.mspGetRevProjBatchPivot'
go

CREATE PROCEDURE mers.mspGetRevProjBatchPivot
(
	@JCCo		bCompany 
,	@Contract	bContract
)
as
-- ========================================================================
-- mers.mspGetRevProjBatchPivot
-- Author:	Ziebell, Jonathan
-- Create date: 07/19/2016
-- Description:	2016.05.06 - LWO - Created
	/*Procedure to return JC Revenue Projection Detail (udJCIRD) data for use in "Prophecy" VSTO workbook solution.
	Determines the Start and End Months for a Provided Contract and returns the data "pivoted" so that the time 
	span (months) are returned as columns (instead of the row based storage method).*/
-- Update Hist: USER--------DATE-------DESC-----------
--              J.Ziebell   7/19/2017  New Version
-- ========================================================================

DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX),
	@dispMonth bMonth,
	@tmpSQL varchar(255)

	, @StartDate Date
	, @EndDate Date
	, @FinalDate Date
	, @DayStart INT
	, @CalcCol VARCHAR(6)
	, @ParentPhase VARCHAR(10)
	, @TextJCCo VARCHAR(5)
	, @CutOffDate Date

DECLARE @DisplayRange TABLE 
	(
	JCCo tinyint
	, Contract bContract
	, StartDate Date
	, EndDate Date
	)

select @dispMonth=max(Mth) from JCIR where Co=@JCCo and Contract=@Contract

if @dispMonth is not null 
	select @tmpSQL= 'and D.Mth = ''' + convert(varchar(10), @dispMonth, 120) + ''''
else 
	select @tmpSQL=''	

SELECT @StartDate = StartMonth, @FinalDate = ProjCloseDate from JCCM where JCCo=@JCCo and Contract= @Contract 

BEGIN
		SELECT @StartDate = CONCAT(DATEPART(YYYY,@StartDate),'-',DATEPART(MM,@StartDate),'-01')
		SELECT @EndDate = DateAdd(Month, 1, @StartDate)
		SELECT @EndDate = DateAdd(Day, -1, @EndDate)

		;with cte (JCCo, Contract, StartDate, EndDate) as
		(
			SELECT JCCo, Contract, @StartDate AS StartDate, @EndDate
				FROM JCCM
					WHERE JCCo=@JCCo and Contract=@Contract
					GROUP BY JCCo, Contract
				UNION ALL
			SELECT JCCo, Contract, dateadd(MONTH, 1, StartDate), dateadd(Day,-1,(dateadd(MONTH, 2, StartDate)))
				FROM cte
				WHERE StartDate < dateadd(day,( day(@FinalDate) * -1 ) + 1 ,@FinalDate) 
					AND JCCo=@JCCo 
					AND Contract=@Contract
		) 

		INSERT INTO @DisplayRange (JCCo, Contract, StartDate, EndDate)
			SELECT c.JCCo, c.Contract, c.StartDate, c.EndDate
			FROM cte c
END

SELECT B.JCCo, B.Contract, B.StartDate, B.EndDate INTO #tempDates 
	FROM (SELECT JCCo, Contract, StartDate, EndDate
			FROM  @DisplayRange) as B 

select @cols = STUFF((SELECT distinct ',' + QUOTENAME(convert(CHAR(10), EndDate, 120)) 
                    from #tempDates
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

    Set @CalcCol = 'CALCME'
	Set @ParentPhase = 'NO PARENT'
	Set @TextJCCo = Convert(VARCHAR,@JCCo)

set @query = 'SELECT udPRGNumber, udPRGDescription, Department, DeptDescription, Item, Description, CostItem
, FutureAmount, CurrentContract, Opening, OpenVariance, PrevRevProjDollars
				, PMVariance, ProjectedCV, PendingCO, Margin,' + @cols + ' from 
             (
				SELECT I.udPRGNumber, I.udPRGDescription, I.Department, DM.Description AS DeptDescription, I.Item, I.Description
				, T.ProjCost AS CostItem, T.FutureAmount, T.CurrentContract, ''' + @CalcCol + ''' as Opening
				, ''' + @CalcCol + ''' AS OpenVariance, R.PrevRevProjDollars, ''' + @CalcCol + ''' As PMVariance
				, ''' + @CalcCol + ''' AS ProjectedCV, ''' + @CalcCol + ''' AS PendingCO, ''' + @CalcCol + ''' AS Margin
				, ISNULL(D.ProjDollars,0) AS ProjDollars, convert(CHAR(10), M.EndDate, 120) PivotDate
				FROM JCCI I
					INNER JOIN JCIR	R
						ON I.JCCo = R.Co
						AND I.Contract=R.Contract
						AND I.Item = R.Item
						AND I.JCCo = ''' + @TextJCCo + '''
						AND I.Contract = ''' + @Contract + '''
					INNER JOIN JCDM DM
							ON I.Department = DM.Department
					INNER JOIN JCIRTotals T
						ON I.JCCo = T.Co
						AND I.Contract = T.Contract
						AND I.Item = T.Item
					INNER JOIN (udJCIRD D
										INNER JOIN #tempDates M
											ON D.Co = M.JCCo
											AND D.Contract = M.Contract
											AND (D.ToDate between M.StartDate and M.EndDate))
						ON I.JCCo = D.Co
						AND I.Contract=D.Contract
						AND I.Item = D.Item	
					' + @tmpSQL + ' 
            ) x
            pivot 
            (
                sum(ProjDollars)
                for PivotDate in (' + @cols + ')
            ) p;'

print @query

execute(@query)

drop table #tempDates

go

