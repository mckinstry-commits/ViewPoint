SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udJobResSys] as select a.* From budJobResSys a
GO
GRANT SELECT ON  [dbo].[udJobResSys] TO [public]
GRANT INSERT ON  [dbo].[udJobResSys] TO [public]
GRANT DELETE ON  [dbo].[udJobResSys] TO [public]
GRANT UPDATE ON  [dbo].[udJobResSys] TO [public]
GO
