SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SQLReservedWords] as select a.* From vSQLReservedWords a
GO
GRANT SELECT ON  [dbo].[SQLReservedWords] TO [public]
GRANT INSERT ON  [dbo].[SQLReservedWords] TO [public]
GRANT DELETE ON  [dbo].[SQLReservedWords] TO [public]
GRANT UPDATE ON  [dbo].[SQLReservedWords] TO [public]
GRANT SELECT ON  [dbo].[SQLReservedWords] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SQLReservedWords] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SQLReservedWords] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SQLReservedWords] TO [Viewpoint]
GO
