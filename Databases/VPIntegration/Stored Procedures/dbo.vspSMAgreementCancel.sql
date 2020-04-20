SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		David Solheim
-- Create date: 6/19/12
-- Description:	Cancel a specified agreement.
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMAgreementCancel]
	@SMCo AS bCompany, 
	@Agreement AS varchar(15), 
	@Revision int,
	@Uncancel bit,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;
	
	DECLARE @Status int, @rcode int, @errmsg varchar(255)
	
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
	IF (@@ROWCOUNT = 0)
	BEGIN
		-- Validated that Agreement/Revision is valid
		IF @Uncancel = 1
		BEGIN
			SELECT @msg = 'Unable to uncancel because the Agreement/Revision was invalid.'
		END
		ELSE
		BEGIN
			SELECT @msg = 'Unable to cancel because the Agreement/Revision was invalid.'
		END
		
		RETURN 1
	END
	
	-- Cancel the Agreement
	IF @Uncancel = 1
	BEGIN
		-- Validate that the agreement is in a status that can be uncancelled
		IF @Status <> 1
		BEGIN
			SELECT @msg = 'The agreement status must be cancelled to be able to uncancel it.'
			RETURN 1
		END
		
		--Make sure all other revisions with the same previous revision are cancelled quotes otherwise prevent the quote from being re-opened so
		--that multiple open quotes do not exist and no quote can be re-opened when some other revision has already been activated against the previous revision.
		IF EXISTS(SELECT 1 
			FROM dbo.SMAgreementExtended
				INNER JOIN dbo.SMAgreementExtended OtherAgreementRevisions ON SMAgreementExtended.SMCo = OtherAgreementRevisions.SMCo AND SMAgreementExtended.Agreement = OtherAgreementRevisions.Agreement AND SMAgreementExtended.PreviousRevision = OtherAgreementRevisions.PreviousRevision
			WHERE SMAgreementExtended.SMCo = @SMCo AND SMAgreementExtended.Agreement = @Agreement AND SMAgreementExtended.Revision = @Revision AND OtherAgreementRevisions.RevisionStatus <> 1)
		BEGIN
			SELECT @msg = 'Changes have been made since this renewal was created so it can no longer be opened.'
			RETURN 1
		END
	
		UPDATE dbo.SMAgreement
		SET DateCancelled = NULL
		WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
	END
	ELSE
	BEGIN
		-- Validate that the agreement is in a status that can be cancelled
		IF @Status <> 0
		BEGIN
			SELECT @msg = 'The agreement status must be quote to be able to cancel it.'
			RETURN 1
		END
	
		UPDATE dbo.SMAgreement
		SET DateCancelled = dbo.vfDateOnly()
		WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementCancel] TO [public]
GO
