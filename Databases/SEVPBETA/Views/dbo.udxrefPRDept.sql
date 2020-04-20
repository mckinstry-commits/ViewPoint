SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefPRDept as select a.* From Viewpoint.dbo.budxrefPRDept a;
GO
GRANT REFERENCES ON  [dbo].[udxrefPRDept] TO [public]
GRANT SELECT ON  [dbo].[udxrefPRDept] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRDept] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRDept] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRDept] TO [public]
GO
