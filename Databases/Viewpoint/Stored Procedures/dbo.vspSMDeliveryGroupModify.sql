SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 9/22/11
-- Description:	Make a modification to a delivery group.  The modification is based
--				on the Action parameter.  This will Add, Remove or Remove all Invoices
--				from the SMDeliveryGroup.
-- Modified:	

-- Parameter Notes:	Action - [AddInvoice, RemoveInvoice, RemoveAll]
--					SMInvoiceID - Required when the Action is AddInvoice or RemoveInvoice.
-- =============================================

CREATE PROCEDURE [dbo].[vspSMDeliveryGroupModify]
	@SMDeliveryGroupID AS int,
	@Action AS varchar(20),
	@SMInvoiceID AS bigint = NULL, 
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF (@Action IS NULL)
	BEGIN
		SET @msg = 'Invalid Delivery Group action.'
		RETURN 1
	END

	IF ((@Action = 'AddInvoice' OR @Action = 'RemoveInvoice') AND @SMInvoiceID IS NULL)
	BEGIN
		SET @msg = 'An SMInvoiceID must be provided to perform the action.'
		RETURN 1
	END
	
	
	IF (@Action = 'AddInvoice')
	BEGIN
		IF (NOT EXISTS(SELECT * FROM dbo.SMDeliveryGroupInvoice WHERE SMDeliveryGroupID = @SMDeliveryGroupID AND SMInvoiceID = @SMInvoiceID))
		BEGIN
			INSERT INTO dbo.SMDeliveryGroupInvoice (SMDeliveryGroupID, SMInvoiceID) VALUES (@SMDeliveryGroupID, @SMInvoiceID)
		END
	END
	ELSE IF (@Action = 'RemoveInvoice')
	BEGIN
		DELETE FROM dbo.SMDeliveryGroupInvoice WHERE SMDeliveryGroupID = @SMDeliveryGroupID AND SMInvoiceID = @SMInvoiceID
	END
	ELSE IF (@Action = 'RemoveAll')
	BEGIN
		DELETE FROM dbo.SMDeliveryGroupInvoice WHERE SMDeliveryGroupID = @SMDeliveryGroupID
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMDeliveryGroupModify] TO [public]
GO
