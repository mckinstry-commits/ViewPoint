SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[DocumentRoleType]
	AS SELECT [DocumentRoleTypeId], [RoleName], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM [Document].[DocumentRoleType]
GO
