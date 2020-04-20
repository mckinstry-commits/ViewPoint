SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vf_rptHQGetRoleMemberOverrideInfo]

/***********************************************************************      
Author:   
Scott Alvey
     
Create date:   
04/26/2012 

Originating V1 reference:   
B-09520 POWF - Reports - HQ Roles Lists  
      
Usage:  
Given the Role, Type, SubType, and UserName this fuction will return either the
Limit and\or Threshold values found in HQRoleMemberOverride or if one or both of those
are null it will the related standard Limit and\or Threshold values defined in 
HQRoleLimit for the UserName given.

Development Notes:
  
Parameters:    
@Role - typically sent from HQRoleLimit
@Type - typically sent from HQRoleLimit
@SubType - typically sent from HQRoleLimit
@User - typically sent from HQRoleMembers
  
Related reports:   
multiple HQ Role reports      
      
Revision History      
Date  Author  Issue     Description  

***********************************************************************/  

(
	@Role varchar(20)
	, @Type varchar(10)
	, @SubType varchar(10)
	, @User bVPUserName
)

RETURNS TABLE

AS

RETURN
(
	Select
		  isnull(hqrmo.Limit, hqrl.Limit) as UserFinalLimit
		, isnull(hqrmo.Threshold, hqrl.Threshold) as UserFinalThreshold
		, (case when hqrmo.Limit is null then 'N' else 'Y' end) as UserFinalLimitOverrideActiveFlag
		, (case when hqrmo.Threshold is null then 'N' else 'Y' end) as UserFinalThresholdOverrideActiveFlag
	From
		HQRoleLimit hqrl
	left join
		HQRoleMemberOverride hqrmo on
			hqrmo.Role = hqrl.Role
			and hqrmo.Type = hqrl.Type
			and hqrmo.SubType = hqrl.SubType
			and hqrmo.UserName = @User
	Where
		hqrl.Role = @Role
		and hqrl.Type = @Type
		and hqrl.SubType = @SubType
)




GO
GRANT SELECT ON  [dbo].[vf_rptHQGetRoleMemberOverrideInfo] TO [public]
GO
