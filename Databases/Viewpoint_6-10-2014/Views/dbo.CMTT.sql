SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMTT] as select a.* From bCMTT a
GO
GRANT SELECT ON  [dbo].[CMTT] TO [public]
GRANT INSERT ON  [dbo].[CMTT] TO [public]
GRANT DELETE ON  [dbo].[CMTT] TO [public]
GRANT UPDATE ON  [dbo].[CMTT] TO [public]
GRANT SELECT ON  [dbo].[CMTT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CMTT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CMTT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CMTT] TO [Viewpoint]
GO
