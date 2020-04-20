CREATE TABLE [dbo].[vSMAgreementAmrtBatch]
(
[SMAgreementAmrtBatchID] [bigint] NOT NULL IDENTITY(1, 1),
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Seq] [int] NOT NULL,
[SMTrans] [dbo].[bTrans] NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[Service] [int] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[AgreementRevDefGLAcct] [dbo].[bGLAcct] NOT NULL,
[AgreementRevGLAcct] [dbo].[bGLAcct] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] ADD CONSTRAINT [PK_vSMAgreementAmrtBatch] PRIMARY KEY CLUSTERED  ([SMAgreementAmrtBatchID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] ADD CONSTRAINT [IX_vSMAgreementAmrtBatch] UNIQUE NONCLUSTERED  ([Co], [Mth], [BatchId], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementAmrtBatch_vSMAgreement] FOREIGN KEY ([Co], [Agreement], [Revision]) REFERENCES [dbo].[vSMAgreement] ([SMCo], [Agreement], [Revision])
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementAmrtBatch_vSMAgreementService] FOREIGN KEY ([Co], [Agreement], [Revision], [Service]) REFERENCES [dbo].[vSMAgreementService] ([SMCo], [Agreement], [Revision], [Service])
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementAmrtBatch_bGLAC_AgreementRevDefGLAcct] FOREIGN KEY ([GLCo], [AgreementRevDefGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementAmrtBatch_bGLAC_AgreementRevGLAcct] FOREIGN KEY ([GLCo], [AgreementRevGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] NOCHECK CONSTRAINT [FK_vSMAgreementAmrtBatch_vSMAgreement]
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] NOCHECK CONSTRAINT [FK_vSMAgreementAmrtBatch_vSMAgreementService]
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] NOCHECK CONSTRAINT [FK_vSMAgreementAmrtBatch_bGLAC_AgreementRevDefGLAcct]
GO
ALTER TABLE [dbo].[vSMAgreementAmrtBatch] NOCHECK CONSTRAINT [FK_vSMAgreementAmrtBatch_bGLAC_AgreementRevGLAcct]
GO
