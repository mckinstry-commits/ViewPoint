USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RLBImportBatch](
	[RLBImportBatchID] [int] IDENTITY(1,1) NOT NULL,
	[RLBProcessNotesID] [int] NULL,
	[FileName] [nvarchar](200) NOT NULL,
	[LastWriteTime] [datetime] NOT NULL,
	[Length] [bigint] NOT NULL,
	[Type] [nvarchar](2) NOT NULL,
	[RLBImportBatchStatusCode] [varchar](3) NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[CompleteTime] [datetime] NULL,
	[ArchiveFolderName] [nvarchar](512) NOT NULL,
	[Created] [datetime] NULL,
	[Modified] [datetime] NULL,
 CONSTRAINT [PK_RLBImportBatch] PRIMARY KEY CLUSTERED 
(
	[RLBImportBatchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[RLBImportBatch] ADD  CONSTRAINT [DF_RLBImportBatch_Created]  DEFAULT (getdate()) FOR [Created]
GO

ALTER TABLE [dbo].[RLBImportBatch]  WITH CHECK ADD  CONSTRAINT [FK_RLBImportBatch_RLBImportBatchStatusCode] FOREIGN KEY([RLBImportBatchStatusCode])
REFERENCES [dbo].[RLBImportBatchStatus] ([StatusCode])
GO

ALTER TABLE [dbo].[RLBImportBatch] CHECK CONSTRAINT [FK_RLBImportBatch_RLBImportBatchStatusCode]
GO


