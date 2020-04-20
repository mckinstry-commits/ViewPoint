SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udSinNum] as select a.* From budSinNum a
GO
GRANT SELECT ON  [dbo].[udSinNum] TO [public]
GRANT INSERT ON  [dbo].[udSinNum] TO [public]
GRANT DELETE ON  [dbo].[udSinNum] TO [public]
GRANT UPDATE ON  [dbo].[udSinNum] TO [public]
GO
