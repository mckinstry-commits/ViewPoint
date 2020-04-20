SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSMH] as select a.* From bMSMH a

GO
GRANT SELECT ON  [dbo].[MSMH] TO [public]
GRANT INSERT ON  [dbo].[MSMH] TO [public]
GRANT DELETE ON  [dbo].[MSMH] TO [public]
GRANT UPDATE ON  [dbo].[MSMH] TO [public]
GRANT SELECT ON  [dbo].[MSMH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSMH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSMH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSMH] TO [Viewpoint]
GO
