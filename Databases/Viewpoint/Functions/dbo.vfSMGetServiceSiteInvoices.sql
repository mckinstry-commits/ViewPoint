SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/11/12
-- Description:	Retrieves SMInvoiceID that are related to a service site
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetServiceSiteInvoices]
(	
	@SMCo bCompany, @ServiceSite varchar(20)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT SMAgreementBillingSchedule.SMInvoiceID
    FROM dbo.SMAgreementService
        INNER JOIN dbo.SMAgreementBillingSchedule ON SMAgreementService.SMCo = SMAgreementBillingSchedule.SMCo AND SMAgreementService.Agreement = SMAgreementBillingSchedule.Agreement AND SMAgreementService.Revision = SMAgreementBillingSchedule.Revision AND (SMAgreementService.[Service] = SMAgreementBillingSchedule.[Service] OR SMAgreementBillingSchedule.[Service] IS NULL)
    WHERE SMAgreementService.SMCo = @SMCo AND SMAgreementService.ServiceSite = @ServiceSite AND SMAgreementBillingSchedule.SMInvoiceID IS NOT NULL
    UNION
    SELECT SMInvoiceID 
    FROM dbo.SMWorkCompleted
    WHERE SMCo = @SMCo AND ServiceSite = @ServiceSite AND SMInvoiceID IS NOT NULL
)
GO
GRANT SELECT ON  [dbo].[vfSMGetServiceSiteInvoices] TO [public]
GO
