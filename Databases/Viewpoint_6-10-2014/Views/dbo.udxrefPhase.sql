SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefPhase as select a.* From Viewpoint.dbo.budxrefPhase a;
GO
GRANT REFERENCES ON  [dbo].[udxrefPhase] TO [public]
GRANT SELECT ON  [dbo].[udxrefPhase] TO [public]
GRANT INSERT ON  [dbo].[udxrefPhase] TO [public]
GRANT DELETE ON  [dbo].[udxrefPhase] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPhase] TO [public]
GRANT SELECT ON  [dbo].[udxrefPhase] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udxrefPhase] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udxrefPhase] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udxrefPhase] TO [Viewpoint]
GO
