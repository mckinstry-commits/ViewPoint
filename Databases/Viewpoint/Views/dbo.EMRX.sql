SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMRX] as select a.* From bEMRX a

GO
GRANT SELECT ON  [dbo].[EMRX] TO [public]
GRANT INSERT ON  [dbo].[EMRX] TO [public]
GRANT DELETE ON  [dbo].[EMRX] TO [public]
GRANT UPDATE ON  [dbo].[EMRX] TO [public]
GO
