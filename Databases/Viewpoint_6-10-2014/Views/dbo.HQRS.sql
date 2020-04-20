SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQRS] as select a.* From bHQRS a

GO
GRANT SELECT ON  [dbo].[HQRS] TO [public]
GRANT INSERT ON  [dbo].[HQRS] TO [public]
GRANT DELETE ON  [dbo].[HQRS] TO [public]
GRANT UPDATE ON  [dbo].[HQRS] TO [public]
GRANT SELECT ON  [dbo].[HQRS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQRS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQRS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQRS] TO [Viewpoint]
GO
