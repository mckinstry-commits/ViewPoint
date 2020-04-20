CREATE TABLE [dbo].[boldxrefUnion]
(
[Company] [smallint] NOT NULL,
[CMSUnion] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CMSClass] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CMSType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Craft] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Class] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
