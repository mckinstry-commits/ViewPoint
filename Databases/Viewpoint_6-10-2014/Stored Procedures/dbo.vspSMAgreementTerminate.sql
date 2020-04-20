SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 6/7/12
-- Description:	Terminate a specified agreement.
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMAgreementTerminate]
	@SMCo AS bCompany, 
	@Agreement AS varchar(15), 
	@Revision int,
	@DateTerminated smalldatetime,
	@CancelQuote bYN,
	@DeleteNewWorkOrders bYN = 'N',
	@AmendmentRevision int,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;
	
	DECLARE @Status int, @rcode int
	
	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF (@Agreement IS NULL)
	BEGIN
		SET @msg = 'Missing SM Agreement!'
		RETURN 1
	END
	
	IF (@Revision IS NULL)
	BEGIN
		SET @msg = 'Missing SM Revision!'
		RETURN 1
	END

	SELECT @Status = [Status]
	FROM dbo.SMAgreement
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
	
	-- Validated that Agreement/Revision is valid
	IF (@@ROWCOUNT = 0)
	BEGIN
		SELECT @msg = 'Unable to terminate because the Agreement/Revision was invalid.'
		RETURN 1
	END
	
	-- Validate that the agreement is in a status that can be terminated
	IF (@Status <> 2)
	BEGIN
		SELECT @msg = 'The agreement status must be active to be able to terminate it.'
		RETURN 1
	END
	
	-- Terminate the Agreement
	IF @DateTerminated IS NULL
		SET @DateTerminated = dbo.vfDateOnly()

	BEGIN TRY
		BEGIN TRAN

		IF (@CancelQuote = 'Y')
		BEGIN
			--Cancel any quotes that haven't been already.
			UPDATE dbo.SMAgreementExtended
			SET DateCancelled = @DateTerminated
			WHERE SMCo = @SMCo AND Agreement = @Agreement AND PreviousRevision = @Revision AND RevisionStatus = 0
		END

		-- Delete 'New' Work Orders for this agreement
		IF (@DeleteNewWorkOrders = 'Y')
		BEGIN
			EXEC @rcode = dbo.vspSMAgreementDeleteNewWorkOrders @SMCo = @SMCo, @Agreement = @Agreement, @Revision = @Revision, @msg = @msg OUTPUT
			
			IF (@rcode <> 0)
			BEGIN
				ROLLBACK TRAN
				RETURN @rcode
			END
		END
		
		UPDATE dbo.SMAgreement
		SET DateTerminated = @DateTerminated, AmendmentRevision = @AmendmentRevision
		WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		--If the error is due to a transaction count mismatch in vspSMAgreementDeleteNewWorkOrders
		--then it is more helpful to keep the error message from vspSMAgreementDeleteNewWorkOrders.
		IF ERROR_NUMBER() <> 266 SET @msg = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		RETURN 1
	END CATCH
	
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementTerminate] TO [public]
GO
