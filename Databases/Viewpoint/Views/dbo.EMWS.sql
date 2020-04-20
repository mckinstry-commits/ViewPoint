SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMWS] as select a.* From bEMWS a
GO
GRANT SELECT ON  [dbo].[EMWS] TO [public]
GRANT INSERT ON  [dbo].[EMWS] TO [public]
GRANT DELETE ON  [dbo].[EMWS] TO [public]
GRANT UPDATE ON  [dbo].[EMWS] TO [public]
GO
