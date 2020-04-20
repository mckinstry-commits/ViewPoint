SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 04/11/2011
-- Description:	Update SM labor records with actual costs from PR
-- Modificatiom: ERICV Change to access Table instead of View.
-- =============================================
CREATE PROCEDURE [dbo].[vspPRUpdateValSM]
(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @beginmth bMonth = null,
 @endmth bMonth = null, @cutoffdate bDate = null, @status int, @errmsg varchar(255) = null output)

AS
BEGIN
	SET NOCOUNT ON
 
	IF @status = 1
	BEGIN
		DECLARE @SMWorkCompletedValidation cursor, @Employee bEmployee, @PaySeq int, @PostSeq tinyint, @PostDate smalldatetime, @SMCo bCompany, @WorkOrder int, @Scope int, @errortext varchar(255), @rcode int
		
		SET @SMWorkCompletedValidation = CURSOR LOCAL FAST_FORWARD FOR
		SELECT bPRTH.Employee, bPRTH.PaySeq, bPRTH.PostSeq, vSMWorkCompleted.SMCo, vSMWorkCompleted.WorkOrder, vSMWorkCompletedDetail.Scope
		FROM dbo.bPRTH
			INNER JOIN dbo.vSMWorkCompleted ON bPRTH.PRCo = vSMWorkCompleted.CostCo AND bPRTH.PRGroup = vSMWorkCompleted.PRGroup AND bPRTH.PREndDate = vSMWorkCompleted.PREndDate AND bPRTH.Employee = vSMWorkCompleted.PREmployee AND bPRTH.PaySeq = vSMWorkCompleted.PRPaySeq AND bPRTH.PostSeq = vSMWorkCompleted.PRPostSeq
			INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompleted.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID AND vSMWorkCompletedDetail.IsSession = 0
		WHERE bPRTH.PRCo = @prco AND bPRTH.PRGroup = @prgroup AND bPRTH.PREndDate = @prenddate AND vSMWorkCompleted.Provisional = 1
		
		OPEN @SMWorkCompletedValidation

		SMWorkCompletedValidation_FetchNext:
		BEGIN
			FETCH NEXT FROM @SMWorkCompletedValidation
			INTO @Employee, @PaySeq, @PostSeq, @SMCo, @WorkOrder, @Scope
			
			IF @@FETCH_STATUS = 0
			BEGIN
				SELECT @errortext = 'Call Type or Rate Template missing on SMCo: '+ dbo.vfToString(@SMCo) + '  WorkOrder: '+ dbo.vfToString(@WorkOrder) + '  Scope: ' + dbo.vfToString(@Scope)
     			EXEC @rcode = dbo.bspPRURInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @employee = @Employee, @payseq = @PaySeq, @postseq = @PostSeq, @errortext = @errortext, @errmsg = @errmsg OUTPUT
     			IF @rcode = 1
     			BEGIN
     				EXEC dbo.vspCleanupCursor @Cursor = @SMWorkCompletedValidation
     				RETURN 1
     			END
			
				GOTO SMWorkCompletedValidation_FetchNext
			END
		END

		EXEC dbo.vspCleanupCursor @Cursor = @SMWorkCompletedValidation
	END
 
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspPRUpdateValSM] TO [public]
GO
