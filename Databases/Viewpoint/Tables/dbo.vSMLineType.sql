CREATE TABLE [dbo].[vSMLineType]
(
[LineType] [tinyint] NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMLineType] ADD CONSTRAINT [PK_vSMLineType] PRIMARY KEY CLUSTERED  ([LineType]) ON [PRIMARY]
GO
