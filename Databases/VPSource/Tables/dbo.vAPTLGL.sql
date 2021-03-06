CREATE TABLE [dbo].[vAPTLGL]
(
[APTLGLID] [bigint] NOT NULL IDENTITY(1, 1),
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APLine] [smallint] NOT NULL,
[CurrentAPInvoiceCostGLEntryID] [bigint] NULL,
[CurrentPOReceiptGLEntryID] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAPTLGL] ADD CONSTRAINT [PK_vAPTLGL] PRIMARY KEY CLUSTERED  ([APTLGLID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAPTLGL] ADD CONSTRAINT [IX_vAPTLGL] UNIQUE NONCLUSTERED  ([APCo], [Mth], [APTrans], [APLine]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vAPTLGL] WITH NOCHECK ADD CONSTRAINT [FK_vAPTLGL_vAPTLGLEntry] FOREIGN KEY ([CurrentAPInvoiceCostGLEntryID]) REFERENCES [dbo].[vAPTLGLEntry] ([GLEntryID])
GO
ALTER TABLE [dbo].[vAPTLGL] WITH NOCHECK ADD CONSTRAINT [FK_vAPTLGL_vPORDGLEntry] FOREIGN KEY ([CurrentPOReceiptGLEntryID]) REFERENCES [dbo].[vPORDGLEntry] ([GLEntryID])
GO
