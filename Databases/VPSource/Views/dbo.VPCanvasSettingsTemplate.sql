SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasSettingsTemplate
AS
SELECT     *
FROM         vVPCanvasSettingsTemplate
UNION ALL
SELECT     *
FROM         vVPCanvasSettingsTemplatec

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
CREATE TRIGGER [dbo].[vtVPCanvasSettingsTemplated] 
   ON  [dbo].[VPCanvasSettingsTemplate] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	DELETE vVPCanvasSettingsTemplate
	FROM vVPCanvasSettingsTemplate
	INNER JOIN deleted i ON vVPCanvasSettingsTemplate.KeyID = i.KeyID AND vVPCanvasSettingsTemplate.TemplateName = i.TemplateName

ELSE
	DELETE vVPCanvasSettingsTemplatec
	FROM vVPCanvasSettingsTemplatec
	INNER JOIN deleted i ON vVPCanvasSettingsTemplatec.KeyID = i.KeyID AND vVPCanvasSettingsTemplatec.TemplateName = i.TemplateName

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
CREATE TRIGGER [dbo].[vtVPCanvasSettingsTemplatei] 
   ON  [dbo].[VPCanvasSettingsTemplate] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	INSERT INTO vVPCanvasSettingsTemplate (TemplateName, IsStandard, NumberOfRows, NumberOfColumns, RefreshInterval, TableLayout)
		SELECT TemplateName, 'Y', NumberOfRows, NumberOfColumns, RefreshInterval, TableLayout FROM inserted
ELSE
	INSERT INTO vVPCanvasSettingsTemplatec (TemplateName, IsStandard, NumberOfRows, NumberOfColumns, RefreshInterval, TableLayout)
		SELECT TemplateName, 'N', NumberOfRows, NumberOfColumns, RefreshInterval, TableLayout FROM inserted
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
CREATE TRIGGER [dbo].[vtVPCanvasSettingsTemplateu] 
   ON  [dbo].[VPCanvasSettingsTemplate] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	UPDATE vVPCanvasSettingsTemplate SET
		TemplateName = i.TemplateName,
		IsStandard = i.IsStandard,
		NumberOfRows = i.NumberOfRows,
		NumberOfColumns = i.NumberOfColumns,
		RefreshInterval = i.RefreshInterval,
		TableLayout = i.TableLayout
	FROM vVPCanvasSettingsTemplate
	INNER JOIN inserted i ON vVPCanvasSettingsTemplate.KeyID = i.KeyID AND vVPCanvasSettingsTemplate.TemplateName = i.TemplateName

ELSE
	UPDATE vVPCanvasSettingsTemplatec SET
		TemplateName = i.TemplateName,
		IsStandard = i.IsStandard,
		NumberOfRows = i.NumberOfRows,
		NumberOfColumns = i.NumberOfColumns,
		RefreshInterval = i.RefreshInterval,
		TableLayout = i.TableLayout
	FROM vVPCanvasSettingsTemplatec
	INNER JOIN inserted i ON vVPCanvasSettingsTemplatec.KeyID = i.KeyID AND vVPCanvasSettingsTemplatec.TemplateName = i.TemplateName

END 
GO
GRANT SELECT ON  [dbo].[VPCanvasSettingsTemplate] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasSettingsTemplate] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasSettingsTemplate] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasSettingsTemplate] TO [public]
GO
