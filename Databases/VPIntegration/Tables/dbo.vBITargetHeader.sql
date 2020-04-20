CREATE TABLE [dbo].[vBITargetHeader]
(
[BICo] [dbo].[bCompany] NOT NULL,
[TargetName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[TargetType] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[GroupingLevel] [smallint] NULL,
[GroupingValue] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[GroupingAll] [dbo].[bYN] NULL,
[FilterField] [smallint] NULL,
[FilterValue] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[FilterAll] [dbo].[bYN] NULL,
[BegDate] [dbo].[bDate] NOT NULL,
[EndDate] [dbo].[bDate] NOT NULL,
[Period] [int] NOT NULL CONSTRAINT [DF_vBITargetHeader_Period] DEFAULT ((0)),
[PRGroup] [dbo].[bGroup] NULL,
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vBITargetHeader] ADD CONSTRAINT [PK_vBITargetHeader] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vBITargetHeader_BICo_TargetName] ON [dbo].[vBITargetHeader] ([BICo], [TargetName]) ON [PRIMARY]
GO
