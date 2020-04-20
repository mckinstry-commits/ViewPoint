SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRCL] as select a.* From bHRCL a

GO
GRANT SELECT ON  [dbo].[HRCL] TO [public]
GRANT INSERT ON  [dbo].[HRCL] TO [public]
GRANT DELETE ON  [dbo].[HRCL] TO [public]
GRANT UPDATE ON  [dbo].[HRCL] TO [public]
GO
