SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMJT] as select a.* From bEMJT a
GO
GRANT SELECT ON  [dbo].[EMJT] TO [public]
GRANT INSERT ON  [dbo].[EMJT] TO [public]
GRANT DELETE ON  [dbo].[EMJT] TO [public]
GRANT UPDATE ON  [dbo].[EMJT] TO [public]
GRANT SELECT ON  [dbo].[EMJT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMJT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMJT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMJT] TO [Viewpoint]
GO
