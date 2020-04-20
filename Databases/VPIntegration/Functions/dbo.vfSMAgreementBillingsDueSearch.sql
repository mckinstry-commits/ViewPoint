SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
--		Author:	David Solheim
-- Create Date: 03/30/12
-- Description:	Query to get list of items to populate SM Agreement Billings Due.
-- =============================================
CREATE FUNCTION [dbo].[vfSMAgreementBillingsDueSearch]
(
	@SMCo bCompany, 
	@CustGroup bGroup,
	@Customer bCustomer,
	@AgreementType varchar(15),
	@DueWithinTheNextDay int
)
RETURNS TABLE
AS
RETURN
(	
	SELECT 'N' [Create],
		SMCustomerInfo.Name AS SMCustomer, 
		SMAgreement.AgreementType AS SMAgreementType, 
		SMAgreementBillingScheduleExt.Agreement,
		SMAgreementBillingScheduleExt.Revision AS Rev, 
		SMAgreement.[Description] AS AgreementDescription,
		SMAgreementService.[Service], 
		SMAgreementService.[Description] AS ServiceDescription,
		SMAgreement.EffectiveDate, 
		SMAgreement.ExpirationDate, 
		SMAgreementBillingScheduleExt.[Date] AS DueDate, 
		SMAgreementBillingScheduleExt.BillingAmount AS AmountDue,
		SMAgreementBillingScheduleExt.SMAgreementBillingScheduleID,
		SMAgreementBillingScheduleExt.BillingSequence, 
		SMAgreementBillingScheduleExt.BillingCount BillingQuantity
	FROM dbo.SMAgreementBillingScheduleExt
	INNER JOIN SMAgreement ON SMAgreement.SMCo=SMAgreementBillingScheduleExt.SMCo
		 AND SMAgreement.Agreement=SMAgreementBillingScheduleExt.Agreement
		 AND SMAgreement.Revision=SMAgreementBillingScheduleExt.Revision
	LEFT JOIN SMAgreementService ON SMAgreementService.SMCo=SMAgreementBillingScheduleExt.SMCo
		 AND SMAgreementService.Agreement=SMAgreementBillingScheduleExt.Agreement
		 AND SMAgreementService.Revision=SMAgreementBillingScheduleExt.Revision
		 AND SMAgreementService.[Service]=SMAgreementBillingScheduleExt.[Service]
	LEFT JOIN SMServiceSite ON SMAgreementService.SMCo = SMServiceSite.SMCo AND
		 SMAgreementService.ServiceSite = SMServiceSite.ServiceSite
	INNER JOIN SMCustomerInfo ON SMCustomerInfo.SMCo=SMAgreement.SMCo
		 AND SMCustomerInfo.Customer=SMAgreement.Customer
	WHERE SMAgreementBillingScheduleExt.SMInvoiceID IS NULL AND
		SMAgreementBillingScheduleExt.SMCo = @SMCo AND
		SMAgreement.[Status] IN (2,3) AND -- Checks if Active or Expired
		(@Customer IS NULL OR SMAgreement.CustGroup = @CustGroup AND SMAgreement.Customer = @Customer) AND
		(@AgreementType IS NULL OR SMAgreement.AgreementType = @AgreementType) AND
		SMAgreementBillingScheduleExt.[Date] <= DATEADD(d,@DueWithinTheNextDay,dbo.vfDateOnly())
)
GO
GRANT SELECT ON  [dbo].[vfSMAgreementBillingsDueSearch] TO [public]
GO
