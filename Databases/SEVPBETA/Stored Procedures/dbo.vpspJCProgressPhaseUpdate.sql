SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 2/22/10
-- Updated:
--		 CJG 5/12/2010: Issue 131369 - Change TotalPercentage data type to allow percentage values.  bPct is for decimal percentages.
--                                   - Added checks to set @PeriodComplete, @CompleteToDate or @TotalPercentage to 0 if passed in as null
--									 - Added check to ensure TotalPercentage updated in JCPP doesn't exceed max field value of 99.9999
--       CJG 5/04/2010: Issue 131369 - Eliminate divide by zero errors.
--
-- Description:	Update a Phase in a JC Progress Entry batch
-- =============================================
CREATE PROCEDURE [dbo].[vpspJCProgressPhaseUpdate]
	@Key_JCCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, 
	@Key_BatchSeq AS int, @VPUserName AS bVPUserName,
	@PeriodComplete AS bUnits, @CompleteToDate AS bUnits, @TotalPercentage AS numeric(38,4)
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Batch is Open Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_JCCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND [Status] = 0)
	BEGIN
		RAISERROR('Cannot update. Batch is not in the Open status.', 16, 1)
		GOTO vspExit
	END
	
	-- Batch Locked Validation
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQBC (NOLOCK) WHERE Co = @Key_JCCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND InUseBy = @VPUserName)
	BEGIN
		RAISERROR('You must first lock the batch before you can update progress', 16, 1)
		GOTO vspExit
	END
	
	-- Convert null values to 0
	IF @PeriodComplete IS NULL
		BEGIN
			SET @PeriodComplete = 0
		END
	
	IF @CompleteToDate IS NULL
		BEGIN
			SET @CompleteToDate = 0
		END
	
	IF @TotalPercentage IS NULL
		BEGIN
			SET @TotalPercentage = 0
		END
	
	SET @TotalPercentage = @TotalPercentage / 100.0	
		
	DECLARE @PreviousPeriodComplete bUnits
	DECLARE @PreviousCompleteToDate bUnits
	DECLARE @PreviousTotalPerc numeric(38,4)
	DECLARE @CurrentCompleted bUnits
	DECLARE @CurrentProjected bUnits
	DECLARE @CurrentEstimated bUnits
	DECLARE @TotalCompletedUnits bUnits
	DECLARE @Plugged bYN
	
	-- Get previous values and such to determing what fields changed and do calculations
	SELECT @PreviousPeriodComplete = JCPP.ActualUnits
		  ,@PreviousCompleteToDate = (JCPP.ActualUnits + dtl.CurrentCompleted)
		  ,@PreviousTotalPerc = JCPP.ProgressCmplt
		  ,@CurrentCompleted = dtl.CurrentCompleted
		  ,@CurrentProjected = dtl.CurrentProjected
		  ,@CurrentEstimated = dtl.CurrentEstimated
		  ,@Plugged = JCCH.Plugged
	FROM JCPP	
		left join JCCH JCCH with (nolock) on JCCH.JCCo = JCPP.Co and JCCH.Job = JCPP.Job and JCCH.PhaseGroup = JCPP.PhaseGroup and JCCH.Phase = JCPP.Phase and JCCH.CostType = JCPP.CostType
		left join JCPPJCCD dtl with (nolock) on dtl.Co=JCPP.Co and dtl.Mth=JCPP.Mth and dtl.BatchId=JCPP.BatchId
		and dtl.BatchSeq=JCPP.BatchSeq and dtl.Job=JCPP.Job and dtl.PhaseGroup=JCPP.PhaseGroup
		and dtl.Phase=JCPP.Phase and dtl.CostType=JCPP.CostType
	WHERE
		JCPP.Co = @Key_JCCo AND
		JCPP.BatchId = @Key_BatchId AND
		JCPP.Mth = @Key_Mth AND
		JCPP.BatchSeq = @Key_BatchSeq
				
	-- ORDER OF PRECEDENCE should the user enter more then one of the 
	-- calculated values the following order of precedence takes effect:
	--		1. Period Complete	
	--		2. Complete To Date
	--		3. Total %	
	-- NOTE: In the V6 form, all 3 input fields are calculated immediately
	--		 when any one of the fields lose focus.  In the web world, however,
	--		 that requires heavy Javascript to accomplish, so to keep things
	--		 simple, we'll use this approach.
				
	-- 1. PERIOD COMPLETE
	IF @PeriodComplete <> @PreviousPeriodComplete
		BEGIN
			SET @TotalCompletedUnits = @CurrentCompleted + @PeriodComplete
			IF @Plugged = 'Y' AND @CurrentProjected <> 0
				SET @TotalPercentage = @TotalCompletedUnits / @CurrentProjected
			ELSE IF @Plugged = 'N' AND @CurrentEstimated <> 0
				SET @TotalPercentage = @TotalCompletedUnits / @CurrentEstimated	
		END		
	-- 2. COMPLETE TO DATE
	ELSE IF @CompleteToDate <> @PreviousCompleteToDate
		BEGIN
			SET @PeriodComplete = @CompleteToDate - @CurrentCompleted		
			IF @Plugged = 'Y' AND @CurrentProjected <> 0
				SET @TotalPercentage = @CompleteToDate / @CurrentProjected
			ELSE IF @Plugged = 'N' AND @CurrentEstimated <> 0
				SET @TotalPercentage = @CompleteToDate / @CurrentEstimated	
		END	
	-- 3. TOTAL PERCENTAGE
	ELSE IF @TotalPercentage <> @PreviousTotalPerc AND @TotalPercentage <> 0
		BEGIN
			IF @Plugged = 'Y' 
				SET @TotalCompletedUnits = @CurrentProjected * @TotalPercentage
			ELSE
				SET @TotalCompletedUnits = @CurrentEstimated * @TotalPercentage				
			SET @PeriodComplete = @TotalCompletedUnits - @CurrentCompleted
		END
	
	-- Ensure the @TotalPercentage doesn't exceed the max allowed value for bPct
	IF @TotalPercentage > 99.9999
		BEGIN
			SET @TotalPercentage = 99.9999
		END
	
	-- UPDATE the batch entry
	UPDATE JCPP 
	SET JCPP.ActualUnits = @PeriodComplete
	   ,JCPP.ProgressCmplt = @TotalPercentage
	WHERE 
		JCPP.Co = @Key_JCCo AND
		JCPP.BatchId = @Key_BatchId AND
		JCPP.Mth = @Key_Mth AND
		JCPP.BatchSeq = @Key_BatchSeq
	
	EXEC vpspJCProgressGet @Key_JCCo, @Key_BatchId, @Key_Mth, @VPUserName, @Key_BatchSeq

	vspExit:
END
GO
GRANT EXECUTE ON  [dbo].[vpspJCProgressPhaseUpdate] TO [VCSPortal]
GO
