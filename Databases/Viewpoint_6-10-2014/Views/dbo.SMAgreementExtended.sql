SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementExtended]
AS
	--This view is used in DDFH as the view for SMAgreement. It needs to remain an updatable view
	--and therefore cannot have any joins.
	WITH AgreementOriginalRevisionCTE
	AS
	(
		SELECT SMAgreementID, SMCo, Agreement, Revision, Revision AS OriginalRevision
		FROM dbo.SMAgreement
		WHERE PreviousRevision IS NULL
		UNION ALL
		SELECT SMAgreement.SMAgreementID, SMAgreement.SMCo, SMAgreement.Agreement, SMAgreement.Revision, CASE WHEN SMAgreement.RevisionType = 2 /* Type is for amendments*/ THEN AgreementOriginalRevisionCTE.OriginalRevision ELSE SMAgreement.Revision END
		FROM dbo.SMAgreement
			INNER JOIN AgreementOriginalRevisionCTE ON SMAgreement.SMCo = AgreementOriginalRevisionCTE.SMCo AND SMAgreement.Agreement = AgreementOriginalRevisionCTE.Agreement AND SMAgreement.PreviousRevision = AgreementOriginalRevisionCTE.Revision
	),
	AgreementExtendedCTE
	AS
	(
		SELECT *,
			ISNULL(DateTerminated, ExpirationDate) EndDate,
			MAX(CASE 
					WHEN DateActivated IS NOT NULL
					AND
					dbo.vfDateOnly()
						BETWEEN
							EffectiveDate
						AND
							CASE
								WHEN DateTerminated IS NOT NULL THEN DateTerminated
								WHEN NonExpiring = 'Y' THEN dbo.vfDateOnly()
								ELSE ExpirationDate
							END
					THEN Revision
				END) OVER (PARTITION BY SMCo, Agreement) CurrentActiveRevision,
			CASE
				-- Quote 0
				WHEN DateActivated IS NULL AND
					 DateCancelled IS NULL THEN 0
				-- Cancelled 1
				WHEN DateActivated IS NULL AND
					 DateCancelled IS NOT NULL THEN 1
				-- Active 2
				WHEN DateActivated IS NOT NULL AND
					 DateTerminated IS NULL AND
					 (dbo.vfDateOnly() <= ExpirationDate OR ExpirationDate IS NULL) THEN 2
				-- Expired 3
				WHEN DateActivated IS NOT NULL AND
					 DateTerminated IS NULL AND
					 dbo.vfDateOnly() > ExpirationDate THEN 3
				-- Terminated 4
				WHEN DateActivated IS NOT NULL AND
					 DateTerminated IS NOT NULL THEN 4
			END RevisionStatus
		FROM dbo.SMAgreement -- Leave a space after the view name.
	)
	SELECT *,
		ISNULL(
			--Return the current active revision if possible
			CurrentActiveRevision,
			--Otherwise return the greatest revision
			MAX(Revision) OVER (PARTITION BY SMCo, Agreement)
		) CurrentRevision,
		(SELECT OriginalRevision FROM AgreementOriginalRevisionCTE WHERE AgreementExtendedCTE.SMAgreementID = SMAgreementID) OriginalRevision,
		CASE 
			WHEN CurrentActiveRevision IS NULL THEN 'I' /* I is Inactive*/ 
			ELSE 'A' /* A is Active*/ 
		END AgreementStatus
	FROM AgreementExtendedCTE
GO
GRANT SELECT ON  [dbo].[SMAgreementExtended] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementExtended] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementExtended] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementExtended] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementExtended] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementExtended] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementExtended] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementExtended] TO [Viewpoint]
GO
