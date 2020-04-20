CREATE TABLE [dbo].[vSMAgreementAmrt]
(
[SMAgreementAmrtID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[SMTrans] [dbo].[bTrans] NOT NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[Service] [int] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[AgreementRevDefGLAcct] [dbo].[bGLAcct] NOT NULL,
[AgreementRevGLAcct] [dbo].[bGLAcct] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] ADD CONSTRAINT [PK_vSMAgreementRevenueRecognized] PRIMARY KEY CLUSTERED  ([SMAgreementAmrtID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] ADD CONSTRAINT [IX_vSMAgreementAmrt] UNIQUE NONCLUSTERED  ([SMCo], [Mth], [SMTrans]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementAmrt_bGLAC_AgreementRevDefGLAcct] FOREIGN KEY ([GLCo], [AgreementRevDefGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementAmrt_bGLAC_AgreementRevGLAcct] FOREIGN KEY ([GLCo], [AgreementRevGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementAmrt_vSMAgreement] FOREIGN KEY ([SMCo], [Agreement], [Revision]) REFERENCES [dbo].[vSMAgreement] ([SMCo], [Agreement], [Revision])
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementAmrt_vSMAgreementService] FOREIGN KEY ([SMCo], [Agreement], [Revision], [Service]) REFERENCES [dbo].[vSMAgreementService] ([SMCo], [Agreement], [Revision], [Service])
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] NOCHECK CONSTRAINT [FK_vSMAgreementAmrt_bGLAC_AgreementRevDefGLAcct]
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] NOCHECK CONSTRAINT [FK_vSMAgreementAmrt_bGLAC_AgreementRevGLAcct]
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] NOCHECK CONSTRAINT [FK_vSMAgreementAmrt_vSMAgreement]
GO
ALTER TABLE [dbo].[vSMAgreementAmrt] NOCHECK CONSTRAINT [FK_vSMAgreementAmrt_vSMAgreementService]
GO
