SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udPublicFundTrail] as select a.* From budPublicFundTrail a
GO
GRANT SELECT ON  [dbo].[udPublicFundTrail] TO [public]
GRANT INSERT ON  [dbo].[udPublicFundTrail] TO [public]
GRANT DELETE ON  [dbo].[udPublicFundTrail] TO [public]
GRANT UPDATE ON  [dbo].[udPublicFundTrail] TO [public]
GO
