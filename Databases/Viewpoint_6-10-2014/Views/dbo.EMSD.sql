SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSD] as select a.* From bEMSD a

GO
GRANT SELECT ON  [dbo].[EMSD] TO [public]
GRANT INSERT ON  [dbo].[EMSD] TO [public]
GRANT DELETE ON  [dbo].[EMSD] TO [public]
GRANT UPDATE ON  [dbo].[EMSD] TO [public]
GRANT SELECT ON  [dbo].[EMSD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMSD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMSD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMSD] TO [Viewpoint]
GO
