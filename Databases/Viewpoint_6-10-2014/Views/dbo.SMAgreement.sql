SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreement]
AS
SELECT     *, 
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
	     (dbo.vfDateOnly() < ExpirationDate OR ExpirationDate IS NULL) THEN 2	
	-- Expired 3
	WHEN DateActivated IS NOT NULL AND
		 DateTerminated IS NULL AND 
		 ExpirationDate IS NOT NULL AND 
		 dbo.vfDateOnly() >= ExpirationDate THEN 3
	-- Terminated 4
	WHEN DateActivated IS NOT NULL AND 
		 DateTerminated IS NOT NULL THEN 4 
END AS [Status]
FROM dbo.vSMAgreement


GO
GRANT SELECT ON  [dbo].[SMAgreement] TO [public]
GRANT INSERT ON  [dbo].[SMAgreement] TO [public]
GRANT DELETE ON  [dbo].[SMAgreement] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreement] TO [public]
GRANT SELECT ON  [dbo].[SMAgreement] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreement] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreement] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreement] TO [Viewpoint]
GO
