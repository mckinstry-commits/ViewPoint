-- Check for existance of records in JCPD ( JobCost Projection Batch Detail)
-- If records exist, dont attempt to populate.
-- If none exist, create appropriate records based on time distribution.

--Trigger: trIU_JCPB_GenDetail
-- Usage:  Fires when JC Cost Projections are created and distributes the "Remaining Amount" across x months in the future based
-- in the Projected End Month defined for the Job/Project (JCJM).  

-- Will only fire if Projection Batch Detail Records have not already
-- been created.  This allows users to adjust/update the generated details and not have them overwritten.

-- Question:  If the projection Final and/or Remaining are updated and the sum of the existing "Detail" records do not match ( maybe +/- by an acceptable amount),
-- should the projected amount be reprocessed and distributed evenly across the future months. 

-- Trigger will fire when a Job is added to a projection batch and any time a projection is updated on the "Info" tab.

--DELETE FROM JCPD WHERE Co=201 and BatchId=1

alter PROCEDURE mspJCCostProjectionForecast
(
	@Co			bCompany
,	@Mth		bMonth
,	@BatchId	bBatchID
,	@BatchSeq	int
,	@Job		bJob
,	@PhaseGroup bGroup
,	@Phase		bPhase
,	@CostType	bJCCType	
,	@ForceReforecast INT = 0
,	@Debug		INT = 0
)

AS

SET NOCOUNT ON

DECLARE @ProjFinalUnits bUnits
DECLARE @ActualCmtdUnits bUnits
DECLARE @RemainingUnits bUnits
DECLARE @ProjFinalHrs bHrs
DECLARE @ActualHours bHrs
DECLARE @RemainingHours bHrs
DECLARE @ProjFinalCost bDollar
DECLARE @ActualCmtdCost bDollar
DECLARE @RemainingCost bDollar

DECLARE @PrevProjectionExists INT 

DECLARE @RemainingUnitsVariance bUnits
DECLARE @RemainingHoursVariance bHrs
DECLARE @RemainingCostVariance bDollar

DECLARE @curJCPDUnitTotal bUnits
DECLARE @curJCPDHourTotal bHrs
DECLARE @curJCPDAmountTotal bDollar
						
DECLARE @JobStartDate bDate
DECLARE @JobEndDate bDate
DECLARE @ForecastStartDate bDate

DECLARE @JobStartMonth VARCHAR(7)
DECLARE @JobEndMonth VARCHAR(7)
DECLARE @ForecastStartMonth VARCHAR(7)

DECLARE @SpreadMonths INT
DECLARE @ForecastMonthCount int

DECLARE @ItemDescription bItemDesc
DECLARE @CostTypeCode VARCHAR(10)

DECLARE @UnitOfMeasure bUM


--Accomodate for null dates ( Will lump everything into current month. )
SELECT
	@JobStartDate = COALESCE(jcjm.udProjStart,CAST(CAST(MONTH(jccm.StartMonth) AS VARCHAR(2)) + '/1/' + CAST(YEAR(jccm.StartMonth) AS VARCHAR(4)) AS SMALLDATETIME),@Mth)
,	@JobEndDate = COALESCE(jcjm.udProjEnd, CAST(CAST(MONTH(jccm.ProjCloseDate) AS VARCHAR(2)) + '/1/' + CAST(YEAR(jccm.ProjCloseDate) AS VARCHAR(4)) AS SMALLDATETIME),@Mth )
FROM 
	JCJM jcjm JOIN
	JCCM jccm ON
		jcjm.JCCo=jccm.JCCo
	AND jcjm.Contract=jccm.Contract
	AND jcjm.Job=@Job
	AND jcjm.JCCo=@Co	
	
IF @Mth > @JobEndDate
BEGIN
	 RAISERROR ('Batch month cannot be past Job End Date.', -- Message text.
               16, -- Severity.
               1 -- State.
               );

