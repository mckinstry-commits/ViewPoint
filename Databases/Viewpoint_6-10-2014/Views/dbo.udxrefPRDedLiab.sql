SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udxrefPRDedLiab] as select a.* From budxrefPRDedLiab a
GO
GRANT SELECT ON  [dbo].[udxrefPRDedLiab] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRDedLiab] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRDedLiab] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRDedLiab] TO [public]
GRANT SELECT ON  [dbo].[udxrefPRDedLiab] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udxrefPRDedLiab] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udxrefPRDedLiab] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udxrefPRDedLiab] TO [Viewpoint]
GO
