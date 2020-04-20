SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/4/11
-- Description:	Preps work completed records by creating session copies of records.
--				Once all the records have been copied the invoice is added to the sessions.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMSessionAddInvoice]
	@SMSessionID bigint, @SMInvoiceID bigint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Create the invoice session record so that the invoice now shows up for the session.
	INSERT dbo.vSMInvoiceSession (SMInvoiceID, SMSessionID, SessionInvoice)
	SELECT @SMInvoiceID, @SMSessionID, ISNULL(MAX(SessionInvoice), 0) + 1
	FROM dbo.vSMInvoiceSession
	WHERE SMSessionID = @SMSessionID
END

GO
GRANT EXECUTE ON  [dbo].[vspSMSessionAddInvoice] TO [public]
GO
