CREATE TABLE [dbo].[bDDUF_Archive]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[BatchYN] [dbo].[bYN] NOT NULL,
[DestTable] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BatchSource] [dbo].[bSource] NULL,
[UploadRoutine] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BidtekRoutine] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[ImportRoutine] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ArchiveDate] [datetime] NULL CONSTRAINT [DF__bDDUF_Arc__Archi__0AD7640F] DEFAULT (getdate()),
[ArchiveID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
