SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 02/04/2011
-- Description:	Create links in vSMBC to link SMWorkCompleted records to PRTB
-- =============================================
CREATE PROCEDURE [dbo].[vspSM_PRTB_LinkCreate]
	@SMCo bCompany, @PRCo bCompany, @BatchMth bMonth, @BatchId int, @BatchSeq int, @WorkOrder int, @Scope int,
	@WorkCompleted bigint, @SMWorkCompletedID bigint=NULL, @errmsg varchar(255)=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int
	
	BEGIN TRY
		INSERT vSMBC (SMCo, PostingCo, WorkOrder, Scope, LineType, [Source], WorkCompleted,
			SMWorkCompletedID, InUseMth, InUseBatchId, InUseBatchSeq)
		VALUES (@SMCo, @PRCo, @WorkOrder, @Scope, 2, 'PRTimecard', @WorkCompleted, @SMWorkCompletedID, 
			@BatchMth, @BatchId, @BatchSeq)
		
		Set @rcode = 0
	END TRY
	BEGIN CATCH
		SET @rcode = 1
		SET @errmsg = 'Link create between SMWorkCompleted and PRTB failed with error: ' + ERROR_MESSAGE()
	END CATCH
	
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspSM_PRTB_LinkCreate] TO [public]
GO
