CREATE TABLE [dbo].[vPCBidPackageScopes]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[BidPackage] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [bigint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ScopeCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AwardedVendorGroup] [dbo].[bGroup] NULL,
[AwardedVendor] [dbo].[bVendor] NULL,
[AwardedContactSeq] [tinyint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidPackageScopes] ADD CONSTRAINT [PK_vPCBidPackageScopes] PRIMARY KEY CLUSTERED  ([JCCo], [PotentialProject], [BidPackage], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidPackageScopes] WITH NOCHECK ADD CONSTRAINT [FK_vPCBidPackageScopes_vPCBidPackage] FOREIGN KEY ([JCCo], [PotentialProject], [BidPackage]) REFERENCES [dbo].[vPCBidPackage] ([JCCo], [PotentialProject], [BidPackage])
GO
ALTER TABLE [dbo].[vPCBidPackageScopes] WITH NOCHECK ADD CONSTRAINT [FK_vPCBidPackageScopes_vPCBidPackageBidList] FOREIGN KEY ([JCCo], [PotentialProject], [BidPackage], [AwardedVendorGroup], [AwardedVendor], [AwardedContactSeq]) REFERENCES [dbo].[vPCBidPackageBidList] ([JCCo], [PotentialProject], [BidPackage], [VendorGroup], [Vendor], [ContactSeq])
GO
ALTER TABLE [dbo].[vPCBidPackageScopes] WITH NOCHECK ADD CONSTRAINT [FK_vPCBidPackageScopes_bJCPM] FOREIGN KEY ([PhaseGroup], [Phase]) REFERENCES [dbo].[bJCPM] ([PhaseGroup], [Phase])
GO
ALTER TABLE [dbo].[vPCBidPackageScopes] WITH NOCHECK ADD CONSTRAINT [FK_vPCBidPackageScopes_vPCScopeCodes] FOREIGN KEY ([VendorGroup], [ScopeCode]) REFERENCES [dbo].[vPCScopeCodes] ([VendorGroup], [ScopeCode])
GO
