SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 4/4/2014
-- Description:	Create SMWorkCompleted and mckSMBC record.  Called when SM type PR Timecard record added.
-- =============================================
CREATE PROCEDURE [dbo].[mckSMTimecardInsert] 
	-- Add the parameters for the stored procedure here
	@PRCo bCompany = 0
	--, @Mth bMonth = 0
	--, @BatchId bBatchID
	--, @BatchSeq INT
	, @PRTHKeyID INT
	, @Employee INT
	, @PostDate SMALLDATETIME
	, @SMCo bCompany
	, @WorkOrder INT, @Scope INT, @SMCostType SMALLINT =NULL, @Hours bHrs
	--, @OldPostSeq INT
	--, @Craft bCraft = NULL, @Class bClass = NULL
	, @SMJCCostType dbo.bJCCType = NULL, @SMPhaseGroup dbo.bGroup, @BatchTransType CHAR(1)
	--, @PRTBKeyID BIGINT 
	, @errmsg VARCHAR(255) OUTPUT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	DECLARE @WorkCompleted INT, @SMWorkCompletedID INT, @rcode INT, @Source VARCHAR(10), @LineType TINYINT, @Technician VARCHAR(15)

	SELECT @Source = 'PRTimecard', @LineType=1

	IF EXISTS(SELECT 1 FROM dbo.mckSMBC WHERE PRTHKeyID =@PRTHKeyID)
		BEGIN
			RETURN 0
		END


	SELECT @Technician = Technician 
		FROM SMTechnician 
		WHERE SMCo = @SMCo AND PRCo = @PRCo AND Employee = @Employee

	IF @BatchTransType = 'A'
	SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @WorkOrder)
	--IF @BatchTransType = 'C'
	--SELECT TOP 1 @WorkCompleted = WorkCompleted , @SMWorkCompletedID = SMWorkCompletedID
	--	FROM dbo.SMWorkCompleted 
	--	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Type = 1 AND Date = @PostDate AND PRPostSeq = @OldPostSeq

	IF @BatchTransType = 'A'
	BEGIN
		BEGIN TRY
			INSERT mckSMBC (SMCo, PostingCo, WorkOrder, Scope, LineType, WorkCompleted/*, InUseMth, InUseBatchId, InUseBatchSeq*/, Source, UpdateInProgress
				--, PRTBKeyID
				, PRTHKeyID) 
				VALUES (@SMCo, @PRCo, @WorkOrder, @Scope, @LineType, @WorkCompleted/*, @Mth, @BatchId, @BatchSeq*/, @Source, 1
				--, @PRTBKeyID
				, @PRTHKeyID)
		END TRY
		BEGIN CATCH
			SET @errmsg = 'Insert into SMBC failed: ' + ERROR_MESSAGE()
			RETURN 1
		END CATCH
	END
	IF @BatchTransType = 'C'
	BEGIN
		--DECLARE @PRTHKeyID BIGINT
		--SELECT @PRTHKeyID = KeyID
		--	FROM dbo.PRTH
		--	WHERE PRTBKeyID = @PRTBKeyID

		--SET @PRTBKeyID = (SELECT TOP 1 KeyID 
		--FROM dbo.PRTB WHERE Co = @PRCo AND BatchId = @BatchId AND BatchSeq = @BatchSeq)

		BEGIN TRY
			UPDATE mckSMBC 
			SET /*InUseBatchId = @BatchId, PostedMth = @Mth,*/ PRTHKeyID = @PRTHKeyID--, PRTBKeyID = @PRTBKeyID
			/*, InUseBatchSeq = @BatchSeq*/
			WHERE SMCo = @SMCo AND PostingCo = @PRCo AND WorkOrder = @WorkOrder AND Scope = @Scope 
				AND LineType = @LineType AND WorkCompleted = @WorkCompleted
		END TRY
		BEGIN CATCH
			SET @errmsg = 'Update to mckSMBC failed: ' + ERROR_MESSAGE()
			RETURN 1
		END CATCH
	END
		
	--Dont insert a new Work Completed if this is a change.  
	IF @BatchTransType = 'C'
	GOTO SetSMWCID

	EXEC @rcode = mckSMWorkCompletedEquipCreate @SMCo = @SMCo, @WorkOrder = @WorkOrder, @Scope = @Scope, @SMCostType = @SMCostType
	, @Date = @PostDate, @Technician = @Technician, @Hours = @Hours, @WorkCompleted = @WorkCompleted, @SMJCCostType = @SMJCCostType	
	, @SMPhaseGroup = @SMPhaseGroup
	, @SMWorkCompletedID = @SMWorkCompletedID OUTPUT, @TCPRCo = @PRCo, @TCPREmployee = @Employee--, @OldPostSeq = @OldPostSeq
	, @msg = @errmsg OUTPUT
	IF (@rcode = 1)
	BEGIN
		RETURN @rcode
	END

	SetSMWCID:
	--IF @BatchTransType = 'C'
	--BEGIN
	--	SELECT @SMWorkCompletedID = SMWorkCompletedID 
	--		FROM dbo.SMWorkCompleted
	--		WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND WorkCompleted = @WorkCompleted
	--		AND Date = @PostDate AND Type = 1 
	--END

	BEGIN TRY
		UPDATE mckSMBC 
		SET SMWorkCompletedID=@SMWorkCompletedID, UpdateInProgress=0 WHERE PRTHKeyID=@PRTHKeyID
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Update of SMBC failed: ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH

END
GO
