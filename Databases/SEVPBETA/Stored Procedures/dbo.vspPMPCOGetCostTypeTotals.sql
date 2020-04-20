SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************/
CREATE PROCEDURE [dbo].[vspPMPCOGetCostTypeTotals]
/********************************
* Created By:	JG 03/21/2011 - TK-03172 - Created stored proc.
* Modified By:
*
* Called from the PM PCO to grab the company cost types and the PCOs totals per cost type.
*
* Input:
* @pmco		
* @project
* @pcotype
* @pco
*
* Output:
* resultset - Cost Types with descriptions and totals
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@pmco bCompany, @project bJob, @pcotype bPCOType, @pco bPCO, @errmsg varchar(512) output)
as
set nocount on

declare @rcode int
select @rcode = 0

DECLARE @ctable TABLE (CostType bJCCType NULL, [Description] bDesc NULL)

---- Null Check
IF @pmco IS NULL OR @project IS NULL OR @pcotype IS NULL OR @pco IS NULL
BEGIN
	SELECT @errmsg = 'Invalid parameter values.  Contact Viewpoint.', @rcode = 1
	GOTO vspexit
END


--- Process Data

-- Grab the CostType (10 total) and place into a temp table
INSERT INTO @ctable
SELECT ShowCostType1,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
AND JCCT.CostType = PMCO.ShowCostType1
WHERE PMCo = @pmco
AND PMCO.ShowCostType1 IS NOT NULL

INSERT INTO @ctable
SELECT ShowCostType2,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
	AND JCCT.CostType = PMCO.ShowCostType2
WHERE PMCo = @pmco
	AND PMCO.ShowCostType2 IS NOT NULL

INSERT INTO @ctable
SELECT ShowCostType3,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
	AND JCCT.CostType = PMCO.ShowCostType3
WHERE PMCo = @pmco
	AND PMCO.ShowCostType3 IS NOT NULL

INSERT INTO @ctable
SELECT ShowCostType4,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
	AND JCCT.CostType = PMCO.ShowCostType4
WHERE PMCo = @pmco
	AND PMCO.ShowCostType4 IS NOT NULL

INSERT INTO @ctable
SELECT ShowCostType5,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
	AND JCCT.CostType = PMCO.ShowCostType5
WHERE PMCo = @pmco
	AND PMCO.ShowCostType5 IS NOT NULL

INSERT INTO @ctable
SELECT ShowCostType6,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
	AND JCCT.CostType = PMCO.ShowCostType6
WHERE PMCo = @pmco
	AND PMCO.ShowCostType6 IS NOT NULL

INSERT INTO @ctable
SELECT ShowCostType7,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
	AND JCCT.CostType = PMCO.ShowCostType7
WHERE PMCo = @pmco
	AND PMCO.ShowCostType7 IS NOT NULL

INSERT INTO @ctable
SELECT ShowCostType8,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
	AND JCCT.CostType = PMCO.ShowCostType8
WHERE PMCo = @pmco
	AND PMCO.ShowCostType8 IS NOT NULL

INSERT INTO @ctable
SELECT ShowCostType9,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
	AND JCCT.CostType = PMCO.ShowCostType9
WHERE PMCo = @pmco
	AND PMCO.ShowCostType9 IS NOT NULL

INSERT INTO @ctable
SELECT ShowCostType10,JCCT.Description  
FROM PMCO 
LEFT JOIN JCCT ON JCCT.PhaseGroup = PMCO.PhaseGroup
	AND JCCT.CostType = PMCO.ShowCostType10
WHERE PMCo = @pmco
	AND PMCO.ShowCostType10 IS NOT NULL

-- Grab the total values for each cost type
SELECT CONVERT(VARCHAR,c.CostType) + '-' + c.[Description] AS Title, SUM(ISNULL(EstCost,0.0)) AS Cost 
FROM @ctable c
LEFT JOIN PMOL ON PMOL.CostType = c.CostType
	AND PMCo = @pmco
	AND Project = @project
	AND PCOType = @pcotype
	AND PCO = @pco
GROUP BY c.CostType, c.Description
ORDER BY c.CostType

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOGetCostTypeTotals] TO [public]
GO
