SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 4/18/2012
-- Description:	Selects Work Orders
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkOrder] 
	@SMCo bCompany,
	@msg nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select top 100
		work.SMCo,
		work.WorkOrder,
		work.SMWorkOrderID,
		work.Customer,
		work.ServiceSite,
		work.Description as WorkOrderDescription,
		SMServiceSite.Description as SiteDescription
	from dbo.SMWorkOrder work
	LEFT JOIN SMServiceSite
		ON work.SMCo = SMServiceSite.SMCo
		AND work.ServiceSite = SMServiceSite.ServiceSite	
	where
		work.SMCo = @SMCo

END


GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrder] TO [public]
GO
