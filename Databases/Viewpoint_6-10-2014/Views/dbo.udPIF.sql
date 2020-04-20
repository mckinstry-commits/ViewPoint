SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udPIF] as select a.* From budPIF a
GO
GRANT SELECT ON  [dbo].[udPIF] TO [public]
GRANT INSERT ON  [dbo].[udPIF] TO [public]
GRANT DELETE ON  [dbo].[udPIF] TO [public]
GRANT UPDATE ON  [dbo].[udPIF] TO [public]
GO
