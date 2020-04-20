SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[DocumentRoleType]
	AS SELECT [DocumentRoleTypeId], [RoleName], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM [Document].[vDocumentRoleType]
GO
GRANT SELECT ON  [Document].[DocumentRoleType] TO [public]
GRANT INSERT ON  [Document].[DocumentRoleType] TO [public]
GRANT DELETE ON  [Document].[DocumentRoleType] TO [public]
GRANT UPDATE ON  [Document].[DocumentRoleType] TO [public]
GO
