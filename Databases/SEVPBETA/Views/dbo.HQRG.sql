SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQRG] as select a.* From vHQRG a
GO
GRANT SELECT ON  [dbo].[HQRG] TO [public]
GRANT INSERT ON  [dbo].[HQRG] TO [public]
GRANT DELETE ON  [dbo].[HQRG] TO [public]
GRANT UPDATE ON  [dbo].[HQRG] TO [public]
GO
