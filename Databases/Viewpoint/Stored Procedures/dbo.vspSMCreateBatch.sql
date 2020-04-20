SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/10/2011
-- Description:	Creates a batch for SM
-- =============================================
CREATE PROCEDURE [dbo].[vspSMCreateBatch]
	@BatchCo bCompany, @BatchMonth bMonth, @Source bSource, @BatchTable char(20), @BatchId bBatchID = NULL OUTPUT, @KeyID bigint = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*DECLARE @rcode int, @GLCo bCompany

	IF @Source = 'PO Receipt'
	BEGIN
		SELECT @GLCo = GLCo
		FROM dbo.PRCO
		WHERE PRCo = @BatchCo
	END
	ELSE IF @Source = 'SMEquipUse'
	BEGIN
		SELECT @GLCo = GLCo
		FROM dbo.EMCO
		WHERE EMCo = @BatchCo
	END
	ELSE
	BEGIN
		SET @msg = 'Required logic has not been added to vspSMCreateBatch. Please add logic for your source.'
		RETURN 1
	END
	
	DECLARE @BeginMonth bDate, @EndMonth bDate
	
	--This is the default logic for calculating the beginning and ending month
	--Depending on what module you are working with you may need to get a different ending month
	--Look to bspHQBatchMonthVal to figure out the logic.
	SELECT @BeginMonth = DATEADD(MONTH, 1, LastMthSubClsd),
		@EndMonth = DATEADD(MONTH, MaxOpen, LastMthSubClsd)
	FROM dbo.GLCO
	WHERE GLCo = @GLCo
	
	SET @BatchMonth = dbo.vfDateOnlyMonth()
	
	--We pick the closest open month to the current month if the current month is not open
	IF @BatchMonth < @BeginMonth
	BEGIN
		SET @BatchMonth = @BeginMonth
	END
	ELSE IF @BatchMonth > @EndMonth
	BEGIN
		SET @BatchMonth = @EndMonth
	END

	--Double check that our logic is correct for figuring out the batch month
	EXEC @rcode = dbo.bspHQBatchMonthVal @glco = @GLCo, @mth = @BatchMonth, @source = @Source, @msg = @msg OUTPUT

	IF @rcode = 1
    BEGIN
		RETURN 1
    END*/

    EXEC @BatchId = dbo.bspHQBCInsert @co = @BatchCo, @month = @BatchMonth, @source = @Source, @batchtable = @BatchTable, @restrict = 'Y', @adjust = 'N', @errmsg = @msg OUTPUT
    
    SELECT @KeyID = KeyID
    FROM dbo.HQBC
    WHERE Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId
    
    --A batchid of 0 indicates there was an error creating the batch
    IF @BatchId = 0
    BEGIN
		RETURN 1
    END
    
    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMCreateBatch] TO [public]
GO
