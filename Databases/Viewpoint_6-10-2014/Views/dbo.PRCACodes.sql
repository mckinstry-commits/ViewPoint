SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCACodes] as select * from bPRCACodes


GO
GRANT SELECT ON  [dbo].[PRCACodes] TO [public]
GRANT INSERT ON  [dbo].[PRCACodes] TO [public]
GRANT DELETE ON  [dbo].[PRCACodes] TO [public]
GRANT UPDATE ON  [dbo].[PRCACodes] TO [public]
GRANT SELECT ON  [dbo].[PRCACodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCACodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCACodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCACodes] TO [Viewpoint]
GO
