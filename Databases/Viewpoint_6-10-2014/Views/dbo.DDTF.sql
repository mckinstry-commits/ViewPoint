SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[DDTF] as select a.* From vDDTF a

GO
GRANT SELECT ON  [dbo].[DDTF] TO [public]
GRANT INSERT ON  [dbo].[DDTF] TO [public]
GRANT DELETE ON  [dbo].[DDTF] TO [public]
GRANT UPDATE ON  [dbo].[DDTF] TO [public]
GRANT SELECT ON  [dbo].[DDTF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDTF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDTF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDTF] TO [Viewpoint]
GO
