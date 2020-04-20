SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMAC] as select a.* From bCMAC a
GO
GRANT SELECT ON  [dbo].[CMAC] TO [public]
GRANT INSERT ON  [dbo].[CMAC] TO [public]
GRANT DELETE ON  [dbo].[CMAC] TO [public]
GRANT UPDATE ON  [dbo].[CMAC] TO [public]
GO
