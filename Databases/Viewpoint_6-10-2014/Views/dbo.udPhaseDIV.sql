SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udPhaseDIV] as select a.* From budPhaseDIV a
GO
GRANT SELECT ON  [dbo].[udPhaseDIV] TO [public]
GRANT INSERT ON  [dbo].[udPhaseDIV] TO [public]
GRANT DELETE ON  [dbo].[udPhaseDIV] TO [public]
GRANT UPDATE ON  [dbo].[udPhaseDIV] TO [public]
GO
