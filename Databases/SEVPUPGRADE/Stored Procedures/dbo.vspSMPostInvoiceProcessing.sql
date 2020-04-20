SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/13/11
-- Description:	This is run after an AR batch has been created and the batch processing
--				form has been launched to process the batch. We need to check if the user
--				actually posted the batch or not. If the user never attempted to post the
--				batch then we delete the batch. If the batch got caught in posting and bombed
--				out then we assume that someone will finish posting the batch and we should
--				accept the changes made on the SM side.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMPostInvoiceProcessing]
	@ARCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @BatchIsPosted bit OUTPUT, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @BatchStatus tinyint
	
    SELECT @BatchStatus = [Status]
    FROM dbo.HQBC
    WHERE Co = @ARCo AND Mth = @BatchMth AND BatchId = @BatchId AND [Source] = 'SM Invoice' AND TableName = 'ARBH'
    IF (@@rowcount <> 1)
    BEGIN
		SET @msg = 'Couldn''t find the AR batch.'
		RETURN 1
    END
    
    SET @BatchIsPosted = 1
    
    IF @BatchStatus NOT IN (4, 5) --If we didn't attempt to post the batch then we cancel the batch
    BEGIN
		-- Cancel the AR batch
		EXEC @rcode = dbo.bspARBatchClear @co = @ARCo, @mth = @BatchMth, @batchid = @BatchId, @errmsg = @msg OUTPUT

		IF @rcode <> 0 RETURN @rcode

		SET @BatchIsPosted = 0
    END
    
    RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMPostInvoiceProcessing] TO [public]
GO
