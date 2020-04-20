SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQNT] as select a.* From bHQNT a

GO
GRANT SELECT ON  [dbo].[HQNT] TO [public]
GRANT INSERT ON  [dbo].[HQNT] TO [public]
GRANT DELETE ON  [dbo].[HQNT] TO [public]
GRANT UPDATE ON  [dbo].[HQNT] TO [public]
GO
