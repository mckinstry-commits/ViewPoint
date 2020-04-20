SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		David Solheim
-- Create date: 3/19/13
-- Description:	Get the information for approving a WO Quote
--				
-- Modified:	
--				
-- =============================================

CREATE PROCEDURE [dbo].[vspSMWOQuoteApproveInfo]
	@SMCo AS bCompany, 
	@WOQuote AS varchar(15),
	@WOQuoteDesc varchar(max) OUTPUT,
	@CustGroup bGroup OUTPUT,
	@Customer bCustomer OUTPUT,
	@CustomerDesc varchar(max) OUTPUT,
	@ServiceSite varchar(20) OUTPUT,
	@ServiceSiteDesc varchar(max) OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;
	
	SELECT 
		@WOQuoteDesc = SMWorkOrderQuote.[Description],
		@CustGroup = SMWorkOrderQuote.CustGroup,
		@Customer = SMWorkOrderQuote.Customer,
		@CustomerDesc = SMCustomerInfo.Name,
		@ServiceSite = SMWorkOrderQuote.ServiceSite,
		@ServiceSiteDesc = SMServiceSite.[Description]
	FROM dbo.SMWorkOrderQuote
	LEFT JOIN SMCustomerInfo
		ON SMWorkOrderQuote.SMCo = SMCustomerInfo.SMCo
		AND SMWorkOrderQuote.CustGroup = SMCustomerInfo.CustGroup
		AND SMWorkOrderQuote.Customer = SMCustomerInfo.Customer
	LEFT JOIN SMServiceSite
		ON SMWorkOrderQuote.SMCo = SMServiceSite.SMCo
		AND SMWorkOrderQuote.ServiceSite = SMServiceSite.ServiceSite
	WHERE SMWorkOrderQuote.SMCo = @SMCo AND WorkOrderQuote = @WOQuote

    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWOQuoteApproveInfo] TO [public]
GO