END
ELSE
BEGIN
	DECLARE jccpcur CURSOR FOR
	SELECT
		Co
	,	Mth
	,	BatchId
	,	BatchSeq
	,	Job
	,	PhaseGroup
	,	Phase
	,	CostType
	,	ProjFinalUnits
	,	ActualCmtdUnits
	,	ProjFinalUnits-ActualCmtdUnits AS RemainingUnits
	,	ProjFinalHrs
	,	ActualHours
	,	ProjFinalHrs-ActualHours AS RemainingHours
	,	ProjFinalCost
	,	ActualCmtdCost
	,	ProjFinalCost-ActualCmtdCost AS RemainingCost
	FROM 
		JCPB -- will become "inserted" in trigger
	WHERE
		Co=@Co
	AND Mth=@Mth
	AND BatchId=@BatchId
	AND (BatchSeq=@BatchSeq OR @BatchSeq IS NULL)
	AND Job=@Job
	AND PhaseGroup=@PhaseGroup
	AND ( Phase=@Phase OR @Phase IS NULL)
	AND (CostType=@CostType OR @CostType IS NULL)
	ORDER BY
		Co
	,	Mth
	,	BatchId
	,	BatchSeq
	,	Job
	,	PhaseGroup
	,	Phase
	,	CostType
	FOR READ ONLY

	--SELECT @ForceReforecast=1

	IF @Debug=1
	BEGIN 
		PRINT
			CAST('CO' AS CHAR(5))
		+	cast('MONTH' AS CHAR(12))
		+	CAST('BATCH #' AS CHAR(10))
		+	CAST('SEQ #' AS CHAR(5))
		+	CAST('JOB #' AS CHAR(15))
		+	CAST('PHGP' AS CHAR(5))
		+	CAST('PHASE' AS CHAR(22))
		+	CAST('CSTYP' AS CHAR(10))	
		+	CAST('REM UNITS' AS CHAR(20))
		+	CAST('REM HRS' AS CHAR(20))
		+	CAST('REM COST' AS CHAR(20))
		+	cast('PROJ START' AS CHAR(12))
		+	cast('PROJ END' AS CHAR(12))

		PRINT REPLICATE('-',170)
	END	

	OPEN jccpcur
	FETCH jccpcur INTO
 		@Co
	,	@Mth
	,	@BatchId
	,	@BatchSeq
	,	@Job
	,	@PhaseGroup
	,	@Phase
	,	@CostType
	,	@ProjFinalUnits
	,	@ActualCmtdUnits
	,	@RemainingUnits
	,	@ProjFinalHrs
	,	@ActualHours
	,	@RemainingHours
	,	@ProjFinalCost
	,	@ActualCmtdCost
	,	@RemainingCost

	WHILE @@fetch_status=0
	BEGIN	
			
		IF @Mth > @JobStartDate
		BEGIN
			SELECT @ForecastStartDate=@Mth
		END
		ELSE
		BEGIN
			SELECT @ForecastStartDate=@JobStartDate
		END

		SELECT 
			@ForecastStartMonth=CAST(MONTH(@ForecastStartDate) AS VARCHAR(2)) + '/' + CAST(YEAR(@ForecastStartDate) AS VARCHAR(4))
		,	@JobStartMonth=CAST(MONTH(@JobStartDate) AS VARCHAR(2)) + '/' + CAST(YEAR(@JobStartDate) AS VARCHAR(4))
		,	@JobEndMonth=CAST(MONTH(@JobEndDate) AS VARCHAR(2)) + '/' + CAST(YEAR(@JobEndDate) AS VARCHAR(4))
		
		SELECT
			@CostTypeCode=COALESCE(Abbreviation,'X')
		FROM 
			JCCT
		WHERE 
			PhaseGroup=@PhaseGroup
		AND CostType=@CostType

		SELECT 
			@ItemDescription = COALESCE(Description,'Unknown') + ' [' + COALESCE(@CostTypeCode,'X') + ']'
		FROM 
			JCJP
		WHERE 
			JCCo=@Co
		AND Job=@Job 
		AND PhaseGroup=@PhaseGroup 
		AND Phase=@Phase

		-- Determine Number of Months to Spread "Remaining" values into the future
		SELECT @SpreadMonths = DATEDIFF(month,@ForecastStartDate,@JobEndDate)+1, @ForecastMonthCount=0

		SELECT 
			@UnitOfMeasure=COALESCE(UM,'LS')
		FROM 
			JCCH
		WHERE
			JCCo=@Co
		AND Job=@Job
		AND PhaseGroup=@PhaseGroup
		AND Phase=@Phase
		AND CostType=@CostType
		
		IF @Debug=1
		BEGIN 	
			PRINT
				CAST(@Co AS CHAR(5))
			+	cast(convert(varchar(10),@Mth,101) AS CHAR(12))
			+	CAST(@BatchId AS CHAR(10))
			+	CAST(@BatchSeq AS CHAR(5))
			+	CAST(@Job AS CHAR(15))
			+	CAST(@PhaseGroup AS CHAR(5))
			+	CAST(@Phase AS CHAR(22))
			+	CAST(@CostType AS CHAR(10))	
			+	CAST(@RemainingUnits AS CHAR(20))
			+	CAST(@RemainingHours AS CHAR(20))
			+	CAST(@RemainingCost AS CHAR(20))
			+	cast(convert(varchar(10),@JobStartDate,101) AS CHAR(12))
			+	cast(convert(varchar(10),@JobEndDate,101) AS CHAR(12))
			+	cast(@SpreadMonths AS CHAR(10))
			+	cast(@UnitOfMeasure AS CHAR(10))
		END
		--Prep Data for JCPD ( JobCost Projection Batch Detail )
		--SELECT * FROM JCPD


		SELECT @RemainingUnitsVariance = @RemainingUnits - ((CAST(@RemainingUnits / @SpreadMonths AS NUMERIC(12,3))) * @SpreadMonths )
		SELECT @RemainingHoursVariance = @RemainingHours - ((CAST(@RemainingHours / @SpreadMonths AS NUMERIC(12,2))) * @SpreadMonths )
		SELECT @RemainingCostVariance = @RemainingCost - ((CAST(@RemainingCost / @SpreadMonths AS NUMERIC(12,2))) * @SpreadMonths )
		
		-- Calculate other Detail Attributes for insert to Detail Records
		

		IF @Debug=1
		BEGIN 	
			PRINT 
				CAST(@RemainingUnitsVariance AS CHAR(20))
			+	CAST(@RemainingHoursVariance AS CHAR(20))
			+	CAST(@RemainingCostVariance AS CHAR(20))	
			
			PRINT ''		
			
			PRINT
				CAST('' AS CHAR(10))
			+	cast('MONTH' AS CHAR(12))
			+	CAST('UNITS' AS CHAR(20))
			+	CAST('HOURS' AS CHAR(20))
			+	CAST('COST' AS CHAR(20))
			
			PRINT 
				CAST('' AS CHAR(10))
			+	REPLICATE('-',80)
		END	

		-- Only Delete if there are not already records in JCPD ( allow manual updates to be made)
		IF EXISTS ( SELECT 1 FROM JCPD WHERE
				Co=@Co
			AND Mth=@Mth
			AND BatchId=@BatchId
			AND BatchSeq=@BatchSeq
			AND Job=@Job
			AND PhaseGroup=@PhaseGroup
			AND Phase=@Phase
			AND CostType=@CostType
		)
		BEGIN 
			DELETE [JCPD]  WHERE
				Co=@Co
			AND Mth=@Mth
			AND BatchId=@BatchId
			AND BatchSeq=@BatchSeq
			AND Job=@Job
			AND PhaseGroup=@PhaseGroup
			AND Phase=@Phase
			AND CostType=@CostType
		END		
		
		BEGIN 
		SELECT 
			@PrevProjectionExists=COUNT(*) 
		FROM 
			JCPR jcpr 
		WHERE 	
			jcpr.JCCo=@Co 
		--AND jcpr.DetMth=DATEADD(MONTH,@ForecastMonthCount-1,@ForecastStartDate)
		AND jcpr.Job=@Job
		AND jcpr.PhaseGroup=@PhaseGroup
		AND jcpr.Phase=@Phase
		AND jcpr.CostType=@CostType

		-- If ForceReforecast is set, make logic think there is no previous projection.
		IF  @ForceReforecast <> 0
			SELECT @PrevProjectionExists=0
			
		WHILE @ForecastMonthCount < @SpreadMonths
		BEGIN
			IF @Debug=1
			BEGIN 		
				PRINT
					CAST('' AS CHAR(10))
				+	cast(convert(varchar(10),DATEADD(MONTH,@ForecastMonthCount,@ForecastStartDate),101) AS CHAR(12))
				+	CAST(CAST(@RemainingUnits / @SpreadMonths AS NUMERIC(12,3)) AS CHAR(20))
				+	CAST(cast(@RemainingHours / @SpreadMonths AS NUMERIC(12,2)) AS CHAR(20))
				+	CAST(cast(@RemainingCost / @SpreadMonths AS NUMERIC(12,2)) AS CHAR(20))
				+	CAST(@ForecastMonthCount AS VARCHAR(10)) + '/'
				+	CAST(@SpreadMonths AS CHAR(10))
				+   @ItemDescription
			END 
				
			-- Check for Entry from Previous Projection
			IF @PrevProjectionExists > 0
			BEGIN
				--IF @Debug=1
				--	PRINT 'Previous Projection Data exists'
				
				IF @ForecastMonthCount = ( @SpreadMonths -1 )
				BEGIN
					-- Last Entry to adjust value to be difference between sum of created entries and root projection total
					SELECT 
						@curJCPDUnitTotal = SUM(jcpd.Units)
					,	@curJCPDHourTotal = SUM(jcpd.Hours)
					,	@curJCPDAmountTotal = SUM(jcpd.Amount)
					FROM
						JCPD jcpd
					WHERE
						jcpd.Co=@Co 
					--AND jcpr.DetMth=DATEADD(MONTH,@ForecastMonthCount,@ForecastStartDate)
					AND jcpd.Job=@Job
					AND jcpd.PhaseGroup=@PhaseGroup
					AND jcpd.Phase=@Phase
					AND jcpd.CostType=@CostType					
				END
				ELSE
				BEGIN
					SELECT 
						@curJCPDUnitTotal = 0.000
					,	@curJCPDHourTotal = 0.00
					,	@curJCPDAmountTotal = 0.00
				END
					
				IF EXISTS ( SELECT 1 FROM 
								JCPR jcpr 
							WHERE 	
								jcpr.JCCo=@Co 
							AND jcpr.DetMth=DATEADD(MONTH,@ForecastMonthCount,@ForecastStartDate)
							AND jcpr.Job=@Job
							AND jcpr.PhaseGroup=@PhaseGroup
							AND jcpr.Phase=@Phase
							AND jcpr.CostType=@CostType )
				BEGIN
					--Use Previous Projection Values


					BEGIN
						INSERT INTO [JCPD] 
						(	[Co]
						,	[Mth]
						,	[BatchId]
						,	[BatchSeq]
						,	[DetSeq]
						,	[Source]
						,	[JCTransType]
						,	[TransType]
						,	[ResTrans]
						,	[Job]
						,	[PhaseGroup]
						,	[Phase]
						,	[CostType]
						,	[Description]
						,	[DetMth]
						,	[UM]
						,	[Units]
						,	[Hours]
						--,	[UnitCost]
						,	[Amount]
						,	[Notes]
						,	OldTransType, OldJob, OldPhaseGroup, OldPhase, OldCostType, OldBudgetCode, OldEMCo,
							OldEquipment, OldPRCo, OldCraft, OldClass, OldEmployee, OldDescription, OldDetMth,
							OldFromDate, OldToDate, OldQuantity, OldUM, OldUnits, OldUnitHours, OldHours,
							OldRate, OldUnitCost, OldAmount, UniqueAttchID							
						)
						
						--SELECT * FROM JCPD WHERE Job='999049-001'
						
						SELECT TOP 1
							jcpr.JCCo
						,	@Mth
						,	@BatchId
						,	@BatchSeq
						,	@ForecastMonthCount + 1
						,	'JC Projctn'
						,	'PF'
						,	'C'
						,	jcpr.ResTrans
						,	jcpr.Job
						,	jcpr.PhaseGroup
						,	jcpr.Phase
						,	jcpr.CostType
						,	jcpr.Description
						,	jcpr.DetMth
						,	jcpr.UM
						,	CASE
								WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN @RemainingUnits - @curJCPDUnitTotal
								ELSE jcpr.Units
							END
						,	CASE
								WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN @RemainingHours - @curJCPDHourTotal
								ELSE jcpr.Hours
							END
						--,	CASE
						--		WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN @RemainingAmount - @curJCPDAmountTotal
						--		ELSE jcpr.Amount
						--	END
						,	CASE
								WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN @RemainingCost - @curJCPDAmountTotal
								ELSE jcpr.Amount
							END
						,	jcpr.Notes
						,	ResTrans, Job, PhaseGroup, Phase, CostType,
							BudgetCode, EMCo, Equipment, PRCo, Craft, Class, Employee, Description, DetMth,
							FromDate, ToDate, Quantity, UM, Units, UnitHours, Hours, Rate, UnitCost, Amount,
							UniqueAttchID
						FROM 
							JCPR jcpr
						WHERE
							jcpr.JCCo=@Co 
						AND jcpr.DetMth=DATEADD(MONTH,@ForecastMonthCount,@ForecastStartDate)
						AND jcpr.Job=@Job
						AND jcpr.PhaseGroup=@PhaseGroup
						AND jcpr.Phase=@Phase
						AND jcpr.CostType=@CostType	
						ORDER BY 
							jcpr.Mth DESC
						
						--SELECT
						--	*
						--FROM 
						--	JCPR jcpr
						--WHERE
						--	jcpr.JCCo=201 
						--AND jcpr.DetMth='2014-08-01 00:00:00'
						--AND jcpr.Job='999049-001'
						--AND jcpr.PhaseGroup=101
						--AND jcpr.Phase='2200-7000-      -'
						--AND jcpr.CostType=1	
						
					END
				END
				ELSE
				BEGIN
					--Load record for missing months in previous projection with zero values.
					INSERT INTO [JCPD] 
					(	[Co]
					,	[Mth]
					,	[BatchId]
					,	[BatchSeq]
					,	[DetSeq]
					,	[Source]
					,	[JCTransType]
					,	[TransType]
					,	[ResTrans]
					,	[Job]
					,	[PhaseGroup]
					,	[Phase]
					,	[CostType]
					,	[Description]
					,	[DetMth]
					,	[UM]
					,	[Units]
					,	[Hours]
					--,	[UnitCost]
					,	[Amount]
					,	[Notes]
					)
					SELECT  
						@Co
					,	@Mth
					,	@BatchId
					,	@BatchSeq
					,	@ForecastMonthCount + 1
					,	'JC Projctn'
					,	'PF'
					,	'A'
					,	null --<ResTrans, bTrans,>
					,	@Job
					,	@PhaseGroup
					,	@Phase
					,	@CostType
					,	@ItemDescription
					,	DATEADD(MONTH,@ForecastMonthCount,@ForecastStartDate)
					,	@UnitOfMeasure 
					,	CASE
								WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN @RemainingUnits - @curJCPDUnitTotal
								ELSE 0.000
							END
						,	CASE
								WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN @RemainingHours - @curJCPDHourTotal
								ELSE 0.00
							END
						--,	CASE
						--		WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN @RemainingAmount - @curJCPDAmountTotal
						--		ELSE 0.00
						--	END
						,	CASE
								WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN @RemainingCost - @curJCPDAmountTotal
								ELSE 0.00
							END	
					,	@ItemDescription + ' Cost Projection from ' + @ForecastStartMonth + ' through ' + @JobEndMonth						
				END
			END 
			ELSE
			BEGIN
				IF @Debug=1
					PRINT 'Previous Projection Data does not exist'
				--Use Standard Flatline Distribution
				INSERT INTO [JCPD] 
				(	[Co]
				,	[Mth]
				,	[BatchId]
				,	[BatchSeq]
				,	[DetSeq]
				,	[Source]
				,	[JCTransType]
				,	[TransType]
				,	[ResTrans]
				,	[Job]
				,	[PhaseGroup]
				,	[Phase]
				,	[CostType]
				,	[Description]
				,	[DetMth]
				,	[UM]
				,	[Units]
				,	[Hours]
				--,	[UnitCost]
				,	[Amount]
				,	[Notes]
				)
				SELECT  
					@Co
				,	@Mth
				,	@BatchId
				,	@BatchSeq
				,	@ForecastMonthCount + 1
				,	'JC Projctn'
				,	'PF'
				,	'A'
				,	null --<ResTrans, bTrans,>
				,	@Job
				,	@PhaseGroup
				,	@Phase
				,	@CostType
				,	@ItemDescription
				,	DATEADD(MONTH,@ForecastMonthCount,@ForecastStartDate)
				,	@UnitOfMeasure
				,	CASE
						WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN (CAST(@RemainingUnits / @SpreadMonths AS NUMERIC(12,3))) + @RemainingUnitsVariance
						else CAST(@RemainingUnits / @SpreadMonths AS NUMERIC(12,3))
					END
				,	CASE
						WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN (CAST(@RemainingHours / @SpreadMonths AS NUMERIC(12,2))) + @RemainingHoursVariance
						else CAST(@RemainingHours / @SpreadMonths AS NUMERIC(12,2))
					END
				--,	CASE
				--		WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN (CAST(@RemainingCost / @SpreadMonths AS NUMERIC(12,2))) + @RemainingCostVariance
				--		else CAST(@RemainingCost / @SpreadMonths AS NUMERIC(12,2))
				--	END			
				,	CASE
						WHEN @ForecastMonthCount = ( @SpreadMonths -1 ) THEN (CAST(@RemainingCost / @SpreadMonths AS NUMERIC(12,2))) + @RemainingCostVariance
						else CAST(@RemainingCost / @SpreadMonths AS NUMERIC(12,2))
					END	
				,	@ItemDescription + ' Cost Projection from ' + @ForecastStartMonth + ' through ' + @JobEndMonth				
			END
			
			--SELECT 
			
			--FROM 
			--	JCPR
			--WHERE
			--	JCCo=@Co 
			--AND 
			
			


			/*
			UPDATE JCPD SET
				Amount=jcpr.Amount
			,	Units=jcpr.Units
			,	UnitHours=jcpr.UnitHours
			,	Hours=jcpr.Hours
			,	Rate=jcpr.Rate
			,	UnitCost=jcpr.UnitCost
			,	UM=jcpr.UM
			,	Description=jcpr.Description
			,	Notes=jcpr.Notes		
			FROM 
				JCPR jcpr
			WHERE
				jcpr.JCCo=@Co 
			AND jcpr.DetMth=DATEADD(MONTH,@ForecastMonthCount,@ForecastStartDate)
			AND jcpr.Job=@Job
			AND jcpr.PhaseGroup=@PhaseGroup
			AND jcpr.Phase=@Phase
			AND jcpr.CostType=@CostType
			*/
						
			
			
			
			SELECT @ForecastMonthCount = @ForecastMonthCount + 1
		END
			
		IF @Debug=1
		BEGIN 	
			PRINT ''
		END




		SELECT @ForecastMonthCount=0,	@UnitOfMeasure=null
		
		--TODO: Potential Future Enhancement
		--Update Forecast Table with Results of Projection
		--SELECT * FROM dbo.JCForecastMonth WHERE JCCo=201 AND Contract='999049-'
		
		END

		FETCH jccpcur INTO
 			@Co
		,	@Mth
		,	@BatchId
		,	@BatchSeq
		,	@Job
		,	@PhaseGroup
		,	@Phase
		,	@CostType
		,	@ProjFinalUnits
		,	@ActualCmtdUnits
		,	@RemainingUnits
		,	@ProjFinalHrs
		,	@ActualHours
		,	@RemainingHours
		,	@ProjFinalCost
		,	@ActualCmtdCost
		,	@RemainingCost

	END 

	CLOSE jccpcur
	DEALLOCATE jccpcur
