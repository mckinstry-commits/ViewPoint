CREATE TABLE [dbo].[budMinutesType]
(
[Type] [varchar] (1000) COLLATE Latin1_General_BIN NOT NULL,
[TypeDescription] [dbo].[bDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudMinutesType] ON [dbo].[budMinutesType] ([Type]) ON [PRIMARY]
GO
