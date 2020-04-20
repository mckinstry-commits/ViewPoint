SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDSLDatatypes] 
as 
select Datatype, TableName, InstanceColumn, QualifierColumn, InUse 
from vDDSL

GO
GRANT SELECT ON  [dbo].[DDSLDatatypes] TO [public]
GRANT INSERT ON  [dbo].[DDSLDatatypes] TO [public]
GRANT DELETE ON  [dbo].[DDSLDatatypes] TO [public]
GRANT UPDATE ON  [dbo].[DDSLDatatypes] TO [public]
GO
