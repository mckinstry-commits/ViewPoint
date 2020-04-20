USE Viewpoint 
GO

SET NOCOUNT ON 
DECLARE @doSQL INT

--Set this to non-zero to allow actual inserts to occur.
SELECT @doSQL=0

BEGIN TRAN

DECLARE cur CURSOR FOR
SELECT DISTINCT 
	jcjm.JCCo
,	jcjm.Job	
--,	jcjp.PhaseGroup
--,	jcjp.Phase
--,	jcch.CostType
--,	jcch.OrigCost
--,	jcch.OrigUnits
--,	jcch.OrigHours
FROM 
	dbo.SMServiceSite smsite
JOIN JCJM jcjm ON
	jcjm.JCCo=smsite.JCCo
AND jcjm.Job=smsite.Job
AND jcjm.JobStatus < 4
--JOIN JCJP jcjp ON
--	jcjp.JCCo=jcjm.JCCo
--AND jcjp.Job=jcjm.Job
--JOIN JCCH jcch ON
--	jcjp.JCCo=jcch.JCCo
--AND jcjp.Job=jcch.Job	
--AND jcjp.PhaseGroup=jcch.PhaseGroup
--AND jcjp.Phase=jcch.Phase
WHERE
(	smsite.JCCo IS NOT NULL
AND smsite.Job IS NOT NULL)
OR smsite.Type='Job'
ORDER BY
	jcjm.JCCo
,	jcjm.Job	
--,	jcjp.PhaseGroup
--,	jcjp.Phase
--,	jcch.CostType
FOR READ ONLY

DECLARE @pcnt			INT
DECLARE @ccnt			int
DECLARE	@JCCo			bCompany
DECLARE	@Job			bJob
DECLARE	@PhaseGroup		bGroup
DECLARE	@Phase			bPhase
DECLARE	@CostType		bJCCType
DECLARE	@OrigCost		bDollar
DECLARE	@OrigUnits		bUnits
DECLARE	@OrigHours		bHrs

DECLARE @PrtMsg			VARCHAR(4000)
DECLARE @PhaseDesc		bDesc
DECLARE @Contract		bContract
DECLARE @Item			bContractItem

select @pcnt=0,@ccnt=0

OPEN cur
FETCH cur INTO
	@JCCo			--bCompany
,	@Job			--bJob
--,	@PhaseGroup		--bGroup
--,	@Phase			--bPhase
--,	@CostType		--bJCCType
--,	@OrigCost		--bDollar
--,	@OrigUnits		--bUnits
--,	@OrigHours		--bHrs

