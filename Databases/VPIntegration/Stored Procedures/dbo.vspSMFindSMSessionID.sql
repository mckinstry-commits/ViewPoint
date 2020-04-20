SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 4/18/12
-- Description:	Pass it a invoiceID and get a sessionID
-- =============================================
CREATE PROCEDURE [dbo].[vspSMFindSMSessionID]
	@SMInvoiceID bigint, @SMSessionID int OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF EXISTS(SELECT 1 FROM dbo.vSMInvoiceSession WHERE SMInvoiceID = @SMInvoiceID)
	BEGIN
		SELECT @SMSessionID = SMSessionID
		FROM dbo.vSMInvoiceSession
		WHERE SMInvoiceID = @SMInvoiceID
	END 
	ELSE
	BEGIN 
		RETURN 1
	END
	
	RETURN 0
	
END

GO
GRANT EXECUTE ON  [dbo].[vspSMFindSMSessionID] TO [public]
GO
