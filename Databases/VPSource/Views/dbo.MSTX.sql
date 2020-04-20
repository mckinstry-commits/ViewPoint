SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSTX] as select a.* From bMSTX a
GO
GRANT SELECT ON  [dbo].[MSTX] TO [public]
GRANT INSERT ON  [dbo].[MSTX] TO [public]
GRANT DELETE ON  [dbo].[MSTX] TO [public]
GRANT UPDATE ON  [dbo].[MSTX] TO [public]
GO
