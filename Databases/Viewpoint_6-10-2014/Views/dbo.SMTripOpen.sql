SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMTripOpen]
as
SELECT t.*
, ISNULL(ti.FullName, 'Unassigned') 
+ ' - '
+ ISNULL(CONVERT(VARCHAR(11), t.ScheduledDate), 'Unscheduled')
+ CASE
	WHEN t.[Description] IS NOT NULL THEN ' - ' 
	ELSE '' END 
+ ISNULL(t.[Description], '') AS [NewDesc] 

FROM SMTrip t
LEFT JOIN dbo.SMTechnicianInfo ti
ON ti.SMCo = t.SMCo
AND ti.Technician = t.Technician
WHERE t.Status = 0


GO
GRANT SELECT ON  [dbo].[SMTripOpen] TO [public]
GRANT INSERT ON  [dbo].[SMTripOpen] TO [public]
GRANT DELETE ON  [dbo].[SMTripOpen] TO [public]
GRANT UPDATE ON  [dbo].[SMTripOpen] TO [public]
GRANT SELECT ON  [dbo].[SMTripOpen] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMTripOpen] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMTripOpen] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMTripOpen] TO [Viewpoint]
GO
