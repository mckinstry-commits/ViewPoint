SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/7/2014
-- Description:	Function to return the multi-level phase code structure.
-- =============================================
CREATE FUNCTION [dbo].[mckfnPhaseHeirarchy] 
(	
	-- Add the parameters for the function here
	 @Phase bPhase
)
RETURNS TABLE 
AS
RETURN 
(	
	-- Add the SELECT statement with parameter references here
	WITH Phases AS(
	--ANCHOR
	SELECT 1 AS level, d1.Phase, d1.Description, d1.Parent, d1.ExtDesc 
		FROM udPhaseDIV d1
	--	LEFT OUTER JOIN Phases p2 ON d1.Parent = p2.Phase
	WHERE d1.Parent IS NULL OR d1.Phase = d1.Parent
	UNION ALL
	--Everything else
	SELECT level + 1, p.Phase, p.Description, p.Parent, p.ExtDesc 
		--, CASE WHEN p.Parent IN (SELECT div.Phase FROM udPhaseDIV div WHERE div.Parent IS NULL OR div.Phase = div.Parent) THEN 2 ELSE 3 END AS LVL
		FROM udPhaseDIV p
		INNER JOIN Phases p2 ON p.Parent = p2.Phase
	--WHERE p.Parent IS NOT NULL AND p.Parent <> p.Phase 
	)
	SELECT p3.Phase, p3.Description, p3.ExtDesc, p3.Parent, p3.level 
	FROM Phases p3
	WHERE p3.Phase = @Phase 
	OR p3.Parent = @Phase 
	OR @Phase = ''
	--ORDER BY p3.Parent, p3.Phase
)
GO
