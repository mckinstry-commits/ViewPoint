use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckspFutureRevPivotDet' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE dbo.mckspFutureRevPivotDet'
	DROP PROCEDURE dbo.mckspFutureRevPivotDet
end
go

print 'CREATE PROCEDURE dbo.mckspFutureRevPivotDet'
go

CREATE PROCEDURE [dbo].[mckspFutureRevPivotDet]
(
	@JCCo		bCompany 
,	@Dept		bDept		= 'ALL'
,	@Contract 	bContract	= 'ALL'
,   @PRG		bJob		= 'ALL'
,   @POC		VARCHAR(50) = 'ALL'
,   @BaseMonth	bMonth
,   @NumMonths	int
,   @NonRev     VARCHAR(1)  
,   @ForType    VARCHAR(1) 
)
as
-- ========================================================================
-- Object Name: mers.mckspFutureRevPivotDet
-- Author:		Ziebell, Jonathan
-- Create date: 06/15/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	06/15/2017 
--				J.Ziebell	06/19/2017 Added Forecast Type Search, Label Change
--				J.Ziebell   06/29/2017 Justin Changes
-- ========================================================================
DECLARE @cols AS NVARCHAR(MAX)
    , @query  AS NVARCHAR(MAX)
	, @dispMonth bMonth
	--, @StartDate Date
	--, @EndDate Date
	--, @DayStart INT
	--, @CalcCol VARCHAR(6)
	--, @ParentPhase VARCHAR(10)
	, @TextJCCo VARCHAR(5)
	, @CutOffDate Date
	, @FinalDate Date
	, @CharMonth VARCHAR(10)
	, @LockMth Date
	, @FirstMonth Date
	, @RevText VARCHAR(50)
	, @ForText VARCHAR(50)
	, @NewMonth Date
DECLARE @DisplayRange TABLE 
	(
	StartDate Date
	)



if @BaseMonth is not null 
	BEGIN
		SET @NewMonth = CONCAT(DATEPART(YYYY,@BaseMonth),'-01-01')
		SET @CharMonth = convert(varchar(10), @BaseMonth, 120)
	END
ELSE 
	BEGIN
		SELECT @LockMth = LastMthSubClsd from dbo.GLCO where GLCo = 1
		SET @NewMonth = CONCAT(DATEPART(YYYY,@LockMth),'-01-01')
		SET @CharMonth = convert(varchar(10), DATEADD(MONTH,1,@BaseMonth), 120)
	END



IF @Dept IS NULL
	SET @Dept='ALL'
IF @Contract IS NULL
	SET @Contract = 'ALL'
IF @PRG IS NULL
	SET @PRG = 'ALL'
IF @POC IS NULL
	SET @POC = 'ALL'

SET @RevText = '= x.RevType'

If @NonRev = 'Y'
	SET @RevText = '= ''Non-Revenue'' '
If @NonRev = 'N'
	SET @RevText = '<> ''Non-Revenue'' '

SET @ForText = ''
If @ForType = 'Y'
	SET @ForText = ' AND JM.udForecastOnly = ''Y'''
If @ForType = 'N'
	SET @ForText = ' AND JM.udForecastOnly <> ''Y'''
--If @ForType IS NULL
--	SET @ForText = ''
--If @ForType = 'A'
--	SET @ForText = ''

BEGIN
--SET @NumMonths = 24
		IF @NumMonths >60
			BEGIN
				SET @NumMonths = 60
			END	

SET NOCOUNT ON 
		
	;WITH MonthRange (StartDate) AS
			(
				SELECT @NewMonth as StartDate
					UNION ALL
				SELECT dateadd(MONTH, 1, StartDate) as StartDate
					FROM MonthRange
					WHERE StartDate < dateadd(MONTH, @NumMonths -1, @NewMonth) 
			)
			INSERT INTO @DisplayRange (StartDate)
			SELECT c.StartDate
			FROM MonthRange c
			 	--SELECT B.StartDate INTO #tempDates 
					--FROM (SELECT StartDate
					--		FROM MonthRange) as B 

SET NOCOUNT OFF

