SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSIH] as select a.* From bMSIH a
GO
GRANT SELECT ON  [dbo].[MSIH] TO [public]
GRANT INSERT ON  [dbo].[MSIH] TO [public]
GRANT DELETE ON  [dbo].[MSIH] TO [public]
GRANT UPDATE ON  [dbo].[MSIH] TO [public]
GRANT SELECT ON  [dbo].[MSIH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSIH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSIH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSIH] TO [Viewpoint]
GO
