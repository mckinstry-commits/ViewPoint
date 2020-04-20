SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMTB] as select a.* From bCMTB a

GO
GRANT SELECT ON  [dbo].[CMTB] TO [public]
GRANT INSERT ON  [dbo].[CMTB] TO [public]
GRANT DELETE ON  [dbo].[CMTB] TO [public]
GRANT UPDATE ON  [dbo].[CMTB] TO [public]
GO
