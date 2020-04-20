SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQCX] as select a.* From bHQCX a

GO
GRANT SELECT ON  [dbo].[HQCX] TO [public]
GRANT INSERT ON  [dbo].[HQCX] TO [public]
GRANT DELETE ON  [dbo].[HQCX] TO [public]
GRANT UPDATE ON  [dbo].[HQCX] TO [public]
GRANT SELECT ON  [dbo].[HQCX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQCX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQCX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQCX] TO [Viewpoint]
GO
