SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Modified:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
--
--
-- Create date: 4/7/11
-- Description:	Loads up a PO for SM in a batch so that the user can modify it.
--				This stored procedure relys on being passed a PO that is legitimately associated with the given work order.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMPOFindBatch]
	@POCo bCompany, @PO varchar(30), @SMCo bCompany, @WorkOrder int, @BatchId bBatchID = NULL OUTPUT, @BatchMonth bMonth = NULL OUTPUT, @BatchSeq int = NULL OUTPUT, @IsCurrentMonthOpen bit = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @BatchStatus tinyint, @InUseBy bVPUserName, @Source bSource, @POStatus tinyint, @POItem bItem

	--First we check to see if the batch was created from SM. If we can find it in our linked table then we will load it.
    SELECT @BatchId = HQBC.BatchId, @BatchMonth = HQBC.Mth, @BatchSeq = POHB.BatchSeq, @BatchStatus = HQBC.[Status], @InUseBy = HQBC.InUseBy, @BatchStatus = HQBC.[Status], @InUseBy = HQBC.InUseBy
    FROM dbo.SMWorkOrderPOHB --SMWorkOrderPOHB links the PO only for add transactions in POHB
		INNER JOIN dbo.POHB ON SMWorkOrderPOHB.POCo = POHB.Co AND SMWorkOrderPOHB.BatchMth = POHB.Mth AND SMWorkOrderPOHB.BatchId = POHB.BatchId AND SMWorkOrderPOHB.BatchSeq = POHB.BatchSeq
		INNER JOIN dbo.HQBC ON HQBC.Co = POHB.Co AND HQBC.Mth = POHB.Mth AND HQBC.BatchId = POHB.BatchId
    WHERE SMWorkOrderPOHB.SMCo = @SMCo AND SMWorkOrderPOHB.WorkOrder = @WorkOrder AND POHB.Co = @POCo AND POHB.PO = @PO
    IF @@rowcount = 1
    BEGIN		
		IF @InUseBy IS NOT NULL
		BEGIN
			SET @msg = 'This PO is being edited by ' + @InUseBy + '. Please wait until they have finished.'
			RETURN 1
		END
		
		IF @BatchStatus <> 0
		BEGIN
			SET @msg = 'This PO already exists in a batch that isn''t open'
			RETURN 1
		END
		
		RETURN 0
    END
    
    SELECT @BatchId = HQBC.BatchId, @BatchMonth = HQBC.Mth, @BatchSeq = POHB.BatchSeq, @BatchStatus = HQBC.[Status], @InUseBy = HQBC.InUseBy, @BatchStatus = HQBC.[Status], @InUseBy = HQBC.InUseBy
    FROM dbo.POIB
		INNER JOIN dbo.POHB ON POIB.Co = POHB.Co AND POIB.Mth = POHB.Mth AND POIB.BatchId = POHB.BatchId
		INNER JOIN dbo.HQBC ON POHB.Co = HQBC.Co AND POHB.Mth = HQBC.Mth AND POHB.BatchId = HQBC.BatchId 
    WHERE POIB.Co = @POCo AND POIB.SMCo = @SMCo AND POIB.SMWorkOrder = @WorkOrder AND POHB.PO = @PO
    IF @@rowcount = 1
    BEGIN		
		IF @InUseBy IS NOT NULL
		BEGIN
			SET @msg = 'This PO is being edited by ' + @InUseBy + '. Please wait until they have finished.'
			RETURN 1
		END
		
		IF @BatchStatus <> 0
		BEGIN
			SET @msg = 'This PO already exists in a batch that isn''t open'
			RETURN 1
		END
		
		RETURN 0
    END
    
    --Now we check to see if the PO actually exists by looking at POHD. If it does then we check to see if the PO
    --has already been pulled into a batch and if so then we load the batch given from the POHD record.
    SELECT @BatchMonth = InUseMth, @BatchId = InUseBatchId, @POStatus = [Status]
    FROM dbo.POHD
    WHERE POCo = @POCo AND PO = @PO
    IF @@rowcount = 1
    BEGIN
		IF @BatchId IS NOT NULL AND @BatchMonth IS NOT NULL
		BEGIN
			SELECT @BatchStatus = HQBC.[Status], @InUseBy = HQBC.InUseBy, @Source = [Source]
			FROM dbo.HQBC
			WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId
			IF @@rowcount = 0
			BEGIN
				--Even though accoring to the record there should be a batch that we can load
				--we were unable to find the actual batch record. If we try to pull this transaction
				--back into a batch the stored procedure bspPOHDInUseValidation will prevent us from being able to.
				--So for right now we bomb out.
				SET @msg = 'PO transaction already in use by another batch!'
				RETURN 1
			END
			
			IF @InUseBy IS NOT NULL
			BEGIN
				SET @msg = 'This PO is being edited by ' + @InUseBy + '. Please wait until they have finished.'
				RETURN 1
			END
			
			IF @BatchStatus <> 0
			BEGIN
				SET @msg = 'This PO already exists in a batch that isn''t open'
				RETURN 1
			END

			IF @Source <> 'PO Entry'
			BEGIN
				SET @msg = 'This PO is being edited in a ' + @Source + ' batch.'
				RETURN 1
			END
			
			SELECT @BatchSeq = BatchSeq
			FROM dbo.POHB
			WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId AND PO = @PO

			IF @BatchSeq IS NULL
			BEGIN
				SET @msg = 'We were unable to find the PO in the batch. Please contact Viewpoint.'
				RETURN 1
			END
			
			RETURN 0
		END
		ELSE
		BEGIN
			IF @POStatus = 3
			BEGIN
				SET @msg  = 'The PO :' + @PO + ' status is pending.'
				RETURN 1
			END
			
			DECLARE @GLCo bCompany, @ThisMonth bMonth
			
			SET @ThisMonth = dbo.vfDateOnlyMonth()
			
			--Get the gl company for the AP company to figure out an open batch month
			SELECT @GLCo = GLCo
			FROM dbo.APCO
			WHERE APCo = @POCo --AP companies are the same as PO companies
			IF @@rowcount <> 1
			BEGIN
				SET @msg = 'The AP company ' + dbo.vfToString(@POCo) + ' could not be found.'
			END

			--Retrieve the closest open month to today's date and whether today's month is an open month
			EXEC @rcode = dbo.vspSMIsBatchMonthOpen @GLCo = @GLCo, @Source = 'PO Entry', @BatchMonth = @ThisMonth, @IsMonthOpen = @IsCurrentMonthOpen OUTPUT, @ClosestOpenMonth = @BatchMonth OUTPUT, @msg = @msg OUTPUT
			IF @rcode <> 0 RETURN @rcode

			RETURN 0
		END
    END
    
    SET @msg = 'Unable to find the PO.'
    
    RETURN 1
END


GO
GRANT EXECUTE ON  [dbo].[vspSMPOFindBatch] TO [public]
GO
