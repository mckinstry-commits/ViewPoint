SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefUM as select a.* From Viewpoint.dbo.budxrefUM a;
GO
GRANT REFERENCES ON  [dbo].[udxrefUM] TO [public]
GRANT SELECT ON  [dbo].[udxrefUM] TO [public]
GRANT INSERT ON  [dbo].[udxrefUM] TO [public]
GRANT DELETE ON  [dbo].[udxrefUM] TO [public]
GRANT UPDATE ON  [dbo].[udxrefUM] TO [public]
GO
