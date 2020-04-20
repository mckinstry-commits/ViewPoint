SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefPREarn as select a.* From Viewpoint.dbo.budxrefPREarn a;
GO
GRANT REFERENCES ON  [dbo].[udxrefPREarn] TO [public]
GRANT SELECT ON  [dbo].[udxrefPREarn] TO [public]
GRANT INSERT ON  [dbo].[udxrefPREarn] TO [public]
GRANT DELETE ON  [dbo].[udxrefPREarn] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPREarn] TO [public]
GO
