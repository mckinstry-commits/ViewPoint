SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PREAEmplMonths]
AS
SELECT DISTINCT PRCo, Employee, Mth
FROM         dbo.bPREA

GO
GRANT SELECT ON  [dbo].[PREAEmplMonths] TO [public]
GRANT INSERT ON  [dbo].[PREAEmplMonths] TO [public]
GRANT DELETE ON  [dbo].[PREAEmplMonths] TO [public]
GRANT UPDATE ON  [dbo].[PREAEmplMonths] TO [public]
GRANT SELECT ON  [dbo].[PREAEmplMonths] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PREAEmplMonths] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PREAEmplMonths] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PREAEmplMonths] TO [Viewpoint]
GO
