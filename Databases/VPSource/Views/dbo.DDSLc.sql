SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDSLc
AS
SELECT     TableName, Datatype, InstanceColumn, QualifierColumn, InUse
FROM         dbo.vDDSLc

GO
GRANT SELECT ON  [dbo].[DDSLc] TO [public]
GRANT INSERT ON  [dbo].[DDSLc] TO [public]
GRANT DELETE ON  [dbo].[DDSLc] TO [public]
GRANT UPDATE ON  [dbo].[DDSLc] TO [public]
GO
