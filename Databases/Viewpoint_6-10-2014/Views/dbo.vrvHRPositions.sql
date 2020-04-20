SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*  
Maintenance Log
Desciption
This view returns HR positions.


Note: The data in the "Type" field in view HRPC is not valid functionality.
When the positions are in relation to view HREH(Employment History) the only Type
is "P".  In Table HRCM the Type "P" is not a valid type.

Date		Programmer		Issue#		Description
6/4/2007	Charles Wirtz	124413		New

*/
CREATE  view [dbo].[vrvHRPositions] 
AS
select 
	 HRPC.HRCo As HRCo
	,HRPC.PositionCode As Code
	,'P' As Type 
	,HRPC.JobTitle AS Description
from HRPC with (nolock)

Union all


select 
	 HRCo
	,Code
	,Type
	,Description
 from HRCM with (nolock)

GO
GRANT SELECT ON  [dbo].[vrvHRPositions] TO [public]
GRANT INSERT ON  [dbo].[vrvHRPositions] TO [public]
GRANT DELETE ON  [dbo].[vrvHRPositions] TO [public]
GRANT UPDATE ON  [dbo].[vrvHRPositions] TO [public]
GRANT SELECT ON  [dbo].[vrvHRPositions] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvHRPositions] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvHRPositions] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvHRPositions] TO [Viewpoint]
GO
