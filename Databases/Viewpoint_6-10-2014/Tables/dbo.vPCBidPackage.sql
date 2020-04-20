CREATE TABLE [dbo].[vPCBidPackage]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[BidPackage] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PackageDetails] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[SealedBid] [dbo].[bYN] NULL,
[BidDueDate] [dbo].[bDate] NULL,
[BidDueTime] [dbo].[bDate] NULL,
[WalkthroughDate] [dbo].[bDate] NULL,
[WalkthroughTime] [dbo].[bDate] NULL,
[WalkthroughNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PrimaryContact] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PrimaryContactPhone] [dbo].[bPhone] NULL,
[PrimaryContactEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SecondaryContact] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SecondaryContactPhone] [dbo].[bPhone] NULL,
[SecondaryContactEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidPackage] ADD CONSTRAINT [PK_vPCBidPackage] PRIMARY KEY CLUSTERED  ([JCCo], [PotentialProject], [BidPackage]) ON [PRIMARY]
GO
