CREATE TABLE [dbo].[bVSBH]
(
[BatchId] [int] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[CreatedDate] [dbo].[bDate] NOT NULL,
[CreatedBy] [dbo].[bVPUserName] NOT NULL,
[InUseBy] [dbo].[bVPUserName] NULL,
[Restricted] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bVSBH_Restricted] DEFAULT ('N'),
[AttachmentTypeID] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biVSBH] ON [dbo].[bVSBH] ([BatchId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biVSBHDesc] ON [dbo].[bVSBH] ([Description]) ON [PRIMARY]
GO
