SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSP] as select a.* From bEMSP a

GO
GRANT SELECT ON  [dbo].[EMSP] TO [public]
GRANT INSERT ON  [dbo].[EMSP] TO [public]
GRANT DELETE ON  [dbo].[EMSP] TO [public]
GRANT UPDATE ON  [dbo].[EMSP] TO [public]
GO
