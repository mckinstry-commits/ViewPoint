CREATE TABLE [dbo].[vSMInvoiceSession]
(
[SMInvoiceID] [bigint] NOT NULL,
[SMSessionID] [int] NOT NULL,
[SessionInvoice] [int] NOT NULL,
[VoidFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSMInvoiceSession_VoidFlag] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMInvoiceSession] ADD CONSTRAINT [PK_vSMInvoiceSession] PRIMARY KEY CLUSTERED  ([SMInvoiceID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMInvoiceSession] ADD CONSTRAINT [IX_vSMInvoiceSession_SMSessionID_SessionInvoice] UNIQUE NONCLUSTERED  ([SMSessionID], [SessionInvoice]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vSMInvoiceSession] WITH NOCHECK ADD CONSTRAINT [FK_vSMInvoiceSession_vSMSession] FOREIGN KEY ([SMSessionID]) REFERENCES [dbo].[vSMSession] ([SMSessionID]) ON DELETE CASCADE
GO
