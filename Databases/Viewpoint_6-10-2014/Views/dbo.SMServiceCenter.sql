SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMServiceCenter] as select a.* From vSMServiceCenter a
GO
GRANT SELECT ON  [dbo].[SMServiceCenter] TO [public]
GRANT INSERT ON  [dbo].[SMServiceCenter] TO [public]
GRANT DELETE ON  [dbo].[SMServiceCenter] TO [public]
GRANT UPDATE ON  [dbo].[SMServiceCenter] TO [public]
GRANT SELECT ON  [dbo].[SMServiceCenter] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMServiceCenter] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMServiceCenter] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMServiceCenter] TO [Viewpoint]
GO
