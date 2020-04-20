USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[RLBAPImportRecord](
	[RLBAPImportRecordID] [int] IDENTITY(1,1) NOT NULL,
	[RLBAPImportDetailID] [int] NOT NULL,
	[Co] [tinyint] NULL,
	[Mth] [smalldatetime] NULL,
	[UISeq] [smallint] NULL,
	[Vendor] [int] NULL,
	[APRef]  [varchar](15) NULL,
	[InvDate] [smalldatetime] NULL,
	[InvTotal] [numeric](12, 2) NULL,
	[HeaderKeyID] [bigint] NULL,
	[FooterKeyID] [bigint] NULL,
	[DocName] [varchar](512) NULL,
	[AttachmentID] [int] NULL,
	[UniqueAttchID] [uniqueidentifier] NULL,
	[OrigFileName] [varchar](512) NULL,
	[FileCopied] [bit] NULL,
	[RLBProcessNotesID] [int] NULL,
    [Created] [datetime] NULL,
	[Modified] [datetime] NULL,

 CONSTRAINT [PK_RLBAPImportRecord] PRIMARY KEY CLUSTERED 
(
	[RLBAPImportRecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_Co]  DEFAULT (NULL) FOR [Co]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_Mth]  DEFAULT (NULL) FOR [Mth]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_UISeq]  DEFAULT (NULL) FOR [UISeq]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_Vendor]  DEFAULT (NULL) FOR [Vendor]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_APRef]  DEFAULT (NULL) FOR [APRef]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_InvDate]  DEFAULT (NULL) FOR [InvDate]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_InvTotal]  DEFAULT (NULL) FOR [InvTotal]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_HeaderKeyID]  DEFAULT (NULL) FOR [HeaderKeyID]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_FooterKeyID]  DEFAULT (NULL) FOR [FooterKeyID]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_DocName]  DEFAULT (NULL) FOR [DocName]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_AttachmentID]  DEFAULT (NULL) FOR [AttachmentID]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_UniqueAttchID]  DEFAULT (NULL) FOR [UniqueAttchID]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_OrigFileName]  DEFAULT (NULL) FOR [OrigFileName]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_FileCopied]  DEFAULT (NULL) FOR [FileCopied]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_RLBProcessNotesID]  DEFAULT (NULL) FOR [RLBProcessNotesID]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_Created]  DEFAULT (getdate()) FOR [Created]
GO

ALTER TABLE [dbo].[RLBAPImportRecord] ADD  CONSTRAINT [DF_RLBAPImportRecord_Modified]  DEFAULT (getdate()) FOR [Modified]
GO


ALTER TABLE [dbo].[RLBAPImportRecord]  WITH CHECK ADD CONSTRAINT [FK_RLBAPImportRecord_RLBAPImportDetailID] FOREIGN KEY([RLBAPImportDetailID])
REFERENCES [dbo].[RLBAPImportDetail] ([RLBAPImportDetailID])
GO
ALTER TABLE [dbo].[RLBAPImportRecord] CHECK CONSTRAINT [FK_RLBAPImportRecord_RLBAPImportDetailID]
GO

ALTER TABLE [dbo].[RLBAPImportRecord]  WITH CHECK ADD CONSTRAINT [FK_RLBAPImportRecord_RLBProcessNotesID] FOREIGN KEY([RLBProcessNotesID])
REFERENCES [dbo].[RLBProcessNotes] ([RLBProcessNotesID])
GO
ALTER TABLE [dbo].[RLBAPImportRecord] CHECK CONSTRAINT [FK_RLBAPImportRecord_RLBProcessNotesID]
GO

