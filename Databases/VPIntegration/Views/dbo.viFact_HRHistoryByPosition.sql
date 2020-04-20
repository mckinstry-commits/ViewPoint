SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viFact_HRHistoryByPosition]

/**************************************************
 * Alterd: CWW 5/6/09
 * Modified:      
 * Usage:  Fact View returning HR Resource data to
 * determine employment history and reasons for employment
 * changes. 
 *
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 06/15/09 129902     C Wirtz		New
 *
 ********************************************************/

AS
--Extract specific HR Resource Employment information 
--bHREH.Type = 'H'  History
--bHREH.Type = 'N'  Reason
With HRResourceHistoryReason
as
(Select	 
	 bHREH.HRCo
	,bHREH.HRRef
	,bHREH.DateChanged
	,bHREH.Code
	,bHRCM.KeyID as CodeMasterID
	,bHREH.Type

From bHREH With (NoLock)
Inner Join bHRCM With (NoLock)
	ON bHREH.HRCo= bHRCM.HRCo and bHREH.Code = bHRCM.Code and bHREH.Type =bHRCM.Type and bHREH.Type  in ('H','N')
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHREH.HRCo  
),
 HRResourceByPositionCodeFirst
as
(Select	 
	 bHREH.HRCo
	,bHREH.HRRef
	,bHREH.DateChanged
	,bHREH.Code
	,bHREH.Type
	,bHRPC.KeyID as PositionCodeID

From bHREH With (NoLock)
Inner Join bHRPC With (NoLock)
	ON bHREH.HRCo = bHRPC.HRCo and bHREH.Code = bHRPC.PositionCode and bHREH.Type = 'P'
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHREH.HRCo  
),
 HRResourceByPositionCode   -- This step is need to get rid of duplicate rolls(Bad Data)
as
(select HRCo,HRRef,DateChanged,Code,Type,PositionCodeID,count(*) as PositionCodeCount
from HRResourceByPositionCodeFirst
group by HRCo,HRRef,DateChanged,Code,Type,PositionCodeID 
),
HRResourceHistoryPositionChanged
as
(Select	 
	 c.HRCo
	,c.HRRef
	,c.DateChanged
	,c.Code
	,c.CodeMasterID
	,c.Type
,(select max(p.DateChanged) from HRResourceByPositionCode p 
		where p.HRCo=c.HRCo and p.HRRef = c.HRRef and p.DateChanged <= c.DateChanged) as maxPositionChangedDate
--,(select isnull(max(p.DateChanged),c.DateChanged) from HRResourceByPositionCode p 
--		where p.HRCo=c.HRCo and p.HRRef = c.HRRef and p.DateChanged <= c.DateChanged) as maxPositionChangedDate

from HRResourceHistoryReason c
) ,
HistoryPositionFinal
as
(Select
	 c.HRCo
	,c.HRRef
	,c.DateChanged
	,c.Code
	,c.CodeMasterID
	,c.Type
	,c.maxPositionChangedDate
	,isnull(d.PositionCodeID,0) as PositionCodeID
from  HRResourceHistoryPositionChanged c left outer join HRResourceByPositionCode d
	ON c.HRCo =d.HRCo and c.HRRef = d.HRRef and c.maxPositionChangedDate = d.DateChanged
)
 
--select * from HRResourceHistoryPositionChanged
--select * from HistoryPositionFinal

select 
	 bHRCO.KeyID as HRCoID
	,isnull(bHRRM.KeyID,0) as HRRefID
	,isnull(bPRCO.KeyID,0) as PRCoID
	,isnull(bPRGR.KeyID,0) as PRGroupID
--	,HRResourceEmploymentStatus.DateChanged
    ,Datediff(dd,'1/1/1950',isnull(HistoryPositionFinal.DateChanged,'1/1/1950')) as ResourceDateChangedID
	,HistoryPositionFinal.CodeMasterID
	,HistoryPositionFinal.PositionCodeID
	,HistoryByPositionCount = 1
from HistoryPositionFinal
Inner Join bHRCO With (NoLock)
	ON HistoryPositionFinal.HRCo = bHRCO.HRCo 
left outer join bHRRM With (NoLOck)
	ON HistoryPositionFinal.HRCo = bHRRM.HRCo and HistoryPositionFinal.HRRef = bHRRM.HRRef 
left outer Join bPRCO With (NoLock)
	ON bHRRM.PRCo= bPRCO.PRCo
Left Outer Join bPRGR With (NoLock)
	ON bHRRM.PRCo= bPRGR.PRCo and bHRRM.PRGroup = bPRGR.PRGroup

GO
GRANT SELECT ON  [dbo].[viFact_HRHistoryByPosition] TO [public]
GRANT INSERT ON  [dbo].[viFact_HRHistoryByPosition] TO [public]
GRANT DELETE ON  [dbo].[viFact_HRHistoryByPosition] TO [public]
GRANT UPDATE ON  [dbo].[viFact_HRHistoryByPosition] TO [public]
GO
