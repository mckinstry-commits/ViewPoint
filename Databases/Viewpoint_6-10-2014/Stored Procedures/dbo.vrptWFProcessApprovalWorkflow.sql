SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==================================================================================            

Author:      
Scott Alvey          

Create date:      
05/02/2012

Originating V1 reference:   
B-09521 POWF - Reports - HQ Approval Processes  

Usage:
PLEASE SEE DOCUMENTATION IN vf_rptHQGetDocTypePerProcess TO UNDERSTAND VARIOUS PROCESS LAYERS

This proc is used to drive the HQ Approval Process Detail report which shows for each procss where
the process is used, who is involved directly, who is involved via a roles, and the various header
details of the process found in WFProcess

We select data from WFProcess, to get Layer 1 data, and join to it thevf_rptHQGetDocTypePerProcess function. 
We also join in WFProcessStep and HQRoleMember to get users who are defined directly to a process via a 
step and users assigned to the process via a role (also assigned to a step).  because it may be useful
to have the description for the various data type instances (like Job Description for a job data type)
we are joining in each master list of that data type (JCJM, EMDM, and INLM). Filtering is done mostly 
here and has to uses case statement due to the left join nature of some of the views, so this may 
not scale very well. But I do not see a TON of data going through this so it should be fine.  

Parameters: 
@Company - feeds @BegCompany and @EndCompany to help allow the report to show all companies
@Module - filter for Viewpoint module using a process
@Process - master list in WFProcess view
@Role - role being used in a step hooked to a process
@VPUser - user being used in a step hooked to a process
@DocType - a doc type can be referenced by many processes     

Related reports:   
WF Approval Process Details (ID: 1213)      

Revision History            
Date  Author  Issue     Description      

==================================================================================*/       

CREATE Procedure [dbo].[vrptWFProcessApprovalWorkflow]      
(         
	@Company  bCompany      
	, @Module  VARCHAR(2)      
	, @Process  VARCHAR(20)      
	, @Role   VARCHAR(20)      
	, @VPUser  bVPUserName      
	, @DocType  VARCHAR(10)      
)      

AS 

/*  
 The @BegCompany and @EndCompany variables are used by the code below to define  
 what companies will be filtered on. We will look to the proc parameter of @Company  
 and if @Company = 0 than this means we do not want to filter on a specific Company. So  
 The related variables are set to the extreems of the datatype value. If @Company <> 0   
 then there IS a specific Company to filter on. The variables are both set to the same value.  
 We do a range here so that we do not have to introduce an case\when\end statement in the   
 where clause which could be more of a performance impact then desired.  
*/       

DECLARE @BegCompany bCompany, @EndCompany bCompany      

	IF @Company = 0      
		BEGIN      
			SET @BegCompany = 0      
			SET @EndCompany = 255      
		END      
	ELSE      
		BEGIN      
			SET @BegCompany = @Company      
			SET @EndCompany = @Company      
		END      
;      

SELECT      
	ISNULL(lp.ApprovalProcessLevel, 1) AS ApprovalProcessLevel      
	, wfp.Process AS WFProcessName      
	, wfp.Description AS WFProcessDescription      
	, wfp.DocType AS WFProcessDocTypeName      
	, wfp.Active AS WFProcessActiveFlag
	, wfp.DaysPerStep as WFProcessDaysPerStepNumber
	, wfp.DaysToRemind as WFProcessDaystoRemindNumber
	, wfp.ApproveTotal as WFProcessApproveTotalFlag      
	, wfps.Seq AS WFProcessStepSequenceNumber      
	, wfps.ApproverType AS WFProcessStepApproverType      
	, wfps.UserName AS WFProcessStepVPUser      
	, wfps.Role AS WFProcessStepRoleName    
	, hqrm.UserName AS WFProcessStepRoleMember  
	, lp.VPModule AS VPModuleID      
	, lp.ModuleCompanyNumber AS ModuleCompanyNumber      
	, lp.ModuleProcessActiveFlag AS ModuleProcessActiveFlag
	, lp.ModuleProcessDocTypeID as ModuleProcessDocTypeID      
	, lp.ModuleUniqueFieldValue AS ModuleUniqueFieldValue      
	, lp.ModuleUniqueFieldColumnName AS ModuleUniqueFieldColumnName     
	, j.Description AS JCJobDescription    
	, e.Description AS EMDepartmentDescription  
	, i.Description AS INLocationDescription  
FROM      
	WFProcess wfp      
outer apply 
	[vf_rptHQGetDocTypePerProcess](wfp.Process) lp    
LEFT JOIN      
	WFProcessStep wfps ON      
		wfp.Process = wfps.Process  
LEFT JOIN  
	HQRoleMember hqrm ON  
		hqrm.Role = wfps.Role  
LEFT JOIN    
	JCJM j ON    
		j.JCCo = lp.ModuleCompanyNumber    
		AND j.Job = lp.ModuleUniqueFieldValue    
		AND lp.ModuleUniqueFieldColumnName = 'JC Job'     
LEFT JOIN  
	EMDM e ON  
		e.EMCo = lp.ModuleCompanyNumber    
		AND e.Department = lp.ModuleUniqueFieldValue    
		AND lp.ModuleUniqueFieldColumnName = 'EM Department'    
LEFT JOIN  
	INLM i ON  
		i.INCo = lp.ModuleCompanyNumber    
		AND i.Loc = lp.ModuleUniqueFieldValue    
		AND lp.ModuleUniqueFieldColumnName = 'IN Location'   
WHERE 
	ISNULL(lp.ModuleCompanyNumber, 0) BETWEEN @BegCompany AND @EndCompany   
	AND (CASE WHEN @Process = '' THEN @Process ELSE wfp.Process END ) = @Process      
	AND (CASE WHEN @DocType = '' THEN @DocType ELSE coalesce(wfp.DocType,lp.ModuleProcessDocTypeID,'') END ) = @DocType      
	AND (CASE WHEN @Role = '' THEN @Role ELSE ISNULL(wfps.Role,'') END) = @Role      
	AND (CASE WHEN @VPUser = '' THEN @VPUser ELSE COALESCE(wfps.UserName,hqrm.UserName,'') END) = @VPUser        
	AND (CASE WHEN @Module = '' THEN @Module ELSE ISNULL(lp.VPModule,'') END) = @Module       
ORDER BY       
	lp.ApprovalProcessLevel      
	, lp.VPModule      
GO
GRANT EXECUTE ON  [dbo].[vrptWFProcessApprovalWorkflow] TO [public]
GO
