CREATE TABLE [dbo].[budBandOClass]
(
[BOClassCode] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudBandOClass] ON [dbo].[budBandOClass] ([BOClassCode]) ON [PRIMARY]
GO
