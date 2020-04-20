USE [Viewpoint]
GO
/****** Object:  StoredProcedure [mers].[mspJCProjInitJCPD]    Script Date: 12/7/2016 1:13:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [mers].[mspJCProjInitJCPD]
(
	@JCCo		bCompany 
,	@Job		bJob
,	@bMonth		bMonth
,	@BatchId	bBatchID
,	@errmsg		varchar(255) output
)
as
-- ========================================================================
-- Object Name: mers.mspJCProjInitJCPD
-- Author:		Ziebell, Jonathan
-- Create date: 06/28/2016
-- Description: Replace [dbo].[vspJCProjJCPDGet] due to performace.  Initialization of Detail Projections must be faster
-- Update Hist: USER--------DATE-------DESC-----------
--              J.Ziebell   08/18/2016    Fixed Issue with Trans Type for Re-Projection
--              J.Ziebell   11/22/2016    When Reprojecting an old month after a new month, need to add old month delete rows.
--              J.Ziebell   12/01/2016    Explicit Schema reference
--				J.Ziebell   07/14/2017	  Remove Null date Code that was allowing duplicate rows.
--				J.Ziebell   01/24/2018    Stop pulling in Old Batch Month Detail for zero-ed out projects.
-- ========================================================================
DECLARE  @MaxDetMonth bMonth
	, @MaxSumMonth bMonth
	, @DetMonth bMonth
	, @Action varchar(1)
	, @opencursor tinyint
	, @opencursor2 tinyint
	, @DetSequence INT
	, @xKeyId INT
	, @xBatchSeq INT
	, @xPhaseGroup bGroup
	, @xPhase bPhase
	, @xCostType bJCCType
	, @xResTrans bTrans
	, @InsertTrans bTrans
	, @rcode TINYINT
	, @CurMonthDetail VARCHAR(1)


SELECT @MaxDetMonth = MAX(Mth) from JCPR where JCCo=@JCCo and Job=@Job     


SET @CurMonthDetail = 'N'
SELECT @CurMonthDetail='Y' from JCPR where JCCo=@JCCo and Job=@Job and Mth=@bMonth
SET @DetSequence = 1

IF @MaxDetMonth is not null 
	BEGIN
		IF @MaxDetMonth < @MaxSumMonth
			BEGIN
				goto BREXIT
				--SET @MaxDetMonth = @MaxSumMonth
			END

		SET @DetMonth = @MaxDetMonth
		IF @MaxDetMonth = @bMonth
			BEGIN
				SET @Action = 'C'
			END
		ELSE
			BEGIN
				SET @Action = 'A'
			END
	END
ELSE 
	BEGIN
		goto BREXIT
		--SELECT @DetMonth = @bMonth	
		--Select @Action = 'A'
	END

BEGIN
    	-- Use a cursor to process each inserted row in sequence
    	DECLARE bJCPD_insert cursor LOCAL FAST_FORWARD
    		FOR SELECT A.ResTrans, B.BatchSeq, B.PhaseGroup, B.Phase, B.CostType 
					FROM dbo.JCPR A 
						INNER JOIN dbo.JCPB B
							ON A.JCCo = B.Co
							AND A.Job = B.Job
							AND A.PhaseGroup = B.PhaseGroup
							AND A.Phase = B.Phase
							AND A.CostType = B.CostType
					WHERE A.Job = @Job
					AND A.JCCo = @JCCo
					AND B.Mth = @bMonth
					AND B.BatchId = @BatchId
					AND ((A.Mth = @DetMonth))
					/*or DetMth >= @bMonth) or (A.DetMth IS NULL AND A.FromDate IS NULL AND A.ToDate IS NULL)) */
       	OPEN bJCPD_insert
    	SET @opencursor = 1

--print @opencursor

bJCPD_Insert_Loop:	
--Print @DetSequence
    	
    	FETCH NEXT FROM bJCPD_insert INTO @xResTrans, @xBatchSeq, @xPhaseGroup, @xPhase, @xCostType
    	
		--Print 'FETCH'
		--Print @xResTrans

    	IF @@fetch_status <> 0
    		BEGIN
			--Print 'NO FETCH'
    			SELECT @errmsg = 'Cursor Empty'
    			GOTO bJCPD_OldDelete_Start
    		END

	IF @Action = 'C'
		SET @InsertTrans = @xResTrans
	ELSE
		SET @InsertTrans = NULL
		
	--Begin Insert	
	INSERT into dbo.bJCPD (Co, Mth, BatchId, BatchSeq, DetSeq, Source, JCTransType, TransType, ResTrans,
			Job, PhaseGroup, Phase, CostType, BudgetCode, EMCo, Equipment, PRCo, Craft, Class,
			Employee, Description, DetMth, FromDate, ToDate, Quantity, UM, Units, UnitHours, Hours,
			Rate, UnitCost, Amount, Notes, OldTransType, OldJob, OldPhaseGroup, OldPhase, OldCostType,
			OldBudgetCode, OldEMCo, OldEquipment, OldPRCo, OldCraft, OldClass, OldEmployee,
			OldDescription, OldDetMth, OldFromDate, OldToDate, OldQuantity, OldUM, OldUnits,
			OldUnitHours, OldHours, OldRate, OldUnitCost, OldAmount, UniqueAttchID)
	SELECT @JCCo, @bMonth, @BatchId, @xBatchSeq, @DetSequence, r.Source, r.JCTransType, @Action, @InsertTrans
			, @Job, @xPhaseGroup, @xPhase, @xCostType, r.BudgetCode, r.EMCo, r.Equipment, r.PRCo,r.Craft, r.Class
			, r.Employee, r.Description, r.DetMth, r.FromDate, r.ToDate, r.Quantity, r.UM, r.Units, r.UnitHours, r.Hours
			, r.Rate, r.UnitCost, r.Amount, r.Notes, @Action, r.Job, r.PhaseGroup, r.Phase, r.CostType
			, r.BudgetCode, r.EMCo, r.Equipment,r.PRCo, r.Craft, r.Class, r.Employee
			, r.Description, r.DetMth, r.FromDate, r.ToDate,r.Quantity, r.UM, r.Units
			, r.UnitHours, r.Hours, r.Rate, r.UnitCost, r.Amount, null
	FROM dbo.bJCPR r with (nolock)
		WHERE r.JCCo = @JCCo 
			AND r.Mth = @DetMonth 
			AND r.ResTrans = @xResTrans
	if @@rowcount <> 1
		begin
		select @errmsg = 'Unable to add entry to JC Projection Detail Batch!', @rcode = 1
		goto BREXIT
		end