END
GO



alter TRIGGER trIU_JCPB_GenDetail 
   ON  bJCPB
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE jcpbcur CURSOR for
	SELECT Co, Mth, BatchId, BatchSeq, Job, PhaseGroup, Phase, CostType,Plugged FROM inserted ORDER BY Co, Mth, BatchId, BatchSeq, Job, PhaseGroup, Phase, CostType FOR READ ONLY

	declare @trCo			bCompany
	declare @trMth			bMonth
	declare @trBatchId		bBatchID
	declare @trBatchSeq		int
	declare @trJob			bJob
	declare @trPhaseGroup	bGroup
	declare @trPhase		bPhase
	declare @trCostType		bJCCType	
	declare @trPlugged		bYN	
	
	OPEN jcpbcur
	FETCH jcpbcur INTO
		@trCo			--bCompany
	,	@trMth			--bMonth
	,	@trBatchId		--bBatchID
	,	@trBatchSeq		--int
	,	@trJob			--bJob
	,	@trPhaseGroup	--bGroup
	,	@trPhase		--bPhase
	,	@trCostType		--bJCCType	
	,	@trPlugged		--bYN
	
	WHILE @@fetch_status=0
	BEGIN
		IF @trPlugged <> 'Y'  -- Only reclaculate the detail breakout if the detail has not already been plugged.
		BEGIN
			EXEC dbo.mspJCCostProjectionForecast
				@Co			=@trCo
			,	@Mth		=@trMth
			,	@BatchId	=@trBatchId
			,	@BatchSeq	=@trBatchSeq
			,	@Job		=@trJob
			,	@PhaseGroup =@trPhaseGroup
			,	@Phase		=@trPhase
			,	@CostType	=@trCostType
			,	@Debug=0
		END
		
		FETCH jcpbcur INTO
			@trCo			--bCompany
		,	@trMth			--bMonth
		,	@trBatchId		--bBatchID
		,	@trBatchSeq		--int
		,	@trJob			--bJob
		,	@trPhaseGroup	--bGroup
		,	@trPhase		--bPhase
		,	@trCostType		--bJCCType	
		,	@trPlugged		--bYN
	END
	
	CLOSE jcpbcur	
	DEALLOCATE jcpbcur	

