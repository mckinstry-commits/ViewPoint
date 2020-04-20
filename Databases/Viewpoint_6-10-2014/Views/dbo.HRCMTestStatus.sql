SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRCMTestStatus]
as select a.* From bHRCM a
where a.Type = 'U'



GO
GRANT SELECT ON  [dbo].[HRCMTestStatus] TO [public]
GRANT INSERT ON  [dbo].[HRCMTestStatus] TO [public]
GRANT DELETE ON  [dbo].[HRCMTestStatus] TO [public]
GRANT UPDATE ON  [dbo].[HRCMTestStatus] TO [public]
GRANT SELECT ON  [dbo].[HRCMTestStatus] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRCMTestStatus] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRCMTestStatus] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRCMTestStatus] TO [Viewpoint]
GO
