SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viDim_EMEquipment] AS

/**************************************************
 * ALTERED:		TMS 2009-06-03
 * Modified:	HH 2010-11-04	#135047	Join bEMCO for company security
 *
 * Usage:  Dimension View for EM Equipment 
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	Equipment.KeyID AS EquipmentID
,	bEMCO.KeyID AS EMCoID	
,	Equipment.Equipment
,	Equipment.Description		AS EquipmentDescription
,	isnull(Equipment.Equipment,'') + '  ' + isnull(Equipment.Description,'') AS EquipmentAndDescription
,	Case When Equipment.Type='E' then 'Equipment' when Equipment.Type='C' then 'Component' end as Type
,	Case When Equipment.Status='A' then 'Active'
		 When Equipment.Status='I' then 'Inactive'
		 When Equipment.Status='D' then 'Down'
	End as EquipmentStatus
,	Job.KeyID as CurrentJobID
,	isnull(Job.Job, '') +' '+ isnull(Job.Description, '') as CurrentJobAndDescription
,	Case when Equipment.OwnershipStatus='O' then 'Owned'
		 when Equipment.OwnershipStatus='L' then 'Leased'
		 when Equipment.OwnershipStatus='R' then 'Rented'
		 when Equipment.OwnershipStatus='C' then 'Customer'
	End as OwnershipStatus,
isnull(Equipment.HourReading, 0) as 'HourReading',
isnull(Equipment.OdoReading,0) as 'OdoReading',
isnull(Equipment.FuelUsed, 0) as 'FuelUsed',
Equipment.HourDate,
Equipment.OdoDate,
Equipment.LastFuelDate
FROM bEMEM Equipment With (NoLock)
left JOIN bJCJM Job With (NoLock)
		ON	Job.JCCo=Equipment.JCCo
		AND	Job.Job=Equipment.Job
Inner Join bEMCO With (NoLock) on bEMCO.EMCo = Equipment.EMCo
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=Equipment.EMCo

--WHERE 
--	Type = 'E'

UNION ALL 

-- Unassigned record
SELECT 
	0		,null, null	,'Unassigned'
	,null	
	,null
	,null
	,0
	,null
	,null
	,null
	,null
	,null
	,null
	,null
	,null


GO
GRANT SELECT ON  [dbo].[viDim_EMEquipment] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMEquipment] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMEquipment] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMEquipment] TO [public]
GO
