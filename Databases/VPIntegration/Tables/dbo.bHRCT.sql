CREATE TABLE [dbo].[bHRCT]
(
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHRCT] ON [dbo].[bHRCT] ([Type]) ON [PRIMARY]
GO
