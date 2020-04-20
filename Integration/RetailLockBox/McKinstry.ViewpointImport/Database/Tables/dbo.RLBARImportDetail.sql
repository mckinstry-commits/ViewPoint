USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[RLBARImportDetail](
	[RLBARImportDetailID] [int] IDENTITY(1,1) NOT NULL,
	[RLBImportBatchID] [int] NOT NULL,
	[FileName] [varchar](200) NOT NULL,
	[LastWriteTime] [datetime] NOT NULL,
	[Length] [bigint] NOT NULL,
	[RLBImportDetailStatusCode] [varchar](3) NOT NULL,
	[RLBProcessNotesID] [int] NULL,
    [Created] [datetime] NULL,
	[Modified] [datetime] NULL,
	[Company] [tinyint] NULL,
	[InvoiceNumber] [varchar](10) NULL,
	[CustGroup] [tinyint] NULL,
	[Customer] [int] NULL,
	[CustomerName] [varchar](60) NULL,
	[TransactionDate] [smalldatetime] NULL,
	[InvoiceDescription] [varchar](30) NULL,
	[DetailLineCount] [int] NULL,
	[AmountDue] [numeric](12, 2) NULL,
	[OriginalAmount] [numeric](12, 2) NULL,
	[Tax] [numeric](12, 2) NULL,
	[CollectedCheckDate] [smalldatetime] NULL,
	[CollectedCheckNumber] [char](10) NULL,
	[CollectedCheckAmount] [numeric](12, 2) NULL,
	[CollectedImage] [varchar](255) NULL,
	[Notes] [varchar](512) NULL,

 CONSTRAINT [PK_RLBARImportDetail] PRIMARY KEY CLUSTERED 
(
	[RLBARImportDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_RLBProcessNotesID]  DEFAULT (NULL) FOR [RLBProcessNotesID]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_Created]  DEFAULT (getdate()) FOR [Created]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_Modified]  DEFAULT (getdate()) FOR [Modified]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_Company]  DEFAULT (NULL) FOR [Company]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_InvoiceNumber]  DEFAULT (NULL) FOR [InvoiceNumber]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_CustGroup]  DEFAULT (NULL) FOR [CustGroup]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_Customer]  DEFAULT (NULL) FOR [Customer]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_CustomerName]  DEFAULT (NULL) FOR [CustomerName]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  DEFAULT (NULL) FOR [TransactionDate]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_InvoiceDescription]  DEFAULT (NULL) FOR [InvoiceDescription]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_DetailLineCount]  DEFAULT (NULL) FOR [DetailLineCount]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_AmountDue]  DEFAULT (NULL) FOR [AmountDue]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_OriginalAmount]  DEFAULT (NULL) FOR [OriginalAmount]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_Tax]  DEFAULT (NULL) FOR [Tax]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  DEFAULT (NULL) FOR [CollectedCheckDate]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_CollectedCheckNumber]  DEFAULT (NULL) FOR [CollectedCheckNumber]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_CollectedCheckAmount]  DEFAULT (NULL) FOR [CollectedCheckAmount]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_CollectedImage]  DEFAULT (NULL) FOR [CollectedImage]
GO

ALTER TABLE [dbo].[RLBARImportDetail] ADD  CONSTRAINT [DF_RLBARImportDetail_Notes]  DEFAULT (NULL) FOR [Notes]
GO

ALTER TABLE [dbo].[RLBARImportDetail]  WITH CHECK ADD CONSTRAINT [FK_RLBARImportDetail_RLBImportBatch] FOREIGN KEY([RLBImportBatchID])
REFERENCES [dbo].[RLBImportBatch] ([RLBImportBatchID])
GO
ALTER TABLE [dbo].[RLBARImportDetail] CHECK CONSTRAINT [FK_RLBARImportDetail_RLBImportBatch]
GO

ALTER TABLE [dbo].[RLBARImportDetail]  WITH CHECK ADD CONSTRAINT [FK_RLBARImportDetail_RLBImportDetailStatusCode] FOREIGN KEY([RLBImportDetailStatusCode])
REFERENCES [dbo].[RLBImportDetailStatus] ([StatusCode])
GO
ALTER TABLE [dbo].[RLBARImportDetail] CHECK CONSTRAINT [FK_RLBARImportDetail_RLBImportDetailStatusCode]
GO

ALTER TABLE [dbo].[RLBARImportDetail]  WITH CHECK ADD CONSTRAINT [FK_RLBARImportDetail_RLBProcessNotesID] FOREIGN KEY([RLBProcessNotesID])
REFERENCES [dbo].[RLBProcessNotes] ([RLBProcessNotesID])
GO
ALTER TABLE [dbo].[RLBARImportDetail] CHECK CONSTRAINT [FK_RLBARImportDetail_RLBProcessNotesID]
GO

