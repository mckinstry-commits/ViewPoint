CREATE TABLE [dbo].[vDDGridGroupingForm]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Tab] [tinyint] NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[vDDGridGroupingForm] ADD 
CONSTRAINT [PK_vDDGridGroupingForm] PRIMARY KEY CLUSTERED  ([KeyID]) WITH (FILLFACTOR=100) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_vDDGridGroupingForm_Form] ON [dbo].[vDDGridGroupingForm] ([Form]) WITH (FILLFACTOR=80) ON [PRIMARY]

GO
