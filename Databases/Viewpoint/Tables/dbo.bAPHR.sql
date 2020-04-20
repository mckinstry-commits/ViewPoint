CREATE TABLE [dbo].[bAPHR]
(
[APCo] [dbo].[bCompany] NOT NULL,
[UserId] [dbo].[bVPUserName] NOT NULL,
[Mth] [smalldatetime] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APLine] [smallint] NOT NULL,
[APSeq] [tinyint] NOT NULL,
[PayType] [tinyint] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[ApplyNewTaxRateYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPHR_ApplyNewTaxRateYN] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bAPHR] ADD CONSTRAINT [PK_bAPHR] PRIMARY KEY CLUSTERED  ([APCo], [UserId], [Mth], [APTrans], [APLine], [APSeq]) ON [PRIMARY]
GO