SELECT @cols = STUFF((SELECT distinct ',' + QUOTENAME(convert(CHAR(10), StartDate, 120)) 
                    from @DisplayRange
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

	Set @TextJCCo = Convert(VARCHAR,@JCCo)

--SET @query = 'SELECT * FROM #tempDates2'

--EXECUTE(@query)
	
set @query = 'SELECT p.* FROM
				(select   LTRIM(x.udPRGNumber) As ''PRG''
						, x.udPRGDescription AS ''PRG Description''
						, CASE WHEN x.RevTotal = 0 THEN NULL ELSE x.RevTotal END AS ''Projected Final Contract Value''
						, CASE WHEN x.JTDEarnedRev = 0 THEN NULL ELSE x.JTDEarnedRev END As ''Earned Revenue''
						, CASE WHEN x.ProjGMP = 0 THEN NULL ELSE x.ProjGMP END AS ''GM %''
						, CASE WHEN x.RemainRev = 0 THEN NULL ELSE x.RemainRev END AS ''Remaining Rev''
						, CASE WHEN x.UnburnRev = 0 THEN NULL ELSE x.UnburnRev END AS ''Unburned Rev''
						, CASE WHEN z.TotalRev = 0 THEN NULL ELSE z.TotalRev END AS MthRev
						, z.Mth as PivotDate
					FROM mckJCPRRevFlat x
						LEFT OUTER JOIN mckJCPRMthFlat z
							ON x.JCCo=z.JCCo
							AND x.Department = z.Department
							AND x.Contract = z.Contract
							AND x.udPRGNumber = z.udPRGNumber
							AND z.Mth >='''+ @CharMonth + '''
							AND z.EffectMth = x.EffectMth
						LEFT OUTER JOIN JCJM JM
							ON x.JCCo = JM.JCCo
							AND x.udPRGNumber = JM.Job
						WHERE x.JCCo = ''' + @TextJCCo + '''
							AND x.EffectMth = ''' + @CharMonth + '''
							AND x.ConRemRevenue >= 1000
							AND ((''' + @Dept + ''' = ''ALL'') OR (LTRIM(x.Department) = LTRIM(''' + @Dept + ''')))
							AND ((''' + @Contract + ''' = ''ALL'') OR (LTRIM(x.Contract) = LTRIM(''' + @Contract + ''')))
							AND ((''' + @PRG + ''' = ''ALL'') OR (LTRIM(x.udPRGNumber) = LTRIM(''' + @PRG + ''')))
							AND ((''' + @POC + ''' = ''ALL'') OR (UPPER(x.POCName) LIKE (''%'' + coalesce(UPPER(''' + @POC + '''),'' '') + ''%'')))
							AND x.RevType ' + @RevText + '
							' + @ForText + ' 
					) x
						pivot 
						(
							sum(MthRev)
							for PivotDate in (' + @cols + ')
						) p;'

--PRINT @query


--Print @NewMonth
--Print @CharMonth

EXECUTE(@query)

--DROP TABLE #tempDates

END

GO


Grant EXECUTE ON dbo.mckspFutureRevPivotDet TO [MCKINSTRY\Viewpoint Users]




						--, x.udPRGDescription AS ''PRG Description''
						--, x.JCCo
						--, x.Department AS ''GL Dept''
						--, x.Description AS ''Dept Description''
						--, x.JCDept AS ''JC Dept''
						--, x.Contract
						--, x.ContractDesc AS ''Contract Description''
						--, x.RevType AS ''Rev Type''
						--, x.POCName AS ''POC Name''
						--, x.POC
						--, x.ProjMgrName AS ''Proj Mgr Name''
						--, x.ProjMgr AS ''Proj Mgr''

						--, x.FutureCostTotal
						--, x.FutureRevTotal
						

						--						, x.AbsFutureRev AS ''Abs Future Rev''
						--, x.AbsFutureCost AS ''Abs Future Cost''
						--, x.MarginChange As ''GM % Change''
						--, x.MarginChgImpact as ''GM %Chg Impact''
						--, CASE WHEN x.MarginChange = 0 THEN 0 WHEN (x.JTDEarnedRev = 0) THEN 0 ELSE (x.MarginChgImpact + x.AdjCurrentMth) END AS ''Adj Current Mth''
						

