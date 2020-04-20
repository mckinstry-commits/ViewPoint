SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMInvoiceSession]
AS
SELECT  vSMInvoiceSession.SMSessionID, vSMInvoiceSession.SessionInvoice, vSMInvoiceSession.VoidFlag, SMInvoice.*, SMInvoice.SMInvoiceID AS KeyID
FROM dbo.vSMInvoiceSession
	INNER JOIN dbo.SMInvoice ON vSMInvoiceSession.SMInvoiceID = SMInvoice.SMInvoiceID








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/12/2010
-- Description:	Handles the delete since this view has a join
-- =============================================
CREATE TRIGGER [dbo].[vtSMInvoiceSessionViewd]
   ON  [dbo].[SMInvoiceSession]
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DELETE dbo.vSMInvoiceSession
	FROM dbo.vSMInvoiceSession
		INNER JOIN DELETED ON vSMInvoiceSession.SMInvoiceID = DELETED.SMInvoiceID

    DELETE dbo.SMInvoice
    FROM dbo.SMInvoice
		INNER JOIN DELETED ON SMInvoice.SMInvoiceID = DELETED.SMInvoiceID

END

GO
GRANT SELECT ON  [dbo].[SMInvoiceSession] TO [public]
GRANT INSERT ON  [dbo].[SMInvoiceSession] TO [public]
GRANT DELETE ON  [dbo].[SMInvoiceSession] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoiceSession] TO [public]
GO
