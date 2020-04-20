SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSHO] as select a.* From bMSHO a
GO
GRANT SELECT ON  [dbo].[MSHO] TO [public]
GRANT INSERT ON  [dbo].[MSHO] TO [public]
GRANT DELETE ON  [dbo].[MSHO] TO [public]
GRANT UPDATE ON  [dbo].[MSHO] TO [public]
GO