WHILE @@FETCH_STATUS=0
BEGIN
	SELECT @PrtMsg  = 
		CAST(COALESCE(@JCCo,0) AS CHAR(5))			--bCompany
	+	CAST(COALESCE(@Job,'') AS CHAR(12))			--bJob
	--+	CAST(COALESCE(@PhaseGroup,'') AS CHAR(5))		--bGroup
	--+	CAST(COALESCE(@Phase,'') AS CHAR(25))			--bPhase
	--+	CAST(COALESCE(@CostType,'') AS CHAR(5))		--bJCCType
	--+	CAST(COALESCE(@OrigCost,0) AS CHAR(20))		--bDollar
	--+	CAST(COALESCE(@OrigUnits,0) AS CHAR(20))		--bUnits
	--+	CAST(COALESCE(@OrigHours,0) AS CHAR(20))		--bHrs
	
	SELECT @PhaseGroup=PhaseGroup FROM HQCO WHERE HQCo=@JCCo
	SELECT @Contract=Contract FROM JCJM WHERE JCCo=@JCCo AND Job=@Job
	SELECT @Item=MIN(Item) FROM JCCI WHERE JCCo=@JCCo AND Contract=@Contract 
	
	IF @Item IS NOT NULL
	BEGIN
	--SELECT MIN(Item) FROM JCCI WHERE JCCo=@JCCo AND Contract=@Contract 

	-- DO Phase '2100-0000-      -   ' Cost Type 2
	SELECT 
		@Phase=Phase
	,	@PhaseDesc=Description
	,	@CostType=2 
	FROM JCPM WHERE PhaseGroup=@PhaseGroup AND Phase='2100-0000-      -   '

	IF NOT EXISTS ( SELECT 1 FROM JCJP jcjp WHERE jcjp.JCCo=@JCCo AND jcjp.Job=@Job AND jcjp.Phase=@Phase)
	BEGIN
		SELECT @pcnt=@pcnt+1, @ccnt=@ccnt+1 

		PRINT @PrtMsg + ' ... ' + @Phase + ' : Missing ' + '(' + @Contract + ':' + CAST(COALESCE(@Item,'XX') AS CHAR(20)) + ') '

		IF @doSQL<>0
		BEGIN				
			INSERT JCJP ( JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN, udConv )
			VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @PhaseDesc, @Contract, @Item, 0.0000, 'Y', 'N')
		
			INSERT JCCH ( JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, BuyOutYN, Plugged, ActiveYN, OrigUnits, OrigHours, OrigCost, SourceStatus, udConv )
			VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @CostType, 'LS', 'Y', 'N', 'N','N','N','Y',0.00,0.00,0.00, 'J','N')
		END
		
	END
	ELSE
    BEGIN
		--PRINT @PrtMsg + ' ... ' + '2100-0000-      -   ' + ' : Exists '
		IF NOT EXISTS ( SELECT 1 FROM JCCH jcch WHERE jcch.JCCo=@JCCo AND jcch.Job=@Job AND jcch.PhaseGroup=@PhaseGroup AND jcch.Phase=@Phase AND jcch.CostType=@CostType )
		BEGIN
			SELECT @ccnt=@ccnt+1 
			PRINT @PrtMsg + ' ... ' + @Phase + ' : Exists ' + ' ... Cost Type ' + CAST(@CostType AS varchar(5)) + ' : Missing'

			IF @doSQL<>0
			BEGIN				
				INSERT JCCH ( JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, BuyOutYN, Plugged, ActiveYN, OrigUnits, OrigHours, OrigCost, SourceStatus, udConv )
				VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @CostType, 'LS', 'Y', 'N', 'N','N','N','Y',0.00,0.00,0.00, 'J','N')
			END

		END
		--ELSE
  --      BEGIN			
		--	PRINT @PrtMsg + ' ... ' + '2100-0000-      -   ' + ' : Exists ' + ' ... Cost Type 2 : Exists'
		--END
	END

	-- DO Phase '2300-0000-      -   ' Cost Type 2
	SELECT 
		@Phase=Phase
	,	@PhaseDesc=Description
	,	@CostType=2 
	FROM JCPM WHERE PhaseGroup=@PhaseGroup AND Phase='2300-0000-      -   '

	IF NOT EXISTS ( SELECT 1 FROM JCJP jcjp WHERE jcjp.JCCo=@JCCo AND jcjp.Job=@Job AND jcjp.Phase=@Phase)
	BEGIN
		SELECT @pcnt=@pcnt+1, @ccnt=@ccnt+1		

		PRINT @PrtMsg + ' ... ' + @Phase + ' : Missing '+ '(' + @Contract + ':' + CAST(COALESCE(@Item,'XX') AS CHAR(20)) + ') '
		IF @doSQL<>0
		BEGIN				
			INSERT JCJP ( JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN, udConv )
			VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @PhaseDesc, @Contract, @Item, 0.0000, 'Y', 'N')
		
			INSERT JCCH ( JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, BuyOutYN, Plugged, ActiveYN, OrigUnits, OrigHours, OrigCost, SourceStatus, udConv )
			VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @CostType, 'LS', 'Y', 'N', 'N','N','N','Y',0.00,0.00,0.00, 'J','N')
		END		
		
	END
	ELSE
    BEGIN
		--PRINT @PrtMsg + ' ... ' + '2100-0000-      -   ' + ' : Exists '
		IF NOT EXISTS ( SELECT 1 FROM JCCH jcch WHERE jcch.JCCo=@JCCo AND jcch.Job=@Job AND jcch.PhaseGroup=@PhaseGroup AND jcch.Phase=@Phase AND jcch.CostType=@CostType )
		BEGIN
			SELECT @ccnt=@ccnt+1 
			PRINT @PrtMsg + ' ... ' + @Phase + ' : Exists ' + ' ... Cost Type ' + CAST(@CostType AS varchar(5)) + ' : Missing'

			IF @doSQL<>0
			BEGIN			
				INSERT JCCH ( JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, BuyOutYN, Plugged, ActiveYN, OrigUnits, OrigHours, OrigCost, SourceStatus, udConv )
				VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @CostType, 'LS', 'Y', 'N', 'N','N','N','Y',0.00,0.00,0.00, 'J','N')
			END	
		
		END
		--ELSE
  --      BEGIN			
		--	PRINT @PrtMsg + ' ... ' + '2100-0000-      -   ' + ' : Exists ' + ' ... Cost Type 2 : Exists'
		--END
	END

	-- DO Phase '2300-0000-      -   ' Cost Type 3
	SELECT 
		@Phase=Phase
	,	@PhaseDesc=Description
	,	@CostType=3 
	FROM JCPM WHERE PhaseGroup=@PhaseGroup AND Phase='2300-0000-      -   '

	IF NOT EXISTS ( SELECT 1 FROM JCJP jcjp WHERE jcjp.JCCo=@JCCo AND jcjp.Job=@Job AND jcjp.Phase=@Phase)
	BEGIN
		SELECT @pcnt=@pcnt+1, @ccnt=@ccnt+1 

		PRINT @PrtMsg + ' ... ' + @Phase + ' : Missing '+ '(' + @Contract + ':' + CAST(COALESCE(@Item,'XX') AS CHAR(20)) + ') '
		
		IF @doSQL<>0
		BEGIN		
			INSERT JCJP ( JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN, udConv )
			VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @PhaseDesc, @Contract, @Item, 0.0000, 'Y', 'N')
		
			INSERT JCCH ( JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, BuyOutYN, Plugged, ActiveYN, OrigUnits, OrigHours, OrigCost, SourceStatus, udConv )
			VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @CostType, 'LS', 'Y', 'N', 'N','N','N','Y',0.00,0.00,0.00, 'J','N')
		END		
		
	END
	ELSE
    BEGIN
		--PRINT @PrtMsg + ' ... ' + '2100-0000-      -   ' + ' : Exists '
		IF NOT EXISTS ( SELECT 1 FROM JCCH jcch WHERE jcch.JCCo=@JCCo AND jcch.Job=@Job AND jcch.PhaseGroup=@PhaseGroup AND jcch.Phase=@Phase AND jcch.CostType=@CostType )
		BEGIN
			SELECT @ccnt=@ccnt+1 
			PRINT @PrtMsg + ' ... ' + @Phase + ' : Exists ' + ' ... Cost Type ' + CAST(@CostType AS varchar(5)) + ' : Missing'

			IF @doSQL<>0
			BEGIN			
				INSERT JCCH ( JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, BuyOutYN, Plugged, ActiveYN, OrigUnits, OrigHours, OrigCost, SourceStatus, udConv )
				VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @CostType, 'LS', 'Y', 'N', 'N','N','N','Y',0.00,0.00,0.00, 'J','N')
			END			

		END
		--ELSE
  --      BEGIN			
		--	PRINT @PrtMsg + ' ... ' + '2100-0000-      -   ' + ' : Exists ' + ' ... Cost Type 2 : Exists'
		--END
	END

	-- DO Phase '0100-0500-      -   ' Cost Type 4
	SELECT 
		@Phase=Phase
	,	@PhaseDesc=Description
	,	@CostType=4 
	FROM JCPM WHERE PhaseGroup=@PhaseGroup AND Phase='0100-0500-      -   '

	IF NOT EXISTS ( SELECT 1 FROM JCJP jcjp WHERE jcjp.JCCo=@JCCo AND jcjp.Job=@Job AND jcjp.Phase=@Phase)
	BEGIN
		SELECT @pcnt=@pcnt+1, @ccnt=@ccnt+1 

		PRINT @PrtMsg + ' ... ' + @Phase + ' : Missing '+ '(' + @Contract + ':' + CAST(COALESCE(@Item,'XX') AS CHAR(20)) + ') '
		
		IF @doSQL<>0
		BEGIN		
			INSERT JCJP ( JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN, udConv )
			VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @PhaseDesc, @Contract, @Item, 0.0000, 'Y', 'N')
		
			INSERT JCCH ( JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, BuyOutYN, Plugged, ActiveYN, OrigUnits, OrigHours, OrigCost, SourceStatus, udConv )
			VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @CostType, 'LS', 'Y', 'N', 'N','N','N','Y',0.00,0.00,0.00, 'J','N')
		END		
		
	END
	ELSE
    BEGIN
		--PRINT @PrtMsg + ' ... ' + '2100-0000-      -   ' + ' : Exists '
		IF NOT EXISTS ( SELECT 1 FROM JCCH jcch WHERE jcch.JCCo=@JCCo AND jcch.Job=@Job AND jcch.PhaseGroup=@PhaseGroup AND jcch.Phase=@Phase AND jcch.CostType=@CostType )
		BEGIN
			SELECT @ccnt=@ccnt+1 
			PRINT @PrtMsg + ' ... ' + @Phase + ' : Exists ' + ' ... Cost Type ' + CAST(@CostType AS varchar(5)) + ' : Missing'

			IF @doSQL<>0
			BEGIN			
				INSERT JCCH ( JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, BuyOutYN, Plugged, ActiveYN, OrigUnits, OrigHours, OrigCost, SourceStatus, udConv )
				VALUES ( @JCCo, @Job, @PhaseGroup, @Phase, @CostType, 'LS', 'Y', 'N', 'N','N','N','Y',0.00,0.00,0.00, 'J','N')
			END			

		END
		--ELSE
  --      BEGIN			
		--	PRINT @PrtMsg + ' ... ' + '2100-0000-      -   ' + ' : Exists ' + ' ... Cost Type 2 : Exists'
		--END
	END


		--JCJP jcjp JOIN JCCH jcch ON jcjp.JCCo=jcch.JCCo AND jcjp.Job=jcch.Job AND jcjp.PhaseGroup=jcch.PhaseGroup AND jcjp.Phase=jcch.Phase AND jcjp.Pha
	END 
	ELSE
    BEGIN 
		PRINT @PrtMsg + ' : No Contract Item Defined'
	END 

