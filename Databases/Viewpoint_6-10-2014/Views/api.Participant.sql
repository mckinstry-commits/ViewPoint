SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[Participant]
	AS SELECT	p.[ParticipantId], 
				p.[FirstName], 
				p.[LastName], 
				p.[Email], 
				p.[DisplayName], 
				p.[Title], 
				p.[CompanyName], 
				p.[CompanyNumber],
				p.[DocumentId], 
				p.[Status], 
				--syncing to the old participant table to prevent code changes
				p.[DocumentRoleTypeId] AS RoleId, 
				rt.[RoleName],
				p.[CreatedByUser], 
				p.[DBCreatedDate], 
				p.[UpdatedByUser], 
				p.[DBUpdatedDate], 
				p.[Version]
		FROM Document.Participant p
			JOIN Document.DocumentRoleType rt ON rt.DocumentRoleTypeId = p.DocumentRoleTypeId
GO
