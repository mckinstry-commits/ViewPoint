CREATE TABLE [dbo].[vPCCertificates]
(
[Vendor] [bigint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[CertificateType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Certificate] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Agency] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ExpDate] [dbo].[bDate] NULL,
[StartDate] [dbo].[bDate] NULL,
[EndDate] [dbo].[bDate] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCCertificates] ADD CONSTRAINT [PK_vPCCertificates] PRIMARY KEY CLUSTERED  ([Vendor], [VendorGroup], [CertificateType]) ON [PRIMARY]
GO
