CREATE TABLE [dbo].[vPCCertificateTypes]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[CertificateType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Active] [dbo].[bYN] NOT NULL,
[Notes] [varbinary] (max) NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL,
[Category] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCCertificateTypes] ADD CONSTRAINT [PK_vPCCertificateTypes] PRIMARY KEY CLUSTERED  ([VendorGroup], [CertificateType]) ON [PRIMARY]
GO
