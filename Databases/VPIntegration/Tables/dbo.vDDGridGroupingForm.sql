CREATE TABLE [dbo].[vDDGridGroupingForm]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Tab] [tinyint] NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDGridGroupingForm] ADD CONSTRAINT [PK_vDDGridGroupingForm] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vDDGridGroupingForm_Form] ON [dbo].[vDDGridGroupingForm] ([Form]) ON [PRIMARY]
GO