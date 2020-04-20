SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Matthew Bradford
-- Create date: 03/05/13
-- Description:	Determines if deferrals exists on agreement #TFS40933
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementRevenueRecVal]
	@SMCo bCompany, 
	@Agreement varchar(15), 
	@Revision int,
	@RevenueDeferral Char,
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @RevenueDeferral <> 'S' AND EXISTS (SELECT 1
		FROM dbo.SMAgreementRevenueDeferral WHERE @SMCo = dbo.SMAgreementRevenueDeferral.SMCo AND @Agreement = dbo.SMAgreementRevenueDeferral.Agreement AND @Revision = dbo.SMAgreementRevenueDeferral.Revision)		
	BEGIN
		SET @msg = 'All revenue deferrals must be deleted before you can switch to Billed.'
		RETURN 1
	END
		
	RETURN 0
END





GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementRevenueRecVal] TO [public]
GO
