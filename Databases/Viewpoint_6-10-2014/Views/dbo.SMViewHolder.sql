SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMViewHolder]
AS
SELECT 1 AS ColumnHolder








GO
GRANT SELECT ON  [dbo].[SMViewHolder] TO [public]
GRANT INSERT ON  [dbo].[SMViewHolder] TO [public]
GRANT DELETE ON  [dbo].[SMViewHolder] TO [public]
GRANT UPDATE ON  [dbo].[SMViewHolder] TO [public]
GRANT SELECT ON  [dbo].[SMViewHolder] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMViewHolder] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMViewHolder] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMViewHolder] TO [Viewpoint]
GO
