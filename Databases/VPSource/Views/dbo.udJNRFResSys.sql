SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udJNRFResSys] as select a.* From budJNRFResSys a
GO
GRANT SELECT ON  [dbo].[udJNRFResSys] TO [public]
GRANT INSERT ON  [dbo].[udJNRFResSys] TO [public]
GRANT DELETE ON  [dbo].[udJNRFResSys] TO [public]
GRANT UPDATE ON  [dbo].[udJNRFResSys] TO [public]
GO
