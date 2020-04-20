SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		David Solheim
-- Create date: 3/9/12
-- Description:	Determines the amount of money remaining to be billed
--				for a given agreement
--	Modified:	JVH	2/25/13 TFS-40933 Modified to also output the deferral total remaining
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetTotalRemainingAgreement]
(
	@SMCo bCompany,
	@Agreement varchar(15),
	@Revision int
)
RETURNS TABLE
AS
RETURN
(
	SELECT SMAgreement.AgreementPrice, GetServiceBillingTotal.ServiceBillingTotal, GetDeferralTotal.DeferralTotal, GetBillingScheduleTotal.BillingScheduleTotal,
		ISNULL(SMAgreement.AgreementPrice, 0) + ISNULL(GetServiceBillingTotal.ServiceBillingTotal, 0) - ISNULL(GetBillingScheduleTotal.BillingScheduleTotal, 0) BillingTotalRemaining,
		--The price should only be deducted from if the agreement was setup for revenue deferral.
		CASE WHEN SMAgreement.RevenueRecognition = 'S' THEN ISNULL(SMAgreement.AgreementPrice, 0) + ISNULL(GetServiceBillingTotal.ServiceBillingTotal, 0) ELSE 0 END - ISNULL(GetDeferralTotal.DeferralTotal, 0) DeferralTotalRemaining
	FROM dbo.SMAgreement
		CROSS APPLY
		(
			SELECT SUM(PricingPrice) ServiceBillingTotal
			FROM dbo.SMAgreementService
			WHERE SMAgreement.SMCo = SMAgreementService.SMCo AND SMAgreement.Agreement = SMAgreementService.Agreement AND SMAgreement.Revision = SMAgreementService.Revision AND 
				--Only include the prices from periodic billings that aren't being billed seperately
				SMAgreementService.PricingMethod = 'P' AND SMAgreementService.BilledSeparately = 'N'
		) GetServiceBillingTotal
		CROSS APPLY
		(
			SELECT SUM(BillingAmount) BillingScheduleTotal
			FROM dbo.SMAgreementBillingSched
			WHERE SMAgreement.SMCo = SMAgreementBillingSched.SMCo AND SMAgreement.Agreement = SMAgreementBillingSched.Agreement AND SMAgreement.Revision = SMAgreementBillingSched.Revision AND 
				--Only scheduled billings should be included.
				SMAgreementBillingSched.BillingType = 'S'
		) GetBillingScheduleTotal
		CROSS APPLY
		(
			SELECT SUM(Amount) DeferralTotal
			FROM dbo.SMAgreementAgreementRevDefer
			WHERE SMAgreement.SMCo = SMAgreementAgreementRevDefer.SMCo AND SMAgreement.Agreement = SMAgreementAgreementRevDefer.Agreement AND SMAgreement.Revision = SMAgreementAgreementRevDefer.Revision
		) GetDeferralTotal
	WHERE SMAgreement.SMCo = @SMCo AND SMAgreement.Agreement = @Agreement AND SMAgreement.Revision = @Revision
)
GO
GRANT SELECT ON  [dbo].[vfSMGetTotalRemainingAgreement] TO [public]
GO
