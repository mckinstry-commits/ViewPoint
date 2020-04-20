CREATE TABLE [dbo].[vSMStandardItemDefault]
(
[SMStandardItemDefaultID] [bigint] NOT NULL IDENTITY(1, 1),
[Type] [tinyint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMStandardItemDefault] ADD CONSTRAINT [PK_vSMStandardItemDefault] PRIMARY KEY CLUSTERED  ([SMStandardItemDefaultID]) ON [PRIMARY]
GO
