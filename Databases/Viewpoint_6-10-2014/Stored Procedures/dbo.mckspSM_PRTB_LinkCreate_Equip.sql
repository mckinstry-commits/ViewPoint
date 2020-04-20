SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Original Author:		Eric Vaterlaus
-- MCK Current Author:	Eric Shafer
-- Create date: 02/04/2011
-- Description:	Create links in vSMBC to link SMWorkCompleted records to PRTB
-- New link to mckSMBC but for EM records added to SMWorkCompleted.
-- =============================================
CREATE PROCEDURE [dbo].[mckspSM_PRTB_LinkCreate_Equip]
	@SMCo bCompany, @PRCo bCompany, @BatchMth bMonth, @BatchId int, @BatchSeq int, @WorkOrder int, @Scope int,
	@WorkCompleted bigint, @SMWorkCompletedID bigint=NULL, @errmsg varchar(255)=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int
	
	BEGIN TRY
		INSERT mckSMBC (SMCo, PostingCo, WorkOrder, Scope, LineType, [Source], WorkCompleted,
			SMWorkCompletedID, InUseMth, InUseBatchId, InUseBatchSeq, Line)
		VALUES (@SMCo, @PRCo, @WorkOrder, @Scope, 1, 'PRTimecard', @WorkCompleted, @SMWorkCompletedID, 
			@BatchMth, @BatchId, @BatchSeq, @BatchSeq)
		
		Set @rcode = 0
	END TRY
	BEGIN CATCH
		SET @rcode = 1
		SET @errmsg = 'Link create between SMWorkCompleted and PRTB failed with error: ' + ERROR_MESSAGE()
	END CATCH
	
	RETURN @rcode
END



GO
