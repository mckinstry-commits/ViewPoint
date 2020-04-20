SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 12/15/2010
-- Description:	Check for status of SM AR Invoice Batch
-- =============================================
CREATE PROCEDURE [dbo].[vspSMInvoiceBatchStatus]
	@SMSessionID	int,
	@BatchMth		smalldatetime,
	@BatchId		int,
	@Posted			bit OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
		
	IF EXISTS(SELECT 1 FROM SMBC
			WHERE SMBC.InUseMth = @BatchMth AND SMBC.InUseBatchId = @BatchId
			AND NOT SMBC.PostedMth is null and NOT SMBC.Trans is null )
		SELECT @Posted = 1
	ELSE
		SELECT @Posted = 0
	
	Return 0
END



GO
GRANT EXECUTE ON  [dbo].[vspSMInvoiceBatchStatus] TO [public]
GO
