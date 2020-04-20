SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[WFTemplateSteps]
AS
SELECT * FROM vWFTemplateStepsc
UNION ALL
SELECT * FROM vWFVPTemplateSteps

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
CREATE TRIGGER [dbo].[vtWFTemplateStepsViewd]
   ON  [dbo].[WFTemplateSteps] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE FROM vWFVPTemplateSteps 
		   FROM vWFVPTemplateSteps t
		   INNER JOIN deleted d on t.KeyID = d.KeyID 
		   WHERE d.IsStandard='Y'

	DELETE FROM vWFTemplateStepsc
		   FROM vWFTemplateStepsc t
		   INNER JOIN deleted d on t.KeyID = d.KeyID 
		   WHERE d.IsStandard='N'
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
CREATE TRIGGER [dbo].[vtWFTemplateStepsViewi] 
   ON  [dbo].[WFTemplateSteps] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    INSERT INTO vWFVPTemplateSteps SELECT Step,Task,Template,Summary,IsStepRequired,UseEmail,[Description],StepType,VPName,IsStandard,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,ReportID,UniqueAttchID FROM inserted WHERE IsStandard = 'Y'
	INSERT INTO vWFTemplateStepsc SELECT Step,Task,Template,Summary,IsStepRequired,UseEmail,[Description],StepType,VPName,IsStandard,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,ReportID,UniqueAttchID FROM inserted WHERE IsStandard = 'N'

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
CREATE TRIGGER [dbo].[vtWFTemplateStepsViewu]
   ON  [dbo].[WFTemplateSteps] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE vWFVPTemplateSteps 
	SET Step = i.Step,
	Task = i.Task, 
	Template = i.Template,
	Summary = i.Summary,
	IsStepRequired = i.IsStepRequired,
	UseEmail = i.UseEmail,
	[Description] = i.[Description],
	StepType = i.StepType,
	VPName = i.VPName,
	IsStandard = i.IsStandard,
	AddedBy = i.AddedBy,
	AddedOn = i.AddedOn,
	ChangedBy = i.ChangedBy,
	ChangedOn = i.ChangedOn,
	Notes = i.Notes,
	ReportID = i.ReportID,
	UniqueAttchID = i.UniqueAttchID
	FROM vWFVPTemplateSteps t
	INNER JOIN inserted i ON t.KeyID = i.KeyID AND i.IsStandard = 'Y'

	UPDATE vWFTemplateStepsc 
	SET Step = i.Step,
	Task = i.Task, 
	Template = i.Template,
	Summary = i.Summary,
	IsStepRequired = i.IsStepRequired,
	UseEmail = i.UseEmail,
	[Description] = i.[Description],
	StepType = i.StepType,
	VPName = i.VPName,
	IsStandard = i.IsStandard,
	AddedBy = i.AddedBy,
	AddedOn = i.AddedOn,
	ChangedBy = i.ChangedBy,
	ChangedOn = i.ChangedOn,
	Notes = i.Notes,
	ReportID = i.ReportID,
	UniqueAttchID = i.UniqueAttchID
	FROM vWFTemplateStepsc t
	INNER JOIN inserted i ON t.KeyID = i.KeyID AND i.IsStandard = 'N'

END

GO
GRANT SELECT ON  [dbo].[WFTemplateSteps] TO [public]
GRANT INSERT ON  [dbo].[WFTemplateSteps] TO [public]
GRANT DELETE ON  [dbo].[WFTemplateSteps] TO [public]
GRANT UPDATE ON  [dbo].[WFTemplateSteps] TO [public]
GRANT SELECT ON  [dbo].[WFTemplateSteps] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFTemplateSteps] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFTemplateSteps] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFTemplateSteps] TO [Viewpoint]
GO
