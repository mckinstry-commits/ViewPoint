SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDQueryableColumns] as select * from vDDQueryableColumns

GO
GRANT SELECT ON  [dbo].[DDQueryableColumns] TO [public]
GRANT INSERT ON  [dbo].[DDQueryableColumns] TO [public]
GRANT DELETE ON  [dbo].[DDQueryableColumns] TO [public]
GRANT UPDATE ON  [dbo].[DDQueryableColumns] TO [public]
GO
