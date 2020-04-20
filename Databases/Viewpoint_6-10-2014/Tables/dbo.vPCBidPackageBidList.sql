CREATE TABLE [dbo].[vPCBidPackageBidList]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[BidPackage] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[ContactSeq] [tinyint] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttendingWalkthrough] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPCBidPackageBidList_AttendingWalkthrough] DEFAULT ('N'),
[MessageStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[LastSent] [dbo].[bDate] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidPackageBidList] ADD CONSTRAINT [PK_vPCBidPackageBiddersList] PRIMARY KEY CLUSTERED  ([JCCo], [PotentialProject], [BidPackage], [VendorGroup], [Vendor], [ContactSeq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidPackageBidList] WITH NOCHECK ADD CONSTRAINT [FK_vPCBidPackageBiddersList_vPCBidPackage] FOREIGN KEY ([JCCo], [PotentialProject], [BidPackage]) REFERENCES [dbo].[vPCBidPackage] ([JCCo], [PotentialProject], [BidPackage])
GO
ALTER TABLE [dbo].[vPCBidPackageBidList] WITH NOCHECK ADD CONSTRAINT [FK_vPCBidPackageBidList_vPCContacts] FOREIGN KEY ([VendorGroup], [Vendor], [ContactSeq]) REFERENCES [dbo].[vPCContacts] ([VendorGroup], [Vendor], [Seq])
GO
ALTER TABLE [dbo].[vPCBidPackageBidList] NOCHECK CONSTRAINT [FK_vPCBidPackageBiddersList_vPCBidPackage]
GO
ALTER TABLE [dbo].[vPCBidPackageBidList] NOCHECK CONSTRAINT [FK_vPCBidPackageBidList_vPCContacts]
GO
