CREATE TABLE [dbo].[vPMDocumentMapping]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[View] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[DocumentCategory] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DocumentTypeColumn] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[FirmOrVendorColumn] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[ContactColumn] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[DescriptionColumn] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[OurFirmColumn] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[OurFirmContactColumn] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMDocumentMapping] ADD CONSTRAINT [PK_vPMDocumentMapping] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
