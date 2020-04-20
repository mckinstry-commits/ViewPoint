SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INXI] as select a.* From bINXI a

GO
GRANT SELECT ON  [dbo].[INXI] TO [public]
GRANT INSERT ON  [dbo].[INXI] TO [public]
GRANT DELETE ON  [dbo].[INXI] TO [public]
GRANT UPDATE ON  [dbo].[INXI] TO [public]
GO
