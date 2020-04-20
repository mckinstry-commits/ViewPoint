SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SMTripWithStatuses]
AS
SELECT *,
	CAST(CASE WHEN ScheduledDate IS NULL THEN 1 ELSE 0 END AS BIT) AS Unscheduled,
	CAST(CASE WHEN Technician IS NULL THEN 1 ELSE 0 END AS BIT) AS Unassigned
FROM dbo.SMTrip



GO
GRANT SELECT ON  [dbo].[SMTripWithStatuses] TO [public]
GRANT INSERT ON  [dbo].[SMTripWithStatuses] TO [public]
GRANT DELETE ON  [dbo].[SMTripWithStatuses] TO [public]
GRANT UPDATE ON  [dbo].[SMTripWithStatuses] TO [public]
GO
