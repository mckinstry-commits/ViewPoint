SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udJCCMEnvInfo] as select a.* From budJCCMEnvInfo a
GO
GRANT SELECT ON  [dbo].[udJCCMEnvInfo] TO [public]
GRANT INSERT ON  [dbo].[udJCCMEnvInfo] TO [public]
GRANT DELETE ON  [dbo].[udJCCMEnvInfo] TO [public]
GRANT UPDATE ON  [dbo].[udJCCMEnvInfo] TO [public]
GO
