SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udJCCHDel] as select a.* From budJCCHDel a
GO
GRANT SELECT ON  [dbo].[udJCCHDel] TO [public]
GRANT INSERT ON  [dbo].[udJCCHDel] TO [public]
GRANT DELETE ON  [dbo].[udJCCHDel] TO [public]
GRANT UPDATE ON  [dbo].[udJCCHDel] TO [public]
GO
