SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSQD] as select a.* From bMSQD a
GO
GRANT SELECT ON  [dbo].[MSQD] TO [public]
GRANT INSERT ON  [dbo].[MSQD] TO [public]
GRANT DELETE ON  [dbo].[MSQD] TO [public]
GRANT UPDATE ON  [dbo].[MSQD] TO [public]
GRANT SELECT ON  [dbo].[MSQD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSQD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSQD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSQD] TO [Viewpoint]
GO
