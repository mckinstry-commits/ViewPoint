SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 02/03/2011
-- Description:	Create SMWorkCompleted and SMBC record. Called when SM type PR Timecard record added.
-- Modifications: 03/15/11 EricV Added Craft, Class and Shift
--                05/04/2011 Eric V  Modified for one unique WorkCompleted for all types.
--				  02/09/2012 JG - TK-12388 - Added SMJCCostType and SMPhaseGroup.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTimecardInsert] 
	@PRCo bCompany, @Mth bMonth, @BatchId int, @BatchSeq int, @Employee int, @PostDate smalldatetime, 
	@SMCo bCompany, @WorkOrder int, @Scope int, @PayType varchar(10), @SMCostType smallint=null, @Hours bHrs, 
	@Craft bCraft=NULL, @Class bClass=NULL, @Shift tinyint=NULL, 
	@SMJCCostType dbo.bJCCType, @SMPhaseGroup dbo.bGroup, @errmsg varchar(255) OUTPUT
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/* Create a matching record in SMWorkCompleted linked with records in SMBC */
	/* For each MyTimesheetDetail record one SMWorkCompleted record will be created for each day that is not null */
	DECLARE @WorkCompleted int, @SMWorkCompletedID int, @rcode int, @Source varchar(10), 
			@LineType tinyint, @Technician varchar(15)
	
	SELECT @Source = 'PRTimecard', @LineType=2
	
	/* Check to see if a link in SMBC already exists.  If so then the SMWorkCompleted record already exists. */
	IF EXISTS(SELECT 1 FROM vSMBC Where Source=@Source AND SMCo=@SMCo AND PostingCo=@PRCo AND InUseMth=@Mth
				AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq)
	BEGIN
		/* Since the link to a SMWorkCompleted record exists, this record must have moved from PRMyTimesheet */
		RETURN 0
	END

	/*	First create the link in SMBC so that the insert trigger on SMWorkCompleted won't try and create
		a PRMyTimesheet record. */	
	SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @WorkOrder)

	BEGIN TRY
		INSERT vSMBC (SMCo, PostingCo, WorkOrder, Scope, LineType, WorkCompleted, InUseMth, InUseBatchId, InUseBatchSeq, Source, UpdateInProgress) 
			VALUES (@SMCo, @PRCo, @WorkOrder, @Scope, @LineType, @WorkCompleted, @Mth, @BatchId, @BatchSeq, @Source, 1)
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Insert into SMBC failed: ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	/* Create the SMWorkCompleted Records */
	SELECT @Technician=Technician FROM SMTechnician WHERE SMCo=@SMCo AND PRCo=@PRCo AND Employee=@Employee
	
	exec @rcode = vspSMWorkCompletedLaborCreate @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope, @WorkCompleted = @WorkCompleted, 
		@PayType=@PayType, @SMCostType=@SMCostType, @Technician=@Technician, @Date=@PostDate, @Hours=@Hours,
		@TCPRCo=@PRCo, @Craft=@Craft, @Class=@Class, @Shift=@Shift, @SMJCCostType=@SMJCCostType, @SMPhaseGroup=@SMPhaseGroup,
		@SMWorkCompletedID=@SMWorkCompletedID OUTPUT, @msg=@errmsg OUTPUT
	IF (@rcode = 1)
	BEGIN
		RETURN @rcode
	END
	BEGIN TRY
		UPDATE vSMBC Set SMWorkCompletedID=@SMWorkCompletedID, UpdateInProgress=0 WHERE PostingCo=@PRCo AND InUseMth=@Mth AND InUseBatchId=@BatchId
			AND InUseBatchSeq=@BatchSeq AND Source=@Source
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Update of SMBC failed: ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH
						
	RETURN @rcode
	
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTimecardInsert] TO [public]
GO