END
GO

/*
EXEC mspJCCostProjectionForecast
	@Co			=101
,	@Mth		='8/1/2014'
,	@BatchId	=25
,	@BatchSeq	=null
,	@Job		='  1004-'
,	@PhaseGroup =101
,	@Phase		=null--'0100-0210-000000-000'
,	@CostType	=2
,	@Debug=1
*/

/*
EXEC mspJCCostProjectionForecast
	@Co			=101
,	@Mth		='10/1/2014'
,	@BatchId	=3
,	@BatchSeq	=null
,	@Job		='080600-004'
,	@PhaseGroup =101
,	@Phase		=null--'0100-0210-000000-000'
,	@CostType	=NULL
,	@Debug=1
*/




/*
EXEC mspJCCostProjectionForecast
	@Co			=101
,	@Mth		='10/1/2014'
,	@BatchId	=3
,	@BatchSeq	=null
,	@Job		='  2083-'
,	@PhaseGroup =101
,	@Phase		=null
,	@CostType	=NULL
,	@ForceReforecast=0
,	@Debug=1
*/



--SELECT * FROM JCPB WHERE BatchId=1 AND Co=201


--SELECT 
--	* 
--FROM 
--	[JCPD] 
--WHERE 
--	Co=201 
--AND Job='999049-001' 
--AND PhaseGroup=101 
--AND Phase='2200-1110-      -' 
--AND CostType=1
--AND DetMth='8/1/2014'
--ORDER BY KeyID DESC

--SELECT * FROM [JCPD] WHERE BatchId=16 AND BatchSeq=1

--sp_depends JCPD

--SELECT 
--	* 
--FROM 
--	JCPR 
--WHERE 
--	JCCo=201 
--AND Job='999049-001' 
--AND PhaseGroup=101 
--AND Phase='2200-1110-      -' 
--AND CostType=1
--AND DetMth='8/1/2014'
--ORDER BY KeyID DESC

--SELECT * FROM JCCH

----sp_helptext JCPBCalculations
--sp_depends JCPBCalculations
--select * from JCPBCalculations where BatchId=16
--sp_helptext vspJCPDInsertExisting