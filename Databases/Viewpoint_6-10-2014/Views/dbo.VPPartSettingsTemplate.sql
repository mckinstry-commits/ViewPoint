SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPPartSettingsTemplate AS 
	SELECT * 
	FROM vVPPartSettingsTemplate 
	
	UNION ALL
	
	SELECT * 
	FROM vVPPartSettingsTemplatec
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: 
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPPartSettingsTemplated] 
   ON  [dbo].[VPPartSettingsTemplate] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	DELETE vVPPartSettingsTemplate 
	FROM vVPPartSettingsTemplate
	INNER JOIN deleted i ON vVPPartSettingsTemplate.KeyID = i.KeyID AND vVPPartSettingsTemplate.TemplateName = i.TemplateName
ELSE
	DELETE vVPPartSettingsTemplatec 	
	FROM vVPPartSettingsTemplatec
	INNER JOIN deleted i ON vVPPartSettingsTemplatec.KeyID = i.KeyID AND vVPPartSettingsTemplatec.TemplateName = i.TemplateName
END 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: 
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPPartSettingsTemplatei] 
   ON  [dbo].[VPPartSettingsTemplate] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	INSERT INTO vVPPartSettingsTemplate (TemplateName, IsStandard, PartName, ColumnNumber, RowNumber, Height, Width, ConfigurationSettings, CollapseDirection, ShowConfiguration, CanCollapse)
		SELECT TemplateName, IsStandard, PartName, ColumnNumber, RowNumber, Height, Width, ConfigurationSettings, CollapseDirection, ShowConfiguration, CanCollapse FROM inserted
ELSE
	INSERT INTO vVPPartSettingsTemplatec (TemplateName, IsStandard, PartName, ColumnNumber, RowNumber, Height, Width, ConfigurationSettings, CollapseDirection, ShowConfiguration, CanCollapse)
		SELECT TemplateName, IsStandard, PartName, ColumnNumber, RowNumber, Height, Width, ConfigurationSettings, CollapseDirection, ShowConfiguration, CanCollapse FROM inserted

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: 
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPPartSettingsTemplateu] 
   ON  [dbo].[VPPartSettingsTemplate] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	UPDATE vVPPartSettingsTemplate SET
		TemplateName = i.TemplateName, 
		IsStandard = i.IsStandard, 
		PartName = i.PartName, 
		ColumnNumber = i.ColumnNumber, 
		RowNumber = i.RowNumber, 
		Height = i.Height, 
		Width = i.Width, 
		ConfigurationSettings = i.ConfigurationSettings,
		CollapseDirection = i.CollapseDirection,
		ShowConfiguration = i.ShowConfiguration,
		CanCollapse = i.ShowConfiguration
	FROM vVPPartSettingsTemplate
	INNER JOIN inserted i ON vVPPartSettingsTemplate.KeyID = i.KeyID AND vVPPartSettingsTemplate.TemplateName = i.TemplateName
ELSE
	UPDATE vVPPartSettingsTemplatec SET
		TemplateName = i.TemplateName, 
		IsStandard = i.IsStandard, 
		PartName = i.PartName, 
		ColumnNumber = i.ColumnNumber, 
		RowNumber = i.RowNumber, 
		Height = i.Height, 
		Width = i.Width, 
		ConfigurationSettings = i.ConfigurationSettings,
		CollapseDirection = i.CollapseDirection,
		ShowConfiguration = i.ShowConfiguration,
		CanCollapse = i.ShowConfiguration
	FROM vVPPartSettingsTemplatec
	INNER JOIN inserted i ON vVPPartSettingsTemplatec.KeyID = i.KeyID AND vVPPartSettingsTemplatec.TemplateName = i.TemplateName
END


GO
GRANT SELECT ON  [dbo].[VPPartSettingsTemplate] TO [public]
GRANT INSERT ON  [dbo].[VPPartSettingsTemplate] TO [public]
GRANT DELETE ON  [dbo].[VPPartSettingsTemplate] TO [public]
GRANT UPDATE ON  [dbo].[VPPartSettingsTemplate] TO [public]
GRANT SELECT ON  [dbo].[VPPartSettingsTemplate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPPartSettingsTemplate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPPartSettingsTemplate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPPartSettingsTemplate] TO [Viewpoint]
GO
