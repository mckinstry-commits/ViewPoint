SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[WFTemplates] as 
select * from vWFVPTemplates
union all
select * from vWFTemplatesc


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
CREATE TRIGGER [dbo].[vtWFTemplatesViewd]
   ON  [dbo].[WFTemplates] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE FROM vWFVPTemplates 
		   FROM vWFVPTemplates t
		   INNER JOIN deleted d on t.KeyID = d.KeyID and d.IsStandard='Y'

	DELETE FROM vWFTemplatesc 
		   FROM vWFTemplatesc t
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
-- Description:	Trigger to seperate system and user templates
-- =============================================
CREATE TRIGGER [dbo].[vtWFTemplatesViewi] 
   ON  [dbo].[WFTemplates] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    INSERT INTO vWFVPTemplates SELECT Template,[Description],Revised,EnforceOrder,UseEmail,IsActive,IsStandard,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,UniqueAttchID FROM inserted WHERE IsStandard = 'Y'
	INSERT INTO vWFTemplatesc SELECT Template,[Description],Revised,EnforceOrder,UseEmail,IsActive,IsStandard,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,UniqueAttchID FROM inserted WHERE IsStandard = 'N'

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
CREATE TRIGGER [dbo].[vtWFTemplatesViewu]
   ON  [dbo].[WFTemplates] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE vWFVPTemplates 
	SET Template = i.Template,
	[Description] = i.[Description],
	Revised = i.Revised,
	EnforceOrder = i.EnforceOrder,
	UseEmail = i.UseEmail,
	IsActive = i.IsActive,
	IsStandard = i.IsStandard,
	AddedBy = i.AddedBy,
	AddedOn = i.AddedOn,
	ChangedBy = i.ChangedBy,
	ChangedOn = i.ChangedOn,
	Notes = i.Notes,
	UniqueAttchID = i.UniqueAttchID
	FROM vWFVPTemplates t
	INNER JOIN inserted i ON t.KeyID = i.KeyID AND i.IsStandard = 'Y'

    UPDATE vWFTemplatesc 
	SET Template = i.Template,
	[Description] = i.[Description],
	Revised = i.Revised,
	EnforceOrder = i.EnforceOrder,
	UseEmail = i.UseEmail,
	IsActive = i.IsActive,
	IsStandard = i.IsStandard,
	AddedBy = i.AddedBy,
	AddedOn = i.AddedOn,
	ChangedBy = i.ChangedBy,
	ChangedOn = i.ChangedOn,
	Notes = i.Notes,
	UniqueAttchID = i.UniqueAttchID
	FROM vWFTemplatesc t
	INNER JOIN inserted i ON t.KeyID = i.KeyID AND i.IsStandard = 'N'

END

GO
GRANT SELECT ON  [dbo].[WFTemplates] TO [public]
GRANT INSERT ON  [dbo].[WFTemplates] TO [public]
GRANT DELETE ON  [dbo].[WFTemplates] TO [public]
GRANT UPDATE ON  [dbo].[WFTemplates] TO [public]
GRANT SELECT ON  [dbo].[WFTemplates] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFTemplates] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFTemplates] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFTemplates] TO [Viewpoint]
GO
