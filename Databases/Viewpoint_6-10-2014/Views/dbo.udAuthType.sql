SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udAuthType] as select a.* From budAuthType a
GO
GRANT SELECT ON  [dbo].[udAuthType] TO [public]
GRANT INSERT ON  [dbo].[udAuthType] TO [public]
GRANT DELETE ON  [dbo].[udAuthType] TO [public]
GRANT UPDATE ON  [dbo].[udAuthType] TO [public]
GO
