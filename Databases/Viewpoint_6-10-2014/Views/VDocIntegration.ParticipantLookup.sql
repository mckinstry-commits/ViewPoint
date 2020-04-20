SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [VDocIntegration].[ParticipantLookup]
	AS SELECT a.* FROM [VDocIntegration].[vParticipantLookup] AS a
GO
GRANT SELECT ON  [VDocIntegration].[ParticipantLookup] TO [public]
GRANT INSERT ON  [VDocIntegration].[ParticipantLookup] TO [public]
GRANT DELETE ON  [VDocIntegration].[ParticipantLookup] TO [public]
GRANT UPDATE ON  [VDocIntegration].[ParticipantLookup] TO [public]
GO
