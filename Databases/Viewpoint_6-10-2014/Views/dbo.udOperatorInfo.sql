SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udOperatorInfo] as select a.* From budOperatorInfo a
GO
GRANT SELECT ON  [dbo].[udOperatorInfo] TO [public]
GRANT INSERT ON  [dbo].[udOperatorInfo] TO [public]
GRANT DELETE ON  [dbo].[udOperatorInfo] TO [public]
GRANT UPDATE ON  [dbo].[udOperatorInfo] TO [public]
GO
