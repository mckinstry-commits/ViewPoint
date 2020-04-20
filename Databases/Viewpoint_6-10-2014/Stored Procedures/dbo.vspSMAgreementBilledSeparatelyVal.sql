SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Dave Solheim
-- Create date: 03/08/12
-- Description:	Determines if Billing schedules exist for a given Service
-- Modification: MDB 3/5/2013 Added Revenue Deferral Check for Billed Seperately TFS#40933
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementBilledSeparatelyVal]
	@SMCo bCompany, 
	@Agreement varchar(15), 
	@Revision int,
	@Service int,
	@BilledSeparately bYN, 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @HasBillingSchedule bit
	SELECT @HasBillingSchedule = 0

	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF @Agreement IS NULL
	BEGIN
		SET @msg = 'Missing SM Agreement!'
		RETURN 1
	END
	
	IF @Revision  IS NULL
	BEGIN
		SET @msg = 'Missing SM Agreement Revision!'
		RETURN 1
	END	
	
	SELECT @HasBillingSchedule = 1 FROM dbo.SMAgreementServiceBillingSched 
		WHERE SMCo = @SMCo 
		AND Agreement = @Agreement 
		AND Revision = @Revision
		AND [Service] = @Service
		
	IF @HasBillingSchedule = 1 AND NOT @BilledSeparately = 'Y'
	BEGIN
		SET @msg = 'All billing schedules must be deleted before clearing Billed Separately'
		RETURN 1
	END
	
	IF @BilledSeparately <> 'Y' AND EXISTS (SELECT 1
		FROM dbo.SMAgreementRevenueDeferral WHERE @SMCo = dbo.SMAgreementRevenueDeferral.SMCo AND @Agreement = dbo.SMAgreementRevenueDeferral.Agreement AND @Revision = dbo.SMAgreementRevenueDeferral.Revision AND @Service = dbo.SMAgreementRevenueDeferral.[Service])		
	BEGIN
		SET @msg = 'All revenue deferrals must be deleted before you can remove Billed Separately.'
		RETURN 1
	END
		
	RETURN 0
END





GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementBilledSeparatelyVal] TO [public]
GO