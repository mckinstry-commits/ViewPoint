SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[HQOrganization]
	AS SELECT [OrganizationID], [OrganizationName], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM dbo.HQOrganization
GO
