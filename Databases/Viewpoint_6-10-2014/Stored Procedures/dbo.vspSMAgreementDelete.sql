SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 6/19/12
-- Description:	Cancel a specified agreement.
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMAgreementDelete]
	@SMCo AS bCompany, 
	@Agreement AS varchar(15), 
	@Revision int,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;
	
	DECLARE @Status int, @rcode int, @errmsg varchar(255), @rows int, @RevisionType tinyint
	
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

	SELECT @Status = [Status], @RevisionType = RevisionType
	FROM dbo.SMAgreement
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
	
	SELECT @rows = @@ROWCOUNT
	
	-- Validated that Agreement/Revision is valid
	IF (@rows = 0)
	BEGIN
		SELECT @msg = 'Unable to delete because the Agreement/Revision was invalid.'
		RETURN 1
	END
	-- Validate that the revision is an amendment
	IF (@RevisionType <> 2)
	BEGIN
		SELECT @msg = 'The revision must be an amendment quote to be able to be deleted.'
		RETURN 1
	END
	
	-- Validate that the agreement is in a status that can be cancelled
	IF (@Status <> 0)
	BEGIN
		SELECT @msg = 'The agreement revision status must be quote to be able to be deleted.'
		RETURN 1
	END
	
	-- Delete the Agreement
	DELETE dbo.SMAgreementServiceTask
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
		
	DELETE dbo.SMAgreementBillingSchedule
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision

	DELETE dbo.SMAgreementRevenueDeferral
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision

	DELETE dbo.SMAgreementService
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision

	DELETE dbo.SMAgreement
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
	
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementDelete] TO [public]
GO
