SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udStandardPS] as select a.* From budStandardPS a
GO
GRANT SELECT ON  [dbo].[udStandardPS] TO [public]
GRANT INSERT ON  [dbo].[udStandardPS] TO [public]
GRANT DELETE ON  [dbo].[udStandardPS] TO [public]
GRANT UPDATE ON  [dbo].[udStandardPS] TO [public]
GO
