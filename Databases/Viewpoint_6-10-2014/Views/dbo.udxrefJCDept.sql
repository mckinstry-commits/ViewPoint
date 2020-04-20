SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefJCDept as select a.* From Viewpoint.dbo.budxrefJCDept a;
GO
GRANT REFERENCES ON  [dbo].[udxrefJCDept] TO [public]
GRANT SELECT ON  [dbo].[udxrefJCDept] TO [public]
GRANT INSERT ON  [dbo].[udxrefJCDept] TO [public]
GRANT DELETE ON  [dbo].[udxrefJCDept] TO [public]
GRANT UPDATE ON  [dbo].[udxrefJCDept] TO [public]
GRANT SELECT ON  [dbo].[udxrefJCDept] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udxrefJCDept] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udxrefJCDept] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udxrefJCDept] TO [Viewpoint]
GO
