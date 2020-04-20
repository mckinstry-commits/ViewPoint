SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		David Solheim
-- Create date: 3/9/12
-- Description:	Determines the amount of money remaining to be billed
--				for a given agreement
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetTotalRemainingAgreement]
(
	@SMCo bCompany,
	@Agreement varchar(15),
	@Revision int	
)
RETURNS @TotalRemainingTable TABLE
	(
		TotalRemaining bDollar NULL
	)
AS
BEGIN
	DECLARE @AgreementRowsTotal bDollar
	DECLARE @TotalRemaining bDollar
	DECLARE @AgreementPrice bDollar
	DECLARE @TotalPrice bDollar
	DECLARE @NonSeperateRowsTotal bDollar

	SELECT @AgreementPrice = ISNULL(AgreementPrice, 0) FROM SMAgreement
	WHERE SMCo = @SMCo 
	AND Revision = @Revision 
	AND Agreement = @Agreement
	
	SELECT @NonSeperateRowsTotal = SUM(PricingPrice) FROM SMAgreementService
	WHERE SMCo = @SMCo 
	AND Revision = @Revision 
	AND Agreement = @Agreement
	AND PricingMethod = 'P'
	AND BilledSeparately = 'N'
	
	SET @TotalPrice = @AgreementPrice + ISNULL(@NonSeperateRowsTotal, 0)

	SELECT @AgreementRowsTotal = SUM(BillingAmount) FROM SMAgreementBillingSchedule
	WHERE SMCo = @SMCo 
	AND Revision = @Revision 
	AND Agreement = @Agreement
	AND [Service] IS NULL
	AND BillingType = 'S'
	
	SET @TotalRemaining = @TotalPrice - ISNULL(@AgreementRowsTotal, 0)
	
	INSERT INTO @TotalRemainingTable VALUES (@TotalRemaining)
	
	RETURN 

END

GO
GRANT SELECT ON  [dbo].[vfSMGetTotalRemainingAgreement] TO [public]
GO
