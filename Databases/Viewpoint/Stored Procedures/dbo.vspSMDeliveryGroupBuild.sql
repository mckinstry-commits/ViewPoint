SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 9/26/11
-- Description:	Make a modification to a delivery group.  The modification is based
--				on the Action parameter.  This will Add, Remove or Remove all Invoices
--				from the SMDeliveryGroup.
-- Modified:	

-- Parameter Notes:	Action - [PreviewInvoice, PreviewAll, Deliver, DeliverInvoiced]
--					SMInvoiceID - Required when the Action is PreviewInvoice.
-- =============================================

CREATE PROCEDURE [dbo].[vspSMDeliveryGroupBuild]
	@SMDeliveryGroupID AS int, 
	@Action AS varchar(20),
	@SMInvoiceID as bigint = NULL,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @DefaultAgreementInvoiceReportID int, @DefaultWorkOrderInvoiceReportID int, @SMSessionID int
	SELECT @DefaultAgreementInvoiceReportID = 1222, @DefaultWorkOrderInvoiceReportID = 1118
	
	-- Set Delivery Report ID in SMDeliveryGroupInvoice to NULL
	UPDATE dbo.SMDeliveryGroupInvoice SET SMDeliveryReportID = NULL WHERE SMDeliveryGroupID = @SMDeliveryGroupID
	
	-- Clear the Delivery Reports
	DELETE FROM dbo.SMDeliveryReport WHERE SMDeliveryGroupID = @SMDeliveryGroupID
	
	-- Auto populate if this has a SessionID
	SELECT @SMSessionID = SMSessionID FROM dbo.SMDeliveryGroup WHERE SMDeliveryGroupID = @SMDeliveryGroupID AND SMSessionID IS NOT NULL
	IF (@@ROWCOUNT > 0)
	BEGIN
		DELETE FROM dbo.SMDeliveryGroupInvoice WHERE SMDeliveryGroupID = @SMDeliveryGroupID
		
		IF (@Action = 'PreviewInvoice')
		BEGIN
			INSERT INTO dbo.SMDeliveryGroupInvoice (SMDeliveryGroupID, SMInvoiceID)
			(SELECT @SMDeliveryGroupID, SMInvoiceID FROM dbo.SMInvoiceSession WHERE SMSessionID = @SMSessionID AND SMInvoiceID = @SMInvoiceID)
		END
		ELSE
		BEGIN
			INSERT INTO dbo.SMDeliveryGroupInvoice (SMDeliveryGroupID, SMInvoiceID)
			(SELECT @SMDeliveryGroupID, SMInvoiceID FROM dbo.SMInvoiceSession WHERE SMSessionID = @SMSessionID AND (SessionDeliver = 'Y' OR ((@Action = 'DeliverInvoiced' OR @Action = 'PreviewAll') AND Invoiced = 1)))
		END
	END
	
	-- Populate SMDeliveryReport and update SMDeliveryGroupInvoice depending on action type
	IF(@Action = 'PreviewInvoice')
	BEGIN
		IF (@SMInvoiceID IS NULL)
		BEGIN
			SET @msg = 'An SMInvoiceID must be provided to perform the action.'
			RETURN 1
		END
	
		-- Insert the one SMDeliveryReport record and back fill the DeliveryReportID
		INSERT INTO dbo.SMDeliveryReport (SMDeliveryGroupID, ReportID) SELECT @SMDeliveryGroupID, ISNULL(ReportID, CASE InvoiceType WHEN 'A' THEN @DefaultAgreementInvoiceReportID WHEN 'W' THEN @DefaultWorkOrderInvoiceReportID END) FROM dbo.SMInvoice WHERE SMInvoiceID = @SMInvoiceID
		UPDATE dbo.SMDeliveryGroupInvoice SET SMDeliveryReportID = SCOPE_IDENTITY() WHERE SMDeliveryGroupID = @SMDeliveryGroupID AND SMInvoiceID = @SMInvoiceID
	END
	ELSE IF (@Action = 'PreviewAll')
	BEGIN
		-- Insert one SMDeliveryReport record for each reportID
		INSERT INTO dbo.SMDeliveryReport (SMDeliveryGroupID, ReportID) 
		SELECT  @SMDeliveryGroupID, ReportID
		FROM
			(SELECT ISNULL(SMInvoice.ReportID, CASE SMInvoice.InvoiceType WHEN 'A' THEN @DefaultAgreementInvoiceReportID WHEN 'W' THEN @DefaultWorkOrderInvoiceReportID END) AS ReportID
			FROM dbo.SMInvoice
				INNER JOIN dbo.SMDeliveryGroupInvoice ON SMDeliveryGroupInvoice.SMInvoiceID = SMInvoice.SMInvoiceID
			WHERE SMDeliveryGroupInvoice.SMDeliveryGroupID = @SMDeliveryGroupID) Reports
		GROUP BY ReportID
		
		-- Update the SMDeliveryGroupInvoice with the appropriate SMDeliveryReportID
		UPDATE dbo.SMDeliveryGroupInvoice SET SMDeliveryGroupInvoice.SMDeliveryReportID = SMDeliveryReport.SMDeliveryReportID
		FROM dbo.SMDeliveryGroupInvoice
		INNER JOIN dbo.SMInvoice ON SMInvoice.SMInvoiceID = SMDeliveryGroupInvoice.SMInvoiceID
		INNER JOIN dbo.SMDeliveryReport ON SMDeliveryReport.SMDeliveryGroupID = SMDeliveryGroupInvoice.SMDeliveryGroupID AND SMDeliveryReport.ReportID = ISNULL(SMInvoice.ReportID, CASE SMInvoice.InvoiceType WHEN 'A' THEN @DefaultAgreementInvoiceReportID WHEN 'W' THEN @DefaultWorkOrderInvoiceReportID END)

	END
	ELSE IF(@Action = 'Deliver' OR @Action = 'DeliverInvoiced')
	BEGIN
		-- Insert one SMDeliveryReport record for each Invoice and backfill the SMDeliveryReportID in SMDeliveryGroupInvoice
		DECLARE @CurrentID int
		SET @CurrentID = 0

		BeginDeliverLoop:
		SELECT TOP 1 @CurrentID = SMDeliveryGroupInvoiceID FROM dbo.SMDeliveryGroupInvoice WHERE SMDeliveryGroupID = @SMDeliveryGroupID AND SMDeliveryReportID IS NULL
		IF (@@ROWCOUNT = 1)
		BEGIN
			INSERT INTO dbo.SMDeliveryReport (SMDeliveryGroupID, ReportID) 
			(
				SELECT @SMDeliveryGroupID, ISNULL(SMInvoice.ReportID, CASE SMInvoice.InvoiceType WHEN 'A' THEN @DefaultAgreementInvoiceReportID WHEN 'W' THEN @DefaultWorkOrderInvoiceReportID END) FROM dbo.SMDeliveryGroupInvoice
				INNER JOIN dbo.SMInvoice ON SMInvoice.SMInvoiceID = SMDeliveryGroupInvoice.SMInvoiceID
				WHERE SMDeliveryGroupID = @SMDeliveryGroupID AND SMDeliveryGroupInvoiceID = @CurrentID
			)
			
			UPDATE dbo.SMDeliveryGroupInvoice SET SMDeliveryReportID = SCOPE_IDENTITY() WHERE SMDeliveryGroupInvoiceID = @CurrentID
			GOTO BeginDeliverLoop
		END
	END
	
	
	-- Return SMDeliveryReport table for the SMDeliveryGroup
	SELECT * FROM dbo.SMDeliveryReport WHERE SMDeliveryGroupID = @SMDeliveryGroupID
	
	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMDeliveryGroupBuild] TO [public]
GO
