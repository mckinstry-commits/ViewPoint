CREATE TABLE [dbo].[vVPDisplayProfile]
(
[KeyID] [int] NOT NULL,
[Name] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPDisplayProfile] ADD CONSTRAINT [PK_vVPDisplayProfile] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
