SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/21/11
-- Description:	This stored procedure should be called whenever all the neccessary information
--				has been supplied for a PO batch record to be posted. This means the vendor has to have
--				been supplied.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMPOEntyValidate] 
	@POCo bCompany, @SMCo bCompany, @WorkOrder int, @BatchMth bMonth, @BatchId bBatchID, @Source char(10), @ReadyToPost bit = 0 OUTPUT, @AttachBatchReportsYN bYN = NULL OUTPUT, @BatchKeyID bigint = NULL OUTPUT, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int, @todaysDate smalldatetime

	--Verify that the batch actually exists
	--Then verify that we don't have any batch records that are missing the vendor.
	IF EXISTS(SELECT 1 FROM dbo.HQBC WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId) 
		AND NOT EXISTS(SELECT 1 FROM dbo.POHB WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId AND Vendor IS NULL)
		AND NOT EXISTS(SELECT 1 FROM dbo.POIB WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId AND CASE WHEN SMCo = @SMCo AND SMWorkOrder = @WorkOrder THEN 1 ELSE 0 END = 0)
	BEGIN
		EXEC @rcode = dbo.bspPOHBVal @co = @POCo, @mth = @BatchMth, @batchid = @BatchId, @source = @Source, @errmsg = @msg OUTPUT
	    
	    --There was an error in the validation proc. Return now.
	    IF @rcode = 1 RETURN 1
	    
	    --A record failed validation. Return now.
	    IF EXISTS(SELECT 1 FROM dbo.HQBE WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId) RETURN 1
	    
	    SET @ReadyToPost = 1
	    
	    --Get whether we should we attach the report
	    SELECT @AttachBatchReportsYN = AttachBatchReportsYN
	    FROM dbo.POCO
	    WHERE POCo = @POCo
	    
	    --Get the batch keyid so that we can attach the report
	    SELECT @BatchKeyID = KeyID
	    FROM dbo.HQBC
		WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId
    END
    ELSE
    BEGIN
		--Unlock the batch so others can jump in from the PO batch form
		EXEC dbo.bspHQBCExitCheck @co=@POCo, @mth=@BatchMth, @batchid = @BatchId, @source = @Source, @tablename = 'POHB', @errmsg = NULL
    END
    
    RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMPOEntyValidate] TO [public]
GO