SELECT
	@JCCo			=NULL --bCompany
,	@Job			=NULL --bJob
,	@PhaseGroup		=NULL --bGroup
,	@Phase			=NULL --bPhase
,	@CostType		=NULL --bJCCType
,	@OrigCost		=NULL --bDollar
,	@OrigUnits		=NULL --bUnits
,	@OrigHours		=NULL --bHr
,	@PrtMsg			=NULL --VARCHAR(4000)
,	@PhaseDesc		=NULL --bDesc
,	@Contract		=NULL --bContract
,	@Item			=NULL --bContractItem

	FETCH cur INTO
		@JCCo			--bCompany
	,	@Job			--bJob
	--,	@PhaseGroup		--bGroup
	--,	@Phase			--bPhase
	--,	@CostType		--bJCCType
	--,	@OrigCost		--bDollar
	--,	@OrigUnits		--bUnits
	--,	@OrigHours		--bHrs

END

PRINT ''

PRINT CAST(@pcnt AS VARCHAR(20)) + ' JCJP Records Added'
PRINT CAST(@ccnt AS VARCHAR(20)) + ' JCCH Records Added'


COMMIT TRAN

CLOSE cur
DEALLOCATE cur

GO


--SELECT * FROM JCJP WHERE JCCo=1 AND Job='10006-001'and Phase='2100-0000-      -   '


--SELECT * FROM JCCI WHERE JCCo=1 AND Contract = ' 10107-'