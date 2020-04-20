SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udRegion] as select a.* From budRegion a
GO
GRANT SELECT ON  [dbo].[udRegion] TO [public]
GRANT INSERT ON  [dbo].[udRegion] TO [public]
GRANT DELETE ON  [dbo].[udRegion] TO [public]
GRANT UPDATE ON  [dbo].[udRegion] TO [public]
GO
