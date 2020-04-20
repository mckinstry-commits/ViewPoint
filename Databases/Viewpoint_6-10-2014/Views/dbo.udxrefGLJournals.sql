SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefGLJournals as select a.* From Viewpoint.dbo.budxrefGLJournals a;
GO
GRANT REFERENCES ON  [dbo].[udxrefGLJournals] TO [public]
GRANT SELECT ON  [dbo].[udxrefGLJournals] TO [public]
GRANT INSERT ON  [dbo].[udxrefGLJournals] TO [public]
GRANT DELETE ON  [dbo].[udxrefGLJournals] TO [public]
GRANT UPDATE ON  [dbo].[udxrefGLJournals] TO [public]
GRANT SELECT ON  [dbo].[udxrefGLJournals] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udxrefGLJournals] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udxrefGLJournals] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udxrefGLJournals] TO [Viewpoint]
GO
