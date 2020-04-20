SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DDCustomConstraintErrorMsg]
AS
SELECT     ConstraintName, ErrorMessage, Country
FROM         dbo.vDDCustomConstraintErrorMsg

GO
GRANT SELECT ON  [dbo].[DDCustomConstraintErrorMsg] TO [public]
GRANT INSERT ON  [dbo].[DDCustomConstraintErrorMsg] TO [public]
GRANT DELETE ON  [dbo].[DDCustomConstraintErrorMsg] TO [public]
GRANT UPDATE ON  [dbo].[DDCustomConstraintErrorMsg] TO [public]
GRANT SELECT ON  [dbo].[DDCustomConstraintErrorMsg] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDCustomConstraintErrorMsg] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDCustomConstraintErrorMsg] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDCustomConstraintErrorMsg] TO [Viewpoint]
GO
