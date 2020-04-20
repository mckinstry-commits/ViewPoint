SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[WFTemplateTasks]
AS
SELECT * FROM vWFTemplateTasksc
UNION ALL
SELECT * FROM vWFVPTemplateTasks


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 3/17/08
-- Description:	Trigger to seperate system and user templates
-- =============================================
CREATE TRIGGER [dbo].[vtWFTemplateTasksViewd]
   ON  [dbo].[WFTemplateTasks] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE FROM vWFVPTemplateTasks 
		   FROM vWFVPTemplateTasks t
		   INNER JOIN deleted d on t.KeyID = d.KeyID and d.IsStandard='Y'

	DELETE FROM vWFTemplateTasksc
		   FROM vWFTemplateTasksc t
		   INNER JOIN deleted d on t.KeyID = d.KeyID and d.IsStandard='N'

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 3/17/08
-- Description:	Trigger to seperate system and user template tasks
-- =============================================
CREATE TRIGGER [dbo].[vtWFTemplateTasksViewi] 
   ON  [dbo].[WFTemplateTasks] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    INSERT INTO vWFVPTemplateTasks SELECT Task, Template, Summary, IsTaskRequired, UseEmail, [Description], TaskType, VPName, IsStandard, AddedBy, AddedOn, ChangedBy, ChangedOn, Notes, ReportID, UniqueAttchID FROM inserted WHERE IsStandard = 'Y'
	INSERT INTO vWFTemplateTasksc SELECT Task, Template, Summary, IsTaskRequired, UseEmail, [Description], TaskType, VPName, IsStandard, AddedBy, AddedOn, ChangedBy, ChangedOn, Notes, ReportID, UniqueAttchID FROM inserted WHERE IsStandard = 'N'

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 3/17/08
-- Description:	Trigger to seperate system and user templates
-- =============================================
CREATE TRIGGER [dbo].[vtWFTemplateTasksViewu]
   ON  [dbo].[WFTemplateTasks] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE vWFVPTemplateTasks 
	SET Task = i.Task, 
	Template = i.Template,
	Summary = i.Summary,
	IsTaskRequired = i.IsTaskRequired,
	UseEmail = i.UseEmail,
	[Description] = i.[Description],
	TaskType = i.TaskType,
	VPName = i.VPName,
	IsStandard = i.IsStandard,
	AddedBy = i.AddedBy,
	AddedOn = i.AddedOn,
	ChangedBy = i.ChangedBy,
	ChangedOn = i.ChangedOn,
	Notes = i.Notes,
	ReportID = i.ReportID,
	UniqueAttchID = i.UniqueAttchID
	FROM vWFVPTemplateTasks t
	INNER JOIN inserted i ON t.KeyID = i.KeyID AND i.IsStandard = 'Y'

	UPDATE vWFTemplateTasksc 
	SET Task = i.Task, 
	Template = i.Template,
	Summary = i.Summary,
	IsTaskRequired = i.IsTaskRequired,
	UseEmail = i.UseEmail,
	[Description] = i.[Description],
	TaskType = i.TaskType,
	VPName = i.VPName,
	IsStandard = i.IsStandard,
	AddedBy = i.AddedBy,
	AddedOn = i.AddedOn,
	ChangedBy = i.ChangedBy,
	ChangedOn = i.ChangedOn,
	Notes = i.Notes,
	ReportID = i.ReportID,
	UniqueAttchID = i.UniqueAttchID
	FROM vWFTemplateTasksc t
	INNER JOIN inserted i ON t.KeyID = i.KeyID AND i.IsStandard = 'N'

END

GO
GRANT SELECT ON  [dbo].[WFTemplateTasks] TO [public]
GRANT INSERT ON  [dbo].[WFTemplateTasks] TO [public]
GRANT DELETE ON  [dbo].[WFTemplateTasks] TO [public]
GRANT UPDATE ON  [dbo].[WFTemplateTasks] TO [public]
GRANT SELECT ON  [dbo].[WFTemplateTasks] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFTemplateTasks] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFTemplateTasks] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFTemplateTasks] TO [Viewpoint]
GO
