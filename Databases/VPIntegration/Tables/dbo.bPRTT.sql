CREATE TABLE [dbo].[bPRTT]
(
[UserId] [dbo].[bVPUserName] NOT NULL,
[SendSeq] [int] NOT NULL,
[Module] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[BatchMth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[PostDate] [dbo].[bDate] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTT] ON [dbo].[bPRTT] ([UserId], [SendSeq], [Module], [Co], [BatchMth], [BatchId]) ON [PRIMARY]
GO
