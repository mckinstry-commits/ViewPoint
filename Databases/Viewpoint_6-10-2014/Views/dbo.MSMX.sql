SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSMX] as select a.* From bMSMX a
GO
GRANT SELECT ON  [dbo].[MSMX] TO [public]
GRANT INSERT ON  [dbo].[MSMX] TO [public]
GRANT DELETE ON  [dbo].[MSMX] TO [public]
GRANT UPDATE ON  [dbo].[MSMX] TO [public]
GRANT SELECT ON  [dbo].[MSMX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSMX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSMX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSMX] TO [Viewpoint]
GO
