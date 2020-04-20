SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMPCOAddPMSLRecords]
   /***********************************************************
    * Created By:		JG	01/10/2012 - TK-11624
    * Code Reviewed By:	
    * Modified By:		
    * Purpose:	Generate the PMSL records for the given PCO.
    *****************************************************/
(@PMCo dbo.bCompany, @Project dbo.bJob, @PCOType dbo.bPCOType, @PCO dbo.bPCO, @msg varchar(255) output)
AS
SET NOCOUNT ON	

DECLARE @Max_Seq INT,
@dfltwcpct dbo.bPct, @PhaseDesc dbo.bItemDesc, @rcode INT

SELECT @rcode = 0, @msg = ''

--------------
--VALIDATION--
--------------
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @PCOType is null
begin
	select @msg = 'Missing PCO Type.', @rcode = 1
	goto vspexit
end

if @PCO is null
begin
	select @msg = 'Missing PCO.', @rcode = 1
	goto vspexit
END

--------------------
--RECORD INSERTION--
--------------------
-- Get the max sequence for the PMSL
SELECT @Max_Seq = ISNULL(MAX(Seq),0) FROM dbo.bPMSL WHERE PMCo=@PMCo AND Project=@Project

-- Insert records into PMSL (Copied from PMOLi for inserting PMSL records)
INSERT dbo.bPMSL (	PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
					PhaseGroup, Phase, CostType, SLCo, SLItemType, Units, UM, UnitCost, Amount,
					SendFlag, WCRetgPct, SMRetgPct, VendorGroup, Vendor, SL, SLItem, SLItemDescription)
					
SELECT	@PMCo, @Project, @Max_Seq + ROW_NUMBER() OVER(ORDER BY PMOL.KeyID), 'C', @PCOType, @PCO, PMOL.PCOItem, PMOL.ACO, PMOL.ACOItem, PMOL.PhaseGroup,
		PMOL.Phase, PMOL.CostType, PMCO.APCo, 2,
		ISNULL(PurchaseUnits,0),
		ISNULL(PurchaseUM, 'LS'), 
		ISNULL(PurchaseUnitCost,0),
		ISNULL(PurchaseAmt,0),
		'Y', ISNULL(i.RetainPCT,0), ISNULL(i.RetainPCT,0), PMOL.VendorGroup, PMOL.Vendor, Subcontract, POSLItem,
		CASE WHEN ISNULL(PMCO.PhaseDescYN, 'N') = 'Y' THEN p.[Description] ELSE NULL END
	
FROM dbo.PMOL
	JOIN dbo.PMCO
		ON PMCO.PMCo = PMOL.PMCo
	JOIN dbo.JCJP p
		ON p.JCCo=@PMCo 
		AND p.Job=@Project 
		AND p.PhaseGroup=PMOL.PhaseGroup 
		AND p.Phase=PMOL.Phase
	JOIN dbo.JCCI i 
		ON i.JCCo = p.JCCo 
		AND i.[Contract] = p.[Contract]
		AND i.Item = p.Item
WHERE PMOL.PMCo = @PMCo
AND PMOL.Project = @Project
AND PMOL.PCOType = @PCOType
AND PMOL.PCO = @PCO
-- Only get SL CostTypes from PMCO
AND PMOL.CostType IN (PMCO.SLCostType, PMCO.SLCostType2)
AND NOT EXISTS	(	SELECT 1 
					FROM dbo.PMSL 
					WHERE PMCo = @PMCo
					AND Project = @Project
					AND PCOType = @PCOType
					AND PCO = @PCO
					AND PCOItem = PMOL.PCOItem
				)
					
vspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOAddPMSLRecords] TO [public]
GO
