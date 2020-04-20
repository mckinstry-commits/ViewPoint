SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].Participant
AS

SELECT * FROM [Document].[vParticipant]
GO
GRANT SELECT ON  [Document].[Participant] TO [public]
GRANT INSERT ON  [Document].[Participant] TO [public]
GRANT DELETE ON  [Document].[Participant] TO [public]
GRANT UPDATE ON  [Document].[Participant] TO [public]
GO
