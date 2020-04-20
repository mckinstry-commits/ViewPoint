
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

GRANT SELECT ON  [dbo].[SMInvoiceSession] TO [public]
GRANT INSERT ON  [dbo].[SMInvoiceSession] TO [public]
GRANT DELETE ON  [dbo].[SMInvoiceSession] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoiceSession] TO [public]
GO
