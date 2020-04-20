USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[RLBARImportRecord](
	[RLBARImportRecordID] [int] IDENTITY(1,1) NOT NULL,
	[RLBARImportDetailID] [int] NOT NULL,
	[Co] [tinyint] NULL,
	[Mth] [smalldatetime] NULL,
	[BatchId] [int] NULL,
	[BatchSeq] [int] NULL,
	[CMDeposit] [varchar](10) NULL,
	[CheckNo] [char](10) NULL,
	[CheckDate] [smalldatetime] NULL,
	[TransDate] [smalldatetime] NULL,
	[CreditAmt] [numeric](12, 2) NULL,
	[HeaderKeyID] [bigint] NULL,
	[DocName] [varchar](512) NULL,
	[AttachmentID] [int] NULL,
	[UniqueAttchID] [uniqueidentifier] NULL,
	[OrigFileName] [varchar](512) NULL,
	[FileCopied] [bit] NULL,
	[RLBProcessNotesID] [int] NULL,
    [Created] [datetime] NULL,
	[Modified] [datetime] NULL,

 CONSTRAINT [PK_RLBARImportRecord] PRIMARY KEY CLUSTERED 
(
	[RLBARImportRecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_Co]  DEFAULT (NULL) FOR [Co]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_Mth]  DEFAULT (NULL) FOR [Mth]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_BatchId]  DEFAULT (NULL) FOR [BatchId]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_BatchSeq]  DEFAULT (NULL) FOR [BatchSeq]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_CMDeposit]  DEFAULT (NULL) FOR [CMDeposit]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_CheckNo]  DEFAULT (NULL) FOR [CheckNo]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  DEFAULT (NULL) FOR [CheckDate]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  DEFAULT (NULL) FOR [TransDate]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_CreditAmt]  DEFAULT (NULL) FOR [CreditAmt]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_HeaderKeyID]  DEFAULT (NULL) FOR [HeaderKeyID]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_DocName]  DEFAULT (NULL) FOR [DocName]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_AttachmentID]  DEFAULT (NULL) FOR [AttachmentID]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_UniqueAttchID]  DEFAULT (NULL) FOR [UniqueAttchID]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_OrigFileName]  DEFAULT (NULL) FOR [OrigFileName]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_FileCopied]  DEFAULT (NULL) FOR [FileCopied]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_RLBProcessNotesID]  DEFAULT (NULL) FOR [RLBProcessNotesID]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_Created]  DEFAULT (getdate()) FOR [Created]
GO

ALTER TABLE [dbo].[RLBARImportRecord] ADD  CONSTRAINT [DF_RLBARImportRecord_Modified]  DEFAULT (getdate()) FOR [Modified]
GO


ALTER TABLE [dbo].[RLBARImportRecord]  WITH CHECK ADD CONSTRAINT [FK_RLBARImportRecord_RLBARImportDetailID] FOREIGN KEY([RLBARImportDetailID])
REFERENCES [dbo].[RLBARImportDetail] ([RLBARImportDetailID])
GO
ALTER TABLE [dbo].[RLBARImportRecord] CHECK CONSTRAINT [FK_RLBARImportRecord_RLBARImportDetailID]
GO

ALTER TABLE [dbo].[RLBARImportRecord]  WITH CHECK ADD CONSTRAINT [FK_RLBARImportRecord_RLBProcessNotesID] FOREIGN KEY([RLBProcessNotesID])
REFERENCES [dbo].[RLBProcessNotes] ([RLBProcessNotesID])
GO
ALTER TABLE [dbo].[RLBARImportRecord] CHECK CONSTRAINT [FK_RLBARImportRecord_RLBProcessNotesID]
GO

