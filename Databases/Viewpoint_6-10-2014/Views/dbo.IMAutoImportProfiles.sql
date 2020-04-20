SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE View [dbo].[IMAutoImportProfiles] as

select * from vIMAutoImportProfiles


GO
GRANT SELECT ON  [dbo].[IMAutoImportProfiles] TO [public]
GRANT INSERT ON  [dbo].[IMAutoImportProfiles] TO [public]
GRANT DELETE ON  [dbo].[IMAutoImportProfiles] TO [public]
GRANT UPDATE ON  [dbo].[IMAutoImportProfiles] TO [public]
GRANT SELECT ON  [dbo].[IMAutoImportProfiles] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMAutoImportProfiles] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMAutoImportProfiles] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMAutoImportProfiles] TO [Viewpoint]
GO
