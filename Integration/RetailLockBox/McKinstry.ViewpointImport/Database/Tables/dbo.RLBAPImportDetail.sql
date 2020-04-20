USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[RLBAPImportDetail](
	[RLBAPImportDetailID] [int] IDENTITY(1,1) NOT NULL,
	[RLBImportBatchID] [int] NOT NULL,
	[FileName] [varchar](200) NOT NULL,
	[LastWriteTime] [datetime] NOT NULL,
	[Length] [bigint] NOT NULL,
	[RLBImportDetailStatusCode] [varchar](3) NOT NULL,
	[RLBProcessNotesID] [int] NULL,
    [Created] [datetime] NULL,
	[Modified] [datetime] NULL,
	[UnmatchedNumber] [varchar](30) NULL,
	[RecordType] [varchar](30) NULL,
	[Company] [tinyint] NULL,
	[Number] [varchar](30) NULL,
	[VendorGroup] [tinyint] NULL,
	[Vendor] [int] NULL,
	[VendorName] [varchar](60) NULL,
	[TransactionDate] [datetime] NULL,
	[JCCo] [tinyint] NULL,
	[Job] [varchar](10) NULL,
	[JobDescription] [varchar](60) NULL,
	[Description] [varchar](30) NULL,
	[DetailLineCount] [int] NULL,
	[TotalOrigCost] [numeric](12, 2) NULL,
	[TotalOrigTax] [numeric](12, 2) NULL,
	[RemainingAmount] [numeric](12, 2) NULL,
	[RemainingTax] [numeric](12, 2) NULL,
	[CollectedInvoiceDate] [smalldatetime] NULL,
	[CollectedInvoiceNumber] [varchar](50) NULL,
	[CollectedTaxAmount] [numeric](12, 2) NULL,
	[CollectedShippingAmount] [numeric](12, 2) NULL,
	[CollectedInvoiceAmount] [numeric](12, 2) NULL,
	[CollectedImage] [varchar](255) NULL,

 CONSTRAINT [PK_RLBAPImportDetail] PRIMARY KEY CLUSTERED 
(
	[RLBAPImportDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_RLBProcessNotesID]  DEFAULT (NULL) FOR [RLBProcessNotesID]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_Created]  DEFAULT (getdate()) FOR [Created]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_Modified]  DEFAULT (getdate()) FOR [Modified]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_UnmatchedNumber]  DEFAULT (getdate()) FOR [UnmatchedNumber]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_RecordType]  DEFAULT (NULL) FOR [RecordType]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_Company]  DEFAULT (NULL) FOR [Company]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_Number]  DEFAULT (NULL) FOR [Number]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_VendorGroup]  DEFAULT (NULL) FOR [VendorGroup]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_Vendor]  DEFAULT (NULL) FOR [Vendor]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_VendorName]  DEFAULT (NULL) FOR [VendorName]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  DEFAULT (NULL) FOR [TransactionDate]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_JCCo]  DEFAULT (NULL) FOR [JCCo]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_Job]  DEFAULT (NULL) FOR [Job]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_JobDescription]  DEFAULT (NULL) FOR [JobDescription]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_Description]  DEFAULT (NULL) FOR [Description]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_DetailLineCount]  DEFAULT (NULL) FOR [DetailLineCount]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_TotalOrigCost]  DEFAULT (NULL) FOR [TotalOrigCost]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_TotalOrigTax]  DEFAULT (NULL) FOR [TotalOrigTax]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_RemainingAmount]  DEFAULT (NULL) FOR [RemainingAmount]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_RemainingTax]  DEFAULT (NULL) FOR [RemainingTax]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  DEFAULT (NULL) FOR [CollectedInvoiceDate]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_CollectedInvoiceNumber]  DEFAULT (NULL) FOR [CollectedInvoiceNumber]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_CollectedTaxAmount]  DEFAULT (NULL) FOR [CollectedTaxAmount]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_CollectedShippingAmount]  DEFAULT (NULL) FOR [CollectedShippingAmount]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_CollectedInvoiceAmount]  DEFAULT (NULL) FOR [CollectedInvoiceAmount]
GO

ALTER TABLE [dbo].[RLBAPImportDetail] ADD  CONSTRAINT [DF_RLBAPImportDetail_CollectedImage]  DEFAULT (NULL) FOR [CollectedImage]
GO

ALTER TABLE [dbo].[RLBAPImportDetail]  WITH CHECK ADD CONSTRAINT [FK_RLBAPImportDetail_RLBImportBatch] FOREIGN KEY([RLBImportBatchID])
REFERENCES [dbo].[RLBImportBatch] ([RLBImportBatchID])
GO
ALTER TABLE [dbo].[RLBAPImportDetail] CHECK CONSTRAINT [FK_RLBAPImportDetail_RLBImportBatch]
GO

ALTER TABLE [dbo].[RLBAPImportDetail]  WITH CHECK ADD CONSTRAINT [FK_RLBAPImportDetail_RLBImportDetailStatusCode] FOREIGN KEY([RLBImportDetailStatusCode])
REFERENCES [dbo].[RLBImportDetailStatus] ([StatusCode])
GO
ALTER TABLE [dbo].[RLBAPImportDetail] CHECK CONSTRAINT [FK_RLBAPImportDetail_RLBImportDetailStatusCode]
GO

ALTER TABLE [dbo].[RLBAPImportDetail]  WITH CHECK ADD CONSTRAINT [FK_RLBAPImportDetail_RLBProcessNotesID] FOREIGN KEY([RLBProcessNotesID])
REFERENCES [dbo].[RLBProcessNotes] ([RLBProcessNotesID])
GO
ALTER TABLE [dbo].[RLBAPImportDetail] CHECK CONSTRAINT [FK_RLBAPImportDetail_RLBProcessNotesID]
GO

