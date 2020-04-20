SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[DDCustomActionParameters] AS SELECT * FROM [vDDCustomActionParameters]
GO
GRANT SELECT ON  [dbo].[DDCustomActionParameters] TO [public]
GRANT INSERT ON  [dbo].[DDCustomActionParameters] TO [public]
GRANT DELETE ON  [dbo].[DDCustomActionParameters] TO [public]
GRANT UPDATE ON  [dbo].[DDCustomActionParameters] TO [public]
GRANT SELECT ON  [dbo].[DDCustomActionParameters] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDCustomActionParameters] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDCustomActionParameters] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDCustomActionParameters] TO [Viewpoint]
GO
