CREATE TABLE [dbo].[vVPDisplayTabs]
(
[Seq] [int] NOT NULL,
[DisplayID] [int] NOT NULL,
[TabNumber] [smallint] NOT NULL,
[TabName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[NavigationID] [int] NULL,
[KeyID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPDisplayTabs] ADD CONSTRAINT [PK_vVPDisplayTabs] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPDisplayTabs] WITH NOCHECK ADD CONSTRAINT [FK_vVPDisplayTabs_vVPDisplayProfile] FOREIGN KEY ([DisplayID]) REFERENCES [dbo].[vVPDisplayProfile] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vVPDisplayTabs] WITH NOCHECK ADD CONSTRAINT [FK_vVPDisplayTabs_vVPDisplayTabNavigation] FOREIGN KEY ([NavigationID]) REFERENCES [dbo].[vVPDisplayTabNavigation] ([KeyID])
GO
ALTER TABLE [dbo].[vVPDisplayTabs] NOCHECK CONSTRAINT [FK_vVPDisplayTabs_vVPDisplayProfile]
GO
ALTER TABLE [dbo].[vVPDisplayTabs] NOCHECK CONSTRAINT [FK_vVPDisplayTabs_vVPDisplayTabNavigation]
GO
