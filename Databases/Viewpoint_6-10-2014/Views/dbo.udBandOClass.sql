SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udBandOClass] as select a.* From budBandOClass a
GO
GRANT SELECT ON  [dbo].[udBandOClass] TO [public]
GRANT INSERT ON  [dbo].[udBandOClass] TO [public]
GRANT DELETE ON  [dbo].[udBandOClass] TO [public]
GRANT UPDATE ON  [dbo].[udBandOClass] TO [public]
GO
