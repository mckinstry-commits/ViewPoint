SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMPCOAddPMMFRecords]
   /***********************************************************
    * Created By:		JG	01/10/2012 - TK-11624
    * Code Reviewed By:	
    * Modified By:		
    * Purpose:	Generate the PMMF records for the given PCO.
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
-- Get the max sequence for the PMMF
SELECT @Max_Seq = ISNULL(MAX(Seq),0) FROM dbo.bPMMF WHERE PMCo=@PMCo AND Project=@Project

-- Insert records into PMMF (Copied from PMOLi for inserting PMMF records)
INSERT dbo.bPMMF (	PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
					PhaseGroup, Phase, CostType, VendorGroup, MaterialOption, POCo, RecvYN, UM,
					Units, UnitCost, ECM, Amount, MaterialGroup, MaterialCode, SendFlag, 
					Vendor, PO, POItem, MtlDescription)
SELECT	@PMCo, @Project, @Max_Seq + ROW_NUMBER() OVER(ORDER BY PMOL.KeyID), 'C', @PCOType, @PCO, PMOL.PCOItem, PMOL.ACO, PMOL.ACOItem, PMOL.PhaseGroup,
		PMOL.Phase, PMOL.CostType, PMOL.VendorGroup, 'P', PMCO.APCo, 'N',
		ISNULL(PurchaseUM, 'LS'),
		ISNULL(PurchaseUnits,0),
		ISNULL(PurchaseUnitCost,0),
		PMOL.ECM,
		ISNULL(PurchaseAmt,0),
		HQCO.MatlGroup, PMOL.MaterialCode, 'Y', PMOL.Vendor,
		PMOL.PO, PMOL.POSLItem,
		CASE WHEN ISNULL(PMCO.MatlPhaseDesc, 'N') = 'Y' THEN p.[Description] ELSE NULL END
	
FROM PMOL
	JOIN dbo.PMCO
		ON PMCO.PMCo = PMOL.PMCo
	JOIN dbo.HQCO
		ON HQCO.HQCo = PMOL.PMCo
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
-- Only get PO CostTypes from PMCO
AND PMOL.CostType IN (PMCO.MtlCostType, PMCO.MatlCostType2)
AND NOT EXISTS	(	SELECT 1 
					FROM dbo.PMMF 
					WHERE PMCo = @PMCo
					AND Project = @Project
					AND PCOType = @PCOType
					AND PCO = @PCO
					AND PCOItem = PMOL.PCOItem
				)
					
vspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOAddPMMFRecords] TO [public]
GO