Set @DetSequence = @DetSequence + 1

GOTO bJCPD_Insert_Loop

bJCPD_OldDelete_Start:

IF ((@CurMonthDetail = 'Y') AND (@MaxDetMonth > @bMonth))
	BEGIN
    					-- Use a cursor to process each inserted row in sequence
    					DECLARE bJCPD_OldDelete cursor LOCAL FAST_FORWARD
    						FOR SELECT A.ResTrans, B.BatchSeq, B.PhaseGroup, B.Phase, B.CostType 
									FROM dbo.JCPR A 
										INNER JOIN dbo.JCPB B
											ON A.JCCo = B.Co
											AND A.Job = B.Job
											AND A.PhaseGroup = B.PhaseGroup
											AND A.Phase = B.Phase
											AND A.CostType = B.CostType
									WHERE A.Job = @Job
									AND A.JCCo = @JCCo
									AND B.Mth = @bMonth
									AND B.BatchId = @BatchId
									AND A.Mth = @bMonth
       					OPEN bJCPD_OldDelete
    					SET @opencursor2 = 1

				--print @opencursor

bJCPD_OldDelete_Loop:	
				--Print @DetSequence
    	
    					FETCH NEXT FROM bJCPD_OldDelete INTO @xResTrans, @xBatchSeq, @xPhaseGroup, @xPhase, @xCostType
    	
						--Print 'FETCH'
						--Print @xResTrans

    					IF @@fetch_status <> 0
    						BEGIN
							--Print 'NO FETCH'
    							SELECT @errmsg = 'Cursor Empty'
    							GOTO BREXIT
    						END

						SET @Action = 'D'
						SET @InsertTrans = @xResTrans
							
					--Begin Insert	
					INSERT into dbo.bJCPD (Co, Mth, BatchId, BatchSeq, DetSeq, Source, JCTransType, TransType, ResTrans,
							Job, PhaseGroup, Phase, CostType, BudgetCode, EMCo, Equipment, PRCo, Craft, Class,
							Employee, Description, DetMth, FromDate, ToDate, Quantity, UM, Units, UnitHours, Hours,
							Rate, UnitCost, Amount, Notes, OldTransType, OldJob, OldPhaseGroup, OldPhase, OldCostType,
							OldBudgetCode, OldEMCo, OldEquipment, OldPRCo, OldCraft, OldClass, OldEmployee,
							OldDescription, OldDetMth, OldFromDate, OldToDate, OldQuantity, OldUM, OldUnits,
							OldUnitHours, OldHours, OldRate, OldUnitCost, OldAmount, UniqueAttchID)
					SELECT @JCCo, @bMonth, @BatchId, @xBatchSeq, @DetSequence, r.Source, r.JCTransType, @Action, @InsertTrans
							, @Job, @xPhaseGroup, @xPhase, @xCostType, r.BudgetCode, r.EMCo, r.Equipment, r.PRCo,r.Craft, r.Class
							, r.Employee, r.Description, r.DetMth, r.FromDate, r.ToDate, r.Quantity, r.UM, r.Units, r.UnitHours, r.Hours
							, r.Rate, r.UnitCost, r.Amount, r.Notes, @Action, r.Job, r.PhaseGroup, r.Phase, r.CostType
							, r.BudgetCode, r.EMCo, r.Equipment,r.PRCo, r.Craft, r.Class, r.Employee
							, r.Description, r.DetMth, r.FromDate, r.ToDate,r.Quantity, r.UM, r.Units
							, r.UnitHours, r.Hours, r.Rate, r.UnitCost, r.Amount, null
					FROM dbo.bJCPR r with (nolock)
						WHERE r.JCCo = @JCCo 
							AND r.Mth = @bMonth
							AND r.ResTrans = @xResTrans
					if @@rowcount <> 1
						begin
						select @errmsg = 'Unable to add entry to JC Projection Detail Batch!', @rcode = 1
						goto BREXIT
						end

				Set @DetSequence = @DetSequence + 1

				GOTO bJCPD_OldDelete_Loop

	END
ELSE
	BEGIN
		GOTO BREXIT
	END

END

BREXIT:
	if @opencursor = 1
		begin
			close bJCPD_insert
			deallocate bJCPD_insert
			SET @opencursor = 0
		end
	if @opencursor2 = 1
		begin
			close bJCPD_OldDelete
			deallocate bJCPD_OldDelete
			SET @opencursor2 = 0
		end

GO

Grant EXECUTE ON dbo.mspJCProjInitJCPD TO [MCKINSTRY\Viewpoint Users]