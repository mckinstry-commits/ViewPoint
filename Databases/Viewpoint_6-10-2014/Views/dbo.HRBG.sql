SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRBG] as select a.* From bHRBG a
GO
GRANT SELECT ON  [dbo].[HRBG] TO [public]
GRANT INSERT ON  [dbo].[HRBG] TO [public]
GRANT DELETE ON  [dbo].[HRBG] TO [public]
GRANT UPDATE ON  [dbo].[HRBG] TO [public]
GRANT SELECT ON  [dbo].[HRBG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRBG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRBG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRBG] TO [Viewpoint]
GO
