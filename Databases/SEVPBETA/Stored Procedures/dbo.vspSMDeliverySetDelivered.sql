SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 9/28/11
-- Description:	Set an invoice delivered information by SMDeliveryReportID.
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMDeliverySetDelivered]
	@SMDeliveryGroupID AS int, 
	@SMDeliveryReportID AS int,
	@DeliveredDate AS datetime,
	@DeliveredBy AS varchar(128),
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	UPDATE dbo.SMInvoice SET DeliveredBy = @DeliveredBy, DeliveredDate = @DeliveredDate 
	FROM dbo.SMInvoice
	INNER JOIN dbo.SMDeliveryGroupInvoice ON SMDeliveryGroupInvoice.SMInvoiceID = SMInvoice.SMInvoiceID
	WHERE SMDeliveryGroupInvoice.SMDeliveryGroupID = @SMDeliveryGroupID 
		AND SMDeliveryGroupInvoice.SMDeliveryReportID = @SMDeliveryReportID
	
	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMDeliverySetDelivered] TO [public]
GO
