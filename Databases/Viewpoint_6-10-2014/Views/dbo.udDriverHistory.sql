SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udDriverHistory] as select a.* From budDriverHistory a
GO
GRANT SELECT ON  [dbo].[udDriverHistory] TO [public]
GRANT INSERT ON  [dbo].[udDriverHistory] TO [public]
GRANT DELETE ON  [dbo].[udDriverHistory] TO [public]
GRANT UPDATE ON  [dbo].[udDriverHistory] TO [public]
GRANT SELECT ON  [dbo].[udDriverHistory] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udDriverHistory] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udDriverHistory] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udDriverHistory] TO [Viewpoint]
GO
