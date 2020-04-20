SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDM] as select a.* From bEMDM a
GO
GRANT SELECT ON  [dbo].[EMDM] TO [public]
GRANT INSERT ON  [dbo].[EMDM] TO [public]
GRANT DELETE ON  [dbo].[EMDM] TO [public]
GRANT UPDATE ON  [dbo].[EMDM] TO [public]
GO
