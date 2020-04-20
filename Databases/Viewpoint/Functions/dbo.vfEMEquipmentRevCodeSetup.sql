SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/9/11
-- Description:	Retrieves information for a piece of equipment based on the revenue code.
-- =============================================
CREATE FUNCTION [dbo].[vfEMEquipmentRevCodeSetup]
(	
	@EMCo bCompany, @Equipment bEquip, @EMGroup bGroup, @RevCode bRevCode
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
			bEMEM.Department,
			bEMEM.Category,
			bEMEM.HourReading,
			bEMRC.Basis,
			CASE WHEN bEMRC.Basis = 'H' THEN bEMRC.TimeUM ELSE bEMCO.HoursUM END AS TimeUM,
			CASE WHEN bEMRC.Basis = 'H' THEN bEMRC.HrsPerTimeUM ELSE 0 END AS HourPerTimeUM,
			CASE WHEN bEMRR.KeyID IS NULL THEN 'N' ELSE 'Y' END AS CategorySetupExists,
			CASE WHEN bEMRH.KeyID IS NULL THEN 'N' ELSE 'Y' END AS EquipmentSetupExists,
			--The rest of the columns are dependent on having a valid setup either in the category or equipment setup			
			CASE WHEN bEMRH.ORideRate = 'Y' THEN bEMRH.Rate ELSE bEMRR.Rate END AS Rate,
			COALESCE(bEMRH.PostWorkUnits, bEMRR.PostWorkUnits) AS PostWorkUnits,
			CASE 
				WHEN bEMRH.PostWorkUnits = 'Y' THEN bEMRH.WorkUM 
				WHEN bEMRH.PostWorkUnits = 'N' THEN NULL 
				WHEN bEMRR.PostWorkUnits = 'Y' THEN bEMRR.WorkUM 
				WHEN bEMRR.PostWorkUnits = 'N' THEN NULL 
			END AS WorkUM,
			COALESCE(bEMRH.AllowPostOride, bEMRR.AllowPostOride) AS AllowPostOverride,
			COALESCE(bEMRH.UpdtHrMeter, bEMRR.UpdtHrMeter) AS UpdateHourMeter
		FROM dbo.bEMEM
			CROSS JOIN dbo.bEMRC
			INNER JOIN dbo.bEMCO ON bEMEM.EMCo = bEMCO.EMCo
			LEFT JOIN dbo.bEMRR ON bEMRC.EMGroup = bEMRR.EMGroup AND bEMRC.RevCode = bEMRR.RevCode AND bEMCO.EMCo = bEMRR.EMCo AND bEMEM.Category = bEMRR.Category
			LEFT JOIN dbo.bEMRH ON bEMRC.EMGroup = bEMRH.EMGroup AND bEMRC.RevCode = bEMRH.RevCode AND bEMCO.EMCo = bEMRH.EMCo AND bEMEM.Equipment = bEMRH.Equipment
		WHERE bEMEM.EMCo = @EMCo AND bEMEM.Equipment = @Equipment AND bEMRC.EMGroup = @EMGroup AND bEMRC.RevCode = @RevCode
)

GO
GRANT SELECT ON  [dbo].[vfEMEquipmentRevCodeSetup] TO [public]
GO
