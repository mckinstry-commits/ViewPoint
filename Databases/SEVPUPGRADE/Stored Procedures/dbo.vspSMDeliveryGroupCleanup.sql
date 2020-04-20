SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 9/26/11
-- Description:	Clean up a delivery group.
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMDeliveryGroupCleanup]
	@SMDeliveryGroupID AS int,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Set Delivery Report ID in SMDeliveryGroupInvoice to NULL
	UPDATE dbo.SMDeliveryGroupInvoice SET SMDeliveryReportID = NULL WHERE SMDeliveryGroupID = @SMDeliveryGroupID
	
	-- Clear the Delviery Group
	DELETE FROM dbo.SMDeliveryGroup WHERE SMDeliveryGroupID = @SMDeliveryGroupID
	
	RETURN 0
END



GO
GRANT EXECUTE ON  [dbo].[vspSMDeliveryGroupCleanup] TO [public]
GO
