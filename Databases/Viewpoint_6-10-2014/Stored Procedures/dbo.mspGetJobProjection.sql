SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[mspGetJobProjection](@JCCo tinyint,@Job varchar(20))
AS

BEGIN

declare @returnTable TABLE 
(
	JCCo		tinyint	null
,	Job			varchar(20)	null
,	Phase		varchar(20)		null
,	Mth			smalldatetime		NULL
,	ActualCost		numeric(12,2) NOT NULL 
,	OrigEstCost		numeric(12,2) NOT NULL 
,	CurrEstCost		numeric(12,2) NOT NULL 
,	ProjCost		numeric(12,2) NOT NULL 
,	ForecastCost		numeric(12,2) NOT NULL 
,	TotalCmtdCost		numeric(12,2) NOT NULL 
,	RemainCmtdCost		numeric(12,2) NOT NULL 
) 

	DECLARE jpcur CURSOR FOR
	SELECT distinct
		Phase 
	FROM
		JCJP
	WHERE 
		JCCo=@JCCo 
	AND Job=@Job
	ORDER BY
		Phase
	FOR READ ONLY
	
	DECLARE @Phase VARCHAR(20)
	DECLARE @Mth AS datetime
	
	OPEN jpcur
	FETCH jpcur INTO @Phase

	--SELECT * FROM JCJM where Job IN (SELECT DISTINCT Job FROM JCJM WHERE Contract='080600-')
		
	WHILE @@fetch_status=0
	BEGIN
	
		--SELECT MAX(Mth) FROM JCCP WHERE JCCo=101 AND Job='080600-000' AND Phase='0131-1000-000000-000'
		--SELECT
		--	JCCo		
		--,	Job	
		--,	Phase	
		--,	Mth
		--,	COALESCE(SUM(ActualCost),0)		--numeric(12,2) NOT NULL 
		--,	COALESCE(SUM(OrigEstCost),0)		--numeric(12,2) NOT NULL 
		--,	COALESCE(SUM(CurrEstCost),0)		--numeric(12,2) NOT NULL 
		--,	COALESCE(SUM(ProjCost)	,0)	--numeric(12,2) NOT NULL 
		--,	COALESCE(SUM(ForecastCost),0)	--	numeric(12,2) NOT NULL 
		--,	COALESCE(SUM(TotalCmtdCost),0)	--	numeric(12,2) NOT NULL 
		--,	COALESCE(SUM(RemainCmtdCost),0)	--	numeric(12,2) NOT NULL 		
		--FROM
		--	JCCP
		--WHERE
		--	JCCo=101 AND Job='080600-000' AND Phase='0131-1000-000000-000'
		--AND Mth='2014-02-01'
		--GROUP BY
		--	JCCo
		--,	Job
		--,	Phase		
		--,	Mth
		PRINT @Job + ' - ' + @Phase
		
		SELECT @Mth = MAX(Mth) FROM JCCP WHERE JCCo=@JCCo AND Job=@Job AND Phase=@Phase
			
		INSERT @returnTable
		(
			JCCo		
		,	Job	
		,	Phase		
		,	Mth	
		,	ActualCost		--numeric(12,2) NOT NULL 
		,	OrigEstCost		--numeric(12,2) NOT NULL 
		,	CurrEstCost		--numeric(12,2) NOT NULL 
		,	ProjCost		--numeric(12,2) NOT NULL 
		,	ForecastCost	--	numeric(12,2) NOT NULL 
		,	TotalCmtdCost	--	numeric(12,2) NOT NULL 
		,	RemainCmtdCost	--	numeric(12,2) NOT NULL 
		)
		SELECT
			JCCo		
		,	Job	
		,	Phase	
		,	Mth
		,	COALESCE(SUM(ActualCost),0)		--numeric(12,2) NOT NULL 
		,	COALESCE(SUM(OrigEstCost),0)		--numeric(12,2) NOT NULL 
		,	COALESCE(SUM(CurrEstCost),0)		--numeric(12,2) NOT NULL 
		,	COALESCE(SUM(ProjCost)	,0)	--numeric(12,2) NOT NULL 
		,	COALESCE(SUM(ForecastCost),0)	--	numeric(12,2) NOT NULL 
		,	COALESCE(SUM(TotalCmtdCost),0)	--	numeric(12,2) NOT NULL 
		,	COALESCE(SUM(RemainCmtdCost),0)	--	numeric(12,2) NOT NULL 		
		FROM
			JCCP
		WHERE
			JCCo=@JCCo 
		AND Job=@Job 
		AND Phase=@Phase
		AND Mth=@Mth
		GROUP BY
			JCCo
		,	Job
		,	Phase		
		,	Mth
			
		SELECT @Mth=NULL
		
		FETCH jpcur INTO @Phase
	END
	
	CLOSE jpcur
	DEALLOCATE jpcur

	SELECT * FROM @returnTable
END
GO
