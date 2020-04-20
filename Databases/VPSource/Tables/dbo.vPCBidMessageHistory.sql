CREATE TABLE [dbo].[vPCBidMessageHistory]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[BidPackage] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[ContactSeq] [tinyint] NOT NULL,
[DateSent] [dbo].[bDate] NOT NULL,
[DocSubject] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[DocBody] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[AttachIDList] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[FromAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Template] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidMessageHistory] ADD CONSTRAINT [PK_vPCBidMessageHistory] PRIMARY KEY CLUSTERED  ([JCCo], [PotentialProject], [BidPackage], [VendorGroup], [Vendor], [ContactSeq], [DateSent]) ON [PRIMARY]
GO
