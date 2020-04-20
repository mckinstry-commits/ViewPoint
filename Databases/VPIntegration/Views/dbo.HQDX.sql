SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQDX] as select a.* From bHQDX a

GO
GRANT SELECT ON  [dbo].[HQDX] TO [public]
GRANT INSERT ON  [dbo].[HQDX] TO [public]
GRANT DELETE ON  [dbo].[HQDX] TO [public]
GRANT UPDATE ON  [dbo].[HQDX] TO [public]
GO
