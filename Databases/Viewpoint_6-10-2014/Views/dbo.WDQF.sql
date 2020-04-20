SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDQF] as select a.* From bWDQF a

GO
GRANT SELECT ON  [dbo].[WDQF] TO [public]
GRANT INSERT ON  [dbo].[WDQF] TO [public]
GRANT DELETE ON  [dbo].[WDQF] TO [public]
GRANT UPDATE ON  [dbo].[WDQF] TO [public]
GRANT SELECT ON  [dbo].[WDQF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WDQF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WDQF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WDQF] TO [Viewpoint]
GO
