CREATE TABLE [dbo].[vPCBidCoverage]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[BidPackage] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ScopePhaseSeq] [bigint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[ContactSeq] [tinyint] NOT NULL,
[BidResponse] [char] (1) COLLATE Latin1_General_BIN NULL,
[BidReceived] [dbo].[bYN] NULL,
[BidAmount] [dbo].[bDollar] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidCoverage] ADD CONSTRAINT [PK_vPCBidCoverage_1] PRIMARY KEY CLUSTERED  ([JCCo], [PotentialProject], [BidPackage], [ScopePhaseSeq], [VendorGroup], [Vendor], [ContactSeq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCBidCoverage] WITH NOCHECK ADD CONSTRAINT [FK_vPCBidCoverage_vPCBidPackageScopes] FOREIGN KEY ([JCCo], [PotentialProject], [BidPackage], [ScopePhaseSeq]) REFERENCES [dbo].[vPCBidPackageScopes] ([JCCo], [PotentialProject], [BidPackage], [Seq]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPCBidCoverage] WITH NOCHECK ADD CONSTRAINT [FK_vPCBidCoverage_vPCBidPackageBidList] FOREIGN KEY ([JCCo], [PotentialProject], [BidPackage], [VendorGroup], [Vendor], [ContactSeq]) REFERENCES [dbo].[vPCBidPackageBidList] ([JCCo], [PotentialProject], [BidPackage], [VendorGroup], [Vendor], [ContactSeq]) ON DELETE CASCADE
GO
