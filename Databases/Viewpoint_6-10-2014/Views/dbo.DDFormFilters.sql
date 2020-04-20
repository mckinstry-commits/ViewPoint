SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DDFormFilters] AS
SELECT * FROM vDDFormFilters;


GO
GRANT SELECT ON  [dbo].[DDFormFilters] TO [public]
GRANT INSERT ON  [dbo].[DDFormFilters] TO [public]
GRANT DELETE ON  [dbo].[DDFormFilters] TO [public]
GRANT UPDATE ON  [dbo].[DDFormFilters] TO [public]
GRANT SELECT ON  [dbo].[DDFormFilters] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFormFilters] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFormFilters] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFormFilters] TO [Viewpoint]
GO
