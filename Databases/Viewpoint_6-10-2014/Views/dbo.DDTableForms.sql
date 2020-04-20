SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DDTableForms] AS SELECT * FROM vDDTableForms

GO
GRANT SELECT ON  [dbo].[DDTableForms] TO [public]
GRANT INSERT ON  [dbo].[DDTableForms] TO [public]
GRANT DELETE ON  [dbo].[DDTableForms] TO [public]
GRANT UPDATE ON  [dbo].[DDTableForms] TO [public]
GRANT SELECT ON  [dbo].[DDTableForms] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDTableForms] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDTableForms] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDTableForms] TO [Viewpoint]
GO
