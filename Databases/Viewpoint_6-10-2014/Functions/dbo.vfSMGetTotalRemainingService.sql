SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		David Solheim
-- Create date: 3/9/12
-- Description:	Determines the amount of money remaining to be billed
--				for a given service
--	Modified:	JVH	2/25/13 TFS-40933 Modified to also output the deferral total remaining
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetTotalRemainingService]
(
	@SMCo bCompany,
	@Agreement varchar(15),
	@Revision int,
	@Service int
)
RETURNS TABLE
AS
RETURN
(
	SELECT SMAgreementService.PricingPrice, GetDeferralTotal.DeferralTotal, GetBillingScheduleTotal.BillingScheduleTotal,
		--The price should only be deducted from if the service has been designated as being billed seperately.
		ISNULL(CASE WHEN SMAgreementService.BilledSeparately = 'Y' THEN SMAgreementService.PricingPrice END, 0) - ISNULL(GetBillingScheduleTotal.BillingScheduleTotal, 0) BillingTotalRemaining,
		--The price should only be deducted from if the service has been designated as being billed seperately and if the agreement was setup for revenue deferral.
		ISNULL(CASE WHEN SMAgreementService.BilledSeparately = 'Y' AND SMAgreement.RevenueRecognition = 'S' THEN SMAgreementService.PricingPrice END, 0) - ISNULL(GetDeferralTotal.DeferralTotal, 0) DeferralTotalRemaining
	FROM dbo.SMAgreementService
		INNER JOIN dbo.SMAgreement ON SMAgreementService.SMCo = SMAgreement.SMCo AND SMAgreementService.Agreement = SMAgreement.Agreement AND SMAgreementService.Revision = SMAgreement.Revision
		CROSS APPLY
		(
			SELECT SUM(BillingAmount) BillingScheduleTotal
			FROM dbo.SMAgreementServiceBillingSched
			WHERE SMAgreementService.SMCo = SMAgreementServiceBillingSched.SMCo AND SMAgreementService.Agreement = SMAgreementServiceBillingSched.Agreement AND SMAgreementService.[Service] = SMAgreementServiceBillingSched.[Service] AND SMAgreementService.Revision = SMAgreementServiceBillingSched.Revision AND 
				--Only include schedule billings
				SMAgreementServiceBillingSched.BillingType = 'S'
		) GetBillingScheduleTotal
		CROSS APPLY
		(
			SELECT SUM(Amount) DeferralTotal
			FROM dbo.SMAgreementServiceRevDefer
			WHERE SMAgreementService.SMCo = SMAgreementServiceRevDefer.SMCo AND SMAgreementService.Agreement = SMAgreementServiceRevDefer.Agreement AND SMAgreementService.[Service] = SMAgreementServiceRevDefer.[Service] AND SMAgreementService.Revision = SMAgreementServiceRevDefer.Revision
		) GetDeferralTotal
	WHERE SMAgreementService.SMCo = @SMCo AND SMAgreementService.Agreement = @Agreement AND SMAgreementService.[Service] = @Service AND SMAgreementService.Revision = @Revision
)
GO
GRANT SELECT ON  [dbo].[vfSMGetTotalRemainingService] TO [public]
GO
