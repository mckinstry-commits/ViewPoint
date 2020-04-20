SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMED] as select a.* From bEMED a

GO
GRANT SELECT ON  [dbo].[EMED] TO [public]
GRANT INSERT ON  [dbo].[EMED] TO [public]
GRANT DELETE ON  [dbo].[EMED] TO [public]
GRANT UPDATE ON  [dbo].[EMED] TO [public]
GO
