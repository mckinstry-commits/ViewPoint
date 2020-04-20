SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMWENotes] as select a.* From bIMWENotes a
GO
GRANT SELECT ON  [dbo].[IMWENotes] TO [public]
GRANT INSERT ON  [dbo].[IMWENotes] TO [public]
GRANT DELETE ON  [dbo].[IMWENotes] TO [public]
GRANT UPDATE ON  [dbo].[IMWENotes] TO [public]
GRANT SELECT ON  [dbo].[IMWENotes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMWENotes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMWENotes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMWENotes] TO [Viewpoint]
GO
