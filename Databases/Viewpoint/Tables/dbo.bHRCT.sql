CREATE TABLE [dbo].[bHRCT]
(
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRCT] ON [dbo].[bHRCT] ([Type]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
