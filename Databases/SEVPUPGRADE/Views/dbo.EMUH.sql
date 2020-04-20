SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMUH] as select a.* From bEMUH a

GO
GRANT SELECT ON  [dbo].[EMUH] TO [public]
GRANT INSERT ON  [dbo].[EMUH] TO [public]
GRANT DELETE ON  [dbo].[EMUH] TO [public]
GRANT UPDATE ON  [dbo].[EMUH] TO [public]
GO
