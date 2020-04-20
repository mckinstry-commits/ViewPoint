SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udCSIPhaseSeg] as select a.* From budCSIPhaseSeg a
GO
GRANT SELECT ON  [dbo].[udCSIPhaseSeg] TO [public]
GRANT INSERT ON  [dbo].[udCSIPhaseSeg] TO [public]
GRANT DELETE ON  [dbo].[udCSIPhaseSeg] TO [public]
GRANT UPDATE ON  [dbo].[udCSIPhaseSeg] TO [public]
GO
