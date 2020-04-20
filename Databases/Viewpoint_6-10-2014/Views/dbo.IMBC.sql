SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMBC] as select a.* From bIMBC a
GO
GRANT SELECT ON  [dbo].[IMBC] TO [public]
GRANT INSERT ON  [dbo].[IMBC] TO [public]
GRANT DELETE ON  [dbo].[IMBC] TO [public]
GRANT UPDATE ON  [dbo].[IMBC] TO [public]
GRANT SELECT ON  [dbo].[IMBC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMBC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMBC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMBC] TO [Viewpoint]
GO
