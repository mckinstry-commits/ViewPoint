CREATE TABLE [dbo].[vVPDisplaySecurityGroups]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[DisplayID] [int] NOT NULL,
[SecurityGroup] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPDisplaySecurityGroups] ADD CONSTRAINT [PK_vVPDisplaySecurityGroups] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPDisplaySecurityGroups] WITH NOCHECK ADD CONSTRAINT [FK_vVPDisplaySecurityGroups_vVPDisplayProfile] FOREIGN KEY ([DisplayID]) REFERENCES [dbo].[vVPDisplayProfile] ([KeyID]) ON DELETE CASCADE
GO
