SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSTT] as select a.* From bMSTT a
GO
GRANT SELECT ON  [dbo].[MSTT] TO [public]
GRANT INSERT ON  [dbo].[MSTT] TO [public]
GRANT DELETE ON  [dbo].[MSTT] TO [public]
GRANT UPDATE ON  [dbo].[MSTT] TO [public]
GRANT SELECT ON  [dbo].[MSTT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSTT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSTT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSTT] TO [Viewpoint]
GO
