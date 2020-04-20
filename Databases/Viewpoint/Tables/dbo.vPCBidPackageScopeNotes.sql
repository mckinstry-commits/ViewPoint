CREATE TABLE [dbo].[vPCBidPackageScopeNotes]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[BidPackage] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[ScopeCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NULL,
[Type] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Detail] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateEntered] [dbo].[bDate] NULL,
[EnteredBy] [dbo].[bVPUserName] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidPackageScopeNotes] ADD CONSTRAINT [PK_vPCBidPackageScopeNotes] PRIMARY KEY CLUSTERED  ([JCCo], [PotentialProject], [BidPackage], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidPackageScopeNotes] WITH NOCHECK ADD CONSTRAINT [FK_vPCBidPackageScopeNotes_vPCBidPackage] FOREIGN KEY ([JCCo], [PotentialProject], [BidPackage]) REFERENCES [dbo].[vPCBidPackage] ([JCCo], [PotentialProject], [BidPackage])
GO
