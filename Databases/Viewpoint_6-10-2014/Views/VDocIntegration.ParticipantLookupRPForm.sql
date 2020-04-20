SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [VDocIntegration].ParticipantLookupRPForm
	AS SELECT a.* FROM [VDocIntegration].vParticipantLookupRPForm AS a
GO
GRANT SELECT ON  [VDocIntegration].[ParticipantLookupRPForm] TO [public]
GRANT INSERT ON  [VDocIntegration].[ParticipantLookupRPForm] TO [public]
GRANT DELETE ON  [VDocIntegration].[ParticipantLookupRPForm] TO [public]
GRANT UPDATE ON  [VDocIntegration].[ParticipantLookupRPForm] TO [public]
GO
