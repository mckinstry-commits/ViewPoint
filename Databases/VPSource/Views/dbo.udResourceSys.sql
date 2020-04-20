SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udResourceSys] as select a.* From budResourceSys a
GO
GRANT SELECT ON  [dbo].[udResourceSys] TO [public]
GRANT INSERT ON  [dbo].[udResourceSys] TO [public]
GRANT DELETE ON  [dbo].[udResourceSys] TO [public]
GRANT UPDATE ON  [dbo].[udResourceSys] TO [public]
GO
