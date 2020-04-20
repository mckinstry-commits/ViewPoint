CREATE TABLE [dbo].[budxrefPRPaySeq]
(
[CGCBatchId] [int] NOT NULL,
[PRCo] [dbo].[bCompany] NOT NULL,
[PREndDate] [int] NOT NULL,
[PRGroup] [int] NULL,
[PaySeq] [int] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biudxrefPRPaySeq] ON [dbo].[budxrefPRPaySeq] ([PRCo], [PREndDate], [CGCBatchId]) ON [PRIMARY]

GO
