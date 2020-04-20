CREATE TABLE [dbo].[vVPCanvasNavigationSettings]
(
[PartId] [int] NOT NULL,
[GridConfigurationID] [int] NOT NULL,
[Step] [int] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ParentGridConfigurationID] [int] NULL,
[UserDefaultDrillThrough] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasNavigationSettings] ADD CONSTRAINT [PK_vVPCanvasNavigationSettings] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPCanvasNavigationSettings] WITH NOCHECK ADD CONSTRAINT [FK_vVPCanvasNavigationSettings_vVPCanvasGridSettings] FOREIGN KEY ([GridConfigurationID]) REFERENCES [dbo].[vVPCanvasGridSettings] ([KeyID])
GO
