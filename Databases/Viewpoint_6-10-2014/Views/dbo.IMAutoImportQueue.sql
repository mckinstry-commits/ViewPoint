SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE View [dbo].[IMAutoImportQueue] as

select * from vIMAutoImportQueue


GO
GRANT SELECT ON  [dbo].[IMAutoImportQueue] TO [public]
GRANT INSERT ON  [dbo].[IMAutoImportQueue] TO [public]
GRANT DELETE ON  [dbo].[IMAutoImportQueue] TO [public]
GRANT UPDATE ON  [dbo].[IMAutoImportQueue] TO [public]
GRANT SELECT ON  [dbo].[IMAutoImportQueue] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMAutoImportQueue] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMAutoImportQueue] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMAutoImportQueue] TO [Viewpoint]
GO
