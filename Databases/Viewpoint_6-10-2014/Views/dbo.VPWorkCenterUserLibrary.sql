SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[VPWorkCenterUserLibrary] as 

SELECT vVPWorkCenterUserLibrary.*
		,p.value('TemplateName[1]', 'varchar(max)') AS Template
		,tg.[Description] AS [Type]
		,p.value('RefreshInterval[1]', 'int') / 60 AS RefreshInterval
FROM vVPWorkCenterUserLibrary 
CROSS APPLY WorkCenterInfo.nodes('/root/VPCanvasSettings/row') t(p)
INNER JOIN VPCanvasSettingsTemplate st on st.TemplateName = p.value('TemplateName[1]', 'varchar(max)')
INNER JOIN VPCanvasTemplateGroup tg on tg.KeyID = st.GroupID


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************************************
* Created: HH 3/28/2013 TFS 45214 delete trigger since VPWorkCenterUserLibrary is a joined view
* Modified: 
*
*	This trigger deletes the table vVPWorkCenterUserLibrary entry since its view VPWorkCenterUserLibrary is joined
*
************************************************************************************************/
CREATE TRIGGER [dbo].[vtVPWorkCenterUserLibraryd] 
   ON  [dbo].[VPWorkCenterUserLibrary] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE vVPWorkCenterUserLibrary
	FROM vVPWorkCenterUserLibrary
	INNER JOIN deleted d ON vVPWorkCenterUserLibrary.KeyID = d.KeyID
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: HH 3/28/2013 - TFS 45214
* Modified: 
*
*	This trigger updates xml content of VPWorkCenterUserLibrary.WorkCenterInfo
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPWorkCenterUserLibraryu] 
   ON  [dbo].[VPWorkCenterUserLibrary] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Convert RefreshInterval from minutes to milliseconds
	DECLARE @RefreshInterval int
	SELECT @RefreshInterval = i.RefreshInterval * 60 
	FROM inserted i

	UPDATE vVPWorkCenterUserLibrary SET
		LibraryName = i.LibraryName, 
		[Owner] = i.[Owner],
		WorkCenterInfo.modify('replace value of (/root/VPCanvasSettings/row/RefreshInterval/text())[1] with sql:variable("@RefreshInterval")'),
		PublicShare = i.PublicShare,
		DateModified = GETDATE(),
		Notes = i.Notes
	FROM vVPWorkCenterUserLibrary
	INNER JOIN inserted i ON vVPWorkCenterUserLibrary.KeyID = i.KeyID
	
END


GO
GRANT SELECT ON  [dbo].[VPWorkCenterUserLibrary] TO [public]
GRANT INSERT ON  [dbo].[VPWorkCenterUserLibrary] TO [public]
GRANT DELETE ON  [dbo].[VPWorkCenterUserLibrary] TO [public]
GRANT UPDATE ON  [dbo].[VPWorkCenterUserLibrary] TO [public]
GRANT SELECT ON  [dbo].[VPWorkCenterUserLibrary] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPWorkCenterUserLibrary] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPWorkCenterUserLibrary] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPWorkCenterUserLibrary] TO [Viewpoint]
GO
