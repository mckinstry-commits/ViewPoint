SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 7/30/12
-- Description:	Validation for SM Invoice
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMInvoiceVal]
	@SMInvoiceID AS bigint, 
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF (@SMInvoiceID IS NULL)
	BEGIN
		SET @msg = 'Missing SM Invoice ID!'
		RETURN 1
	END
    
	IF NOT EXISTS(SELECT 1 FROM dbo.SMInvoice WHERE SMInvoiceID = @SMInvoiceID)
	BEGIN
		SELECT @msg = 'SM Invoice does not exist.'
		RETURN 1
	END
    
    RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMInvoiceVal] TO [public]
GO
