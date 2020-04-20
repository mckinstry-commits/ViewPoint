SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvHQRolesListByMember]    
    
  
/***********************************************************************        
Author:     
Scott Alvey  
       
Create date:     
04/26/2012  

Originating V1 reference:   
B-09520 POWF - Reports - HQ Roles List  
        
Usage:    
Returns to a list report the setup details for each role in HQ Roles, including  
roles, descriptions, types and subtypes, members, standard limits and override limits  
  
Development Notes:  
Two things that really stand out here are:  
- The view looks to DDCI to get the combo box display value for HQRoleLimt.Type. This is  
 done so that in the future if more values are added to the combo box the view, and thus  
 the report, will automatically pick up the new values with out any modification to  
 the report. This is a bit tricky as there is really no direct link between HQRoleLimit and   
 DDCI so we have to filter on DDCI.DatabaseValue. To make this work we need to only look to   
 DDCI records with a ComboType value HQRoleLimitType. Unfortunately there is also a ComboType  
 value of PMDocCategory that also has a common DatabaseValue when compared to HQRoleLimit so we  
 need to include the DDCI.ComboType value of HQRoleLimitType in the where clause. Typically we would  
 just do a 'where ComboType = HQRoleLimitType' but there are instances where where HQRoleLimit.Type  
 may be null, and since we are using HQRoleLimit.Type in the join between HQRoleLimit and   
 DDCI adding a simple 'where =' at the end would kill the left outer join that is used  
 in the link between the two view. To deal with this we just wrap HQRoleLimit.Type in a case statement  
 to capture for null values. You can see in the where statement how it works.  
- This view also uses a report specific table function called vf_rptHQGetRoleMemberOverrideInfo.   
 The full functionality and notes regarding what it does can be found in the notes  
 section of the function itself. But it used here to get the override values (if there  
 are any) for each member in a role. I am always including the standard limit and threshold   
 values on each line as there may be times a user will want to compare standard to override.   
 And since the function only standard OR override (dependingon the data) we need to have something  
 that always returns standard values.   
Other than than just remembet that Roles may or may not have types and may or may not have members.  
Members may or may not have overrides.   
    
Parameters:      
N/A    
    
Related reports:     
HQ Roles List (ID#: 1212)        
        
Revision History        
Date  Author  Issue     Description    
  
***********************************************************************/         
      
AS    
  
SELECT  
 hqr.Role AS HQRole  
 , hqr.Description AS HQRoleDescription  
 , hqr.Active AS HQRoleActiveFlag  
 , hqr.UsableInPC AS HQRolePCUsable  
 , hqr.UsableInPM AS HQRolePMUsable  
 , hqr.UsableInSM AS HQRoleSMUsable  
 , hqrl.Type AS HQRoleLimtType  
 , ci.DisplayValue AS HQRoleLimitTypeDescription  
 , hqrl.SubType AS HQRoleLimitSubType  
 , hqrl.Limit AS HQRoleLimitDefaultLimit  
 , hqrl.Threshold AS HQRoleLimitDefaultThreshold  
 , hqrl.Active AS HQRoleLimitActiveFlag  
 , hqrm.UserName AS HQRoleMemberUserName  
 , vuser.FullName AS HQRoleMemberFullName  
 , hqrm.Active as HQRoleMemberActiveFlag  
 , hqrmo.UserFinalLimit AS HQRoleMemberFinalLimit  
 , hqrmo.UserFinalLimitOverrideActiveFlag AS HQRoleMemberFinalLimitActiveFlag  
 , hqrmo.UserFinalThreshold AS HQRoleMemberFinalThreshold  
 , hqrmo.UserFinalThresholdOverrideActiveFlag AS HQRoleMemberFinalThresholdActiveFlag  
From  
 HQRoles hqr  
LEFT OUTER JOIN  
 HQRoleLimit hqrl ON  
  hqrl.Role = hqr.Role  
LEFT OUTER JOIN  
 HQRoleMember hqrm ON  
  hqrm.Role = hqr.Role  
LEFT OUTER JOIN  
 DDUP vuser ON  
  vuser.VPUserName = hqrm.UserName  
LEFT OUTER JOIN  
 DDCI ci ON  
  ci.DatabaseValue = hqrl.Type  
OUTER APPLY  
 dbo.vf_rptHQGetRoleMemberOverrideInfo (hqrl.Role, hqrl.Type, hqrl.SubType, hqrm.UserName) hqrmo   
WHERE  
 (CASE WHEN hqrl.Type IS NULL THEN 'HQRoleLimitType' ELSE ci.ComboType END) = 'HQRoleLimitType'  
  
GO
GRANT SELECT ON  [dbo].[vrvHQRolesListByMember] TO [public]
GRANT INSERT ON  [dbo].[vrvHQRolesListByMember] TO [public]
GRANT DELETE ON  [dbo].[vrvHQRolesListByMember] TO [public]
GRANT UPDATE ON  [dbo].[vrvHQRolesListByMember] TO [public]
GRANT SELECT ON  [dbo].[vrvHQRolesListByMember] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvHQRolesListByMember] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvHQRolesListByMember] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvHQRolesListByMember] TO [Viewpoint]
GO
