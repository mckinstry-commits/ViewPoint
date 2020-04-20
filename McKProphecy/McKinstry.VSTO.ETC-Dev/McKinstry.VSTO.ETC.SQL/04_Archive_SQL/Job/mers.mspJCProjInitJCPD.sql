use ViewpointProphecy
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspJCProjInitJCPD' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspJCProjInitJCPD'
	DROP PROCEDURE mers.mspJCProjInitJCPD
end
go

print 'CREATE PROCEDURE mers.mspJCProjInitJCPD'
go

CREATE PROCEDURE [mers].[mspJCProjInitJCPD]
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
-- ========================================================================
DECLARE  @MaxDetMonth bMonth
	, @DetMonth bMonth
	, @Action varchar(1)
	, @opencursor tinyint
	, @DetSequence INT
	, @xKeyId INT
	, @xBatchSeq INT
	, @xPhaseGroup bGroup
	, @xPhase bPhase
	, @xCostType bJCCType
	, @xResTrans bTrans
	, @rcode TINYINT


SELECT @MaxDetMonth=max(Mth) from JCPR where JCCo=@JCCo and Job=@Job
SET @DetSequence = 1

IF @MaxDetMonth is not null 
	BEGIN
		SET @DetMonth = @MaxDetMonth
		IF @MaxDetMonth >= @bMonth
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
					FROM JCPR A 
						INNER JOIN JCPB B
							ON A.JCCo = B.Co
							AND A.Job = B.Job
							AND A.PhaseGroup = B.PhaseGroup
							AND A.Phase = B.Phase
							AND A.CostType = B.CostType
					WHERE A.Job = @Job
					AND A.JCCo = @JCCo
					AND B.Mth = @bMonth
					AND B.BatchId = @BatchId
					AND ((A.Mth = @bMonth or DetMth >= @bMonth)
					or (A.DetMth IS NULL AND A.FromDate IS NULL AND A.ToDate IS NULL)) 
       	OPEN bJCPD_insert
    	SET @opencursor = 1

bJCPD_Insert_Loop:	
    	
    	FETCH NEXT FROM bJCPD_insert INTO @xResTrans, @xBatchSeq, @xPhaseGroup, @xPhase, @xCostType
    	
    	IF @@fetch_status <> 0
    		BEGIN
    			SELECT @errmsg = 'Cursor Empty'
    			GOTO BREXIT
    		END

	--Begin Insert	
	INSERT into bJCPD (Co, Mth, BatchId, BatchSeq, DetSeq, Source, JCTransType, TransType, ResTrans,
			Job, PhaseGroup, Phase, CostType, BudgetCode, EMCo, Equipment, PRCo, Craft, Class,
			Employee, Description, DetMth, FromDate, ToDate, Quantity, UM, Units, UnitHours, Hours,
			Rate, UnitCost, Amount, Notes, OldTransType, OldJob, OldPhaseGroup, OldPhase, OldCostType,
			OldBudgetCode, OldEMCo, OldEquipment, OldPRCo, OldCraft, OldClass, OldEmployee,
			OldDescription, OldDetMth, OldFromDate, OldToDate, OldQuantity, OldUM, OldUnits,
			OldUnitHours, OldHours, OldRate, OldUnitCost, OldAmount, UniqueAttchID)
	SELECT @JCCo, @bMonth, @BatchId, @xBatchSeq, @DetSequence, r.Source, r.JCTransType, @Action, null
			, @Job, @xPhaseGroup, @xPhase, @xCostType, r.BudgetCode, r.EMCo, r.Equipment, r.PRCo,r.Craft, r.Class
			, r.Employee, r.Description, r.DetMth, r.FromDate, r.ToDate, r.Quantity, r.UM, r.Units, r.UnitHours, r.Hours
			, r.Rate, r.UnitCost, r.Amount, r.Notes, @Action, r.Job, r.PhaseGroup, r.Phase, r.CostType
			, r.BudgetCode, r.EMCo, r.Equipment,r.PRCo, r.Craft, r.Class, r.Employee
			, r.Description, r.DetMth, r.FromDate, r.ToDate,r.Quantity, r.UM, r.Units
			, r.UnitHours, r.Hours, r.Rate, r.UnitCost, r.Amount, null
	FROM bJCPR r with (nolock)
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

END

BREXIT:
	if @opencursor = 1
		begin
		close bJCPD_insert
		deallocate bJCPD_insert
		SET @opencursor = 0
		end
   

GO