CREATE TABLE [dbo].[vPCPotentialProjectCertificate]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[CertificateType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[GoalPct] [dbo].[bPct] NULL,
[ActualPct] [dbo].[bPct] NULL,
[GoalAmount] [dbo].[bDollar] NULL,
[ActualAmount] [dbo].[bDollar] NULL,
[GoalMetYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPCPotentialProjectCertificate_GoalMetYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCPotentialProjectCertificate] ADD CONSTRAINT [PK_vPCPotentialProjectCertificates] PRIMARY KEY CLUSTERED  ([JCCo], [PotentialProject], [VendorGroup], [CertificateType]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCPotentialProjectCertificate] WITH NOCHECK ADD CONSTRAINT [FK_vPCPotentialProjectCertificate_vPCCertificateTypes] FOREIGN KEY ([VendorGroup], [CertificateType]) REFERENCES [dbo].[vPCCertificateTypes] ([VendorGroup], [CertificateType])
GO
