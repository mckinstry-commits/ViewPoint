SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefGLSubLedger as select a.* From Viewpoint.dbo.budxrefGLSubLedger a;
GO
GRANT REFERENCES ON  [dbo].[udxrefGLSubLedger] TO [public]
GRANT SELECT ON  [dbo].[udxrefGLSubLedger] TO [public]
GRANT INSERT ON  [dbo].[udxrefGLSubLedger] TO [public]
GRANT DELETE ON  [dbo].[udxrefGLSubLedger] TO [public]
GRANT UPDATE ON  [dbo].[udxrefGLSubLedger] TO [public]
GRANT SELECT ON  [dbo].[udxrefGLSubLedger] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udxrefGLSubLedger] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udxrefGLSubLedger] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udxrefGLSubLedger] TO [Viewpoint]
GO
