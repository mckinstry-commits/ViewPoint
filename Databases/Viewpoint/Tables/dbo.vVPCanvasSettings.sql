CREATE TABLE [dbo].[vVPCanvasSettings]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[NumberOfRows] [int] NULL,
[NumberOfColumns] [int] NULL,
[RefreshInterval] [int] NULL,
[TableLayout] [varbinary] (max) NULL,
[GridLayout] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[TabNumber] [int] NULL,
[TabName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[FilterConfigurationSettings] [varbinary] (max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_vVPCanvasSettings_VPUserName] ON [dbo].[vVPCanvasSettings] ([VPUserName]) WITH (FILLFACTOR=80) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 8/25/2010
-- Mods:		HH 5/17/2012 TK-14882 added VPCanvasNavigationSettings
-- Description:	Clean up grid configuration settings when a user is removed
-- =============================================
CREATE TRIGGER [dbo].[vtVPCanvasSettingsd]
   ON  [dbo].[vVPCanvasSettings] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE VPCanvasTreeItems
	FROM VPCanvasTreeItems
	INNER JOIN deleted AS d ON VPCanvasTreeItems.CanvasId = d.KeyID;
	
	DELETE VPCanvasGridParameters
	FROM VPCanvasGridParameters
	INNER JOIN VPCanvasGridSettings ON VPCanvasGridParameters.GridConfigurationId = VPCanvasGridSettings.KeyID
	INNER JOIN VPPartSettings ON VPCanvasGridSettings.PartId = VPPartSettings.KeyID
	INNER JOIN deleted AS d ON VPPartSettings.CanvasId = d.KeyID;
	
	DELETE VPCanvasGridGroupedColumns
	FROM VPCanvasGridGroupedColumns
	INNER JOIN VPCanvasGridSettings ON VPCanvasGridGroupedColumns.GridConfigurationId = VPCanvasGridSettings.KeyID
	INNER JOIN VPPartSettings ON VPCanvasGridSettings.PartId = VPPartSettings.KeyID
	INNER JOIN deleted AS d ON VPPartSettings.CanvasId = d.KeyID; 
 
	DELETE VPCanvasGridColumns
	FROM VPCanvasGridColumns
	INNER JOIN VPCanvasGridSettings ON VPCanvasGridColumns.GridConfigurationId = VPCanvasGridSettings.KeyID
	INNER JOIN VPPartSettings ON VPCanvasGridSettings.PartId = VPPartSettings.KeyID
	INNER JOIN deleted AS d ON VPPartSettings.CanvasId = d.KeyID; 

	DELETE VPCanvasNavigationSettings
	FROM VPCanvasNavigationSettings
	INNER JOIN VPCanvasGridSettings ON VPCanvasNavigationSettings.GridConfigurationID = VPCanvasGridSettings.KeyID
	INNER JOIN VPPartSettings ON VPCanvasGridSettings.PartId = VPPartSettings.KeyID
	INNER JOIN deleted AS d ON VPPartSettings.CanvasId = d.KeyID

	DELETE VPCanvasGridSettings
	FROM VPCanvasGridSettings
	INNER JOIN VPPartSettings ON VPCanvasGridSettings.PartId = VPPartSettings.KeyID
	INNER JOIN deleted AS d ON VPPartSettings.CanvasId = d.KeyID;  

	DELETE VPCanvasGridPartSettings
	FROM VPCanvasGridPartSettings
	INNER JOIN VPPartSettings ON VPCanvasGridPartSettings.PartId = VPPartSettings.KeyID
	INNER JOIN deleted AS d ON VPPartSettings.CanvasId = d.KeyID;  

	DELETE VPPartSettings 
	FROM VPPartSettings 	
	INNER JOIN deleted AS d ON VPPartSettings.CanvasId = d.KeyID;  

END

GO
ALTER TABLE [dbo].[vVPCanvasSettings] ADD CONSTRAINT [PK_vVPCanvasSettings] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
