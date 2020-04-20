SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/7/13
-- Description:	Used to start a session. Can specify the SMSessionID or the SMInvoiceID which will 
--				either return the session the invoice is already a part of, otherwise a new session
--				will be created and the invoice will be added to it.
-- =============================================
CREATE PROCEDURE dbo.vspSMSessionStart
	@SMSessionID int = NULL OUTPUT, @SMInvoiceID bigint = NULL, @SMCo bCompany = NULL,
	@Prebilling bit = NULL OUTPUT, @msg varchar(256) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--If an invoice is passed in then the assoicated session should be
	--passed back out
	IF @SMSessionID IS NULL AND @SMInvoiceID IS NOT NULL
	BEGIN
		SELECT @SMSessionID = SMSessionID
		FROM dbo.vSMInvoiceSession
		WHERE SMInvoiceID = @SMInvoiceID
	END

	--When a session is not passed in then a new one should be created
	IF @SMSessionID IS NULL
	BEGIN
		BEGIN TRY
			BEGIN TRAN

			IF @Prebilling IS NULL
			BEGIN
				SET @Prebilling = 0
			END

			SELECT @SMSessionID = ISNULL(MAX(SMSessionID), 0) + 1
			FROM dbo.vSMSession

			INSERT dbo.vSMSession (SMSessionID, SMCo, Prebilling)
			VALUES (@SMSessionID, @SMCo, @Prebilling)

			--If an invoice was passed in then it should be added to the session.
			IF @SMInvoiceID IS NOT NULL
			BEGIN
				INSERT dbo.vSMInvoiceSession (SMInvoiceID, SMSessionID, SessionInvoice)
				VALUES (@SMInvoiceID, @SMSessionID, 1)
			END

			COMMIT TRAN

			RETURN 0
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
			SET @msg = ERROR_MESSAGE()

			RETURN 1
		END CATCH
	END

    BEGIN TRY
		--If we are able to read the session record using NOWAIT right away then IsLocked will be set to 0
		--otherwise an exception will be thrown and we will grab the user that has it locked
        SELECT @Prebilling = Prebilling
        FROM dbo.vSMSession WITH (NOWAIT)
        WHERE SMSessionID = @SMSessionID

		IF @@ROWCOUNT <> 1
		BEGIN
			SET @msg = 'Session doesn''t exist'
			RETURN 1
		END

		RETURN 0
    END TRY
    BEGIN CATCH
		--The record is locked so we read the username using NOLOCK so that we aren't prevented by the lock from reading the record
        SELECT @msg = dbo.vfToString(UserName) + ' is currently in this session. Please wait until they are done.'
        FROM dbo.vSMSession WITH (NOLOCK)
        WHERE SMSessionID = @SMSessionID

		RETURN 1
    END CATCH
END

GO
GRANT EXECUTE ON  [dbo].[vspSMSessionStart] TO [public]
GO
