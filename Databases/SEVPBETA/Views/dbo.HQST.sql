SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQST] as select a.* From bHQST a

GO
GRANT SELECT ON  [dbo].[HQST] TO [public]
GRANT INSERT ON  [dbo].[HQST] TO [public]
GRANT DELETE ON  [dbo].[HQST] TO [public]
GRANT UPDATE ON  [dbo].[HQST] TO [public]
GO
