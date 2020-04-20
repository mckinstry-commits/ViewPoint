SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Garth Theisen
-- Create date: 7/2/2013
-- Description:	Get site details from work order
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGetSiteDetailFromWorkOrder]
	@SMCo	bCompany,
	@WorkOrder int,
	@msg nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT
		wo.ContactName,
		wo.ContactPhone,
		ssite.Address1,
		ssite.Address2,
		ssite.City,
		ssite.State,
		ssite.Zip,
		ssite.Country,
		ssite.Phone
	FROM dbo.SMWorkOrder wo
		inner join dbo.SMServiceSite ssite on wo.SMCo = ssite.SMCo and wo.ServiceSite = ssite.ServiceSite
	WHERE wo.SMCo = @SMCo AND wo.WorkOrder = @WorkOrder
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMGetSiteDetailFromWorkOrder] TO [public]
GO
