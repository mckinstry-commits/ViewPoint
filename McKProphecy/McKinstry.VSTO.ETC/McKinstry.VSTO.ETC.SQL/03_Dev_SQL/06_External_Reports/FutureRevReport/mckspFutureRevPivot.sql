use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckspFutureRevPivot' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE dbo.mckspFutureRevPivot'
	DROP PROCEDURE dbo.mckspFutureRevPivot
end
go

print 'CREATE PROCEDURE dbo.mckspFutureRevPivot'
go

CREATE PROCEDURE [dbo].[mckspFutureRevPivot]
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
-- Object Name: mers.mckspFutureRevPivot
-- Author:		Ziebell, Jonathan
-- Create date: 04/14/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	04/15/2017 
--				J.Ziebell	05/09/2017 Added Forecast Type Search, Label Change
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
DECLARE @DisplayRange TABLE 
	(
	StartDate Date
	)

if @BaseMonth is not null 
	BEGIN
		SET @CharMonth = convert(varchar(10), @BaseMonth, 120)
	END
ELSE 
	BEGIN
		SELECT @LockMth = LastMthSubClsd from dbo.GLCO where GLCo = 1
		SET @CharMonth = convert(varchar(10), DATEADD(MONTH,1,@LockMth), 120)
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
		IF @NumMonths >60
			BEGIN
				SET @NumMonths = 60
			END	

SET NOCOUNT ON 
		
	;WITH MonthRange (StartDate) AS
			(
				SELECT @BaseMonth as StartDate
					UNION ALL
				SELECT dateadd(MONTH, 1, StartDate) as StartDate
					FROM MonthRange
					WHERE StartDate < dateadd(MONTH, @NumMonths -1, @BaseMonth) 
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
				(select   x.udPRGNumber As ''PRG''
						, x.udPRGDescription AS ''PRG Description''
						, x.JCCo
						, x.Department AS ''GL Dept''
						, x.Description AS ''GL Dept Description''
						, x.JCDept AS ''JC Dept''
						, x.Contract
						, x.ContractDesc AS ''Contract Description''
						, x.RevType AS ''Revenue Type''
						, x.POCName AS ''POC Name''
						, x.POC
						, x.ProjMgrName AS ''Proj Mgr Name''
						, x.ProjMgr AS ''Proj Mgr''
						, x.RevTotal AS ''Projected Final Contract Value''
						, x.JTDEarnedRev As ''Earned Revenue''
						, x.ProjGMP AS ''GM %''
						, x.FutureCostTotal
						, x.FutureRevTotal
						, x.RemainRev AS ''Remaining Rev''
						, x.UnburnRev AS ''Unburned Rev''
						, x.AbsFutureRev AS ''Absent Future Rev''
						, x.AbsFutureCost AS ''Absent Future Cost''
						, x.MarginChange As ''GM % Change''
						, x.MarginChgImpact as ''GM %Chg Impact''
						, CASE WHEN x.MarginChange = 0 THEN 0 WHEN (x.JTDEarnedRev = 0) THEN 0 ELSE (x.MarginChgImpact + x.AdjCurrentMth) END AS ''Adj Current Mth Rev''
						, z.TotalRev AS MthRev
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

EXECUTE(@query)

--DROP TABLE #tempDates

END

GO

Grant EXECUTE ON dbo.mckspFutureRevPivot TO [MCKINSTRY\Viewpoint Users]

