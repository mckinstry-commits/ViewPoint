SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		AJW
-- Create date: 11/28/12
-- Description:	Returns column names in PMSL to SLIT equivelent
-- =============================================
CREATE FUNCTION [dbo].[vfPMSLtoSLIT](@pmslcolumns varchar(max))
RETURNS varchar(max)
AS
BEGIN
  	return (	    
	    REPLACE(
	    REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
			@pmslcolumns,'.SLItemType', '.ItemType')
			,'.SLItemDescription', '.Description')
			,'.Units', '.OrigUnits')
			,'.UnitCost', '.OrigUnitCost')
			,'.Amount','.OrigCost')
			,'.PMCo','.JCCo')
			,'.Project','.Job')
			,'.SLAddon', '.Addon')
			,'.SLAddonPct', '.AddonPct')
			,'.CostType', '.JCCType')
			,'.WCRetgPct', '.WCRetPct')
			,'.SMRetgPct', '.SMRetPct')
			,'.SubCO','''''')
			,'.SLItemDescription', '.Description')
			,'PMSL','SLIT')
	)

END;
GO
GRANT EXECUTE ON  [dbo].[vfPMSLtoSLIT] TO [public]
GO
