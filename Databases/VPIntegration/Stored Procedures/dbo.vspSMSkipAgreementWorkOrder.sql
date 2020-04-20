SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		David Solheim
-- Create date: 3/27/2012
-- Description:	Skips a workorder during processing
-- =============================================
CREATE PROCEDURE [dbo].[vspSMSkipAgreementWorkOrder]
	@SMCo bCompany, 
	@Agreement varchar(15), 
	@Revision int, 
	@Service int,
	@ServiceDate bDate, 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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
		SET @msg = 'Missing SM Agreement Revision!'
		RETURN 1
	END
	
	IF (@Service IS NULL)
	BEGIN
		SET @msg = 'Missing SM Service!'
		RETURN 1
	END
	
	IF (@ServiceDate IS NULL)
	BEGIN
		SET @msg = 'Missing Scheduled Date!'
		RETURN 1
	END
	
	BEGIN TRY
		
		-- Mark the service as scheduled
		INSERT INTO dbo.SMAgreementServiceDate (SMCo, Agreement, Revision, [Service], ServiceDate, WorkOrder, Scope)
		VALUES (@SMCo, @Agreement, @Revision, @Service, @ServiceDate, null, null)
		
	END TRY
	BEGIN CATCH
		SELECT @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMSkipAgreementWorkOrder] TO [public]
GO
