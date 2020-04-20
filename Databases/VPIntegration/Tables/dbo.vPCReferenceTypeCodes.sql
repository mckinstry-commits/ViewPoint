CREATE TABLE [dbo].[vPCReferenceTypeCodes]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[ReferenceTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ActiveLookup] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCReferenceTypeCodes] ADD CONSTRAINT [PK_vPCReferenceTypeCodes] PRIMARY KEY CLUSTERED  ([VendorGroup], [ReferenceTypeCode]) ON [PRIMARY]
GO
