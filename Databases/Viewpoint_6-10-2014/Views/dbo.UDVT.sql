SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[UDVT] as select a.* From bUDVT a

GO
GRANT SELECT ON  [dbo].[UDVT] TO [public]
GRANT INSERT ON  [dbo].[UDVT] TO [public]
GRANT DELETE ON  [dbo].[UDVT] TO [public]
GRANT UPDATE ON  [dbo].[UDVT] TO [public]
GRANT SELECT ON  [dbo].[UDVT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[UDVT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[UDVT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[UDVT] TO [Viewpoint]
GO
