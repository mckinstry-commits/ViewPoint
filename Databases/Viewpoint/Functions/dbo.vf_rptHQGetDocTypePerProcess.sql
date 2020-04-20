SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vf_rptHQGetDocTypePerProcess]

/***********************************************************************      
Author:   
Scott Alvey
     
Create date:   
05/15/2012
      
Usage:
Combines processes used on a data type (Job, EM Departent, or IN Location) with processes used
globally in a module.         

Things to keep in mind regarding this proc and related report:  
Alright, let's get some terminology cleared up here first. In the realm of WFProcess I am claiming 
that there are three layers of related data:

1-Processes that are defined in WFProcess but are not being used actively in a module or a 
	form (data type, more on that below)
2-Processes that are applied globally to a unique module\company combination as seen in 
	Company Setup form for that combination
3-Processes that are applied to a specific data type (form in a company) that may or may not 
	be a repeat of what is defined in layer 2. So a unique data type\company combination
	
In this documentation I am using the term 'data type' to mean an individual Job, EM Department, 
or IN Location. As of writing this these three data types are the only ones that can have a 
process (via the Workflow tab) assigned to them. Also keep in mind that a process applied in layer 
two means that all data types under that unique module\company combination will pick up that process. 
This means that a data type may have some redundant setup, if the same process is defined at layer 2 
and at layer 3. This also means though that a process defined at layer 3 may not be defined in layer 2. 
Finally, please realize that while Layer 1 and Layer 2 processes have their own data location 
(WFProcess and HQCompanyProcess respectively) layer 3 processes each have their own location of data:

JC-JCJobApprovalProcess
EM-EMDepartmentApprovalProcess
IN-INLocationApprovalProcess

Which means that, more than likely, as more data types receive the ability to processes defined on 
them each data type will continue to get its own view and this function will need to be updated with them.

Because a process can have layers of defined locations we are starting our data collection from the 
bottom up, from the layer 3 then union to layer 2.  The CTE ProcessList first parses each data 
type location to their process information. Each line from these three locations are given an 
ApprovalProcessLevel field value of '3', corresponding with my layer theory up above. At each 
of the three locations we filter for Company, Process, and DocType to help reduce the load of the 
final data call if filters are being used.  To these three locations we union HQCompanyProcess (with 
the same filters) to get us all the layer 2 values (ApprovalProcessLevel field value of '2'). This 
means that we in our CTE we will have values that are unique to a data type\company combination, 
values unique to module\company combinations, and\or combination of both if some processes are both 
defined a layer 2 and at layer 3.

Development Notes:
The @Process parameter, if given a blank value '', will return all processes. If given a process value
then it will return only data for that process.
  
Parameters:    
@Process - a Process found in layers 2 and 3
  
Related objects that call this function: 
vrptWFProcessApprovalWorkflow
   
      
Revision History      
Date  Author  Issue     Description
09/26/2012	ScottAlvey	CL-??????/V1-D-05976 remove case statement in the where clause
	the case statement is not necessary as @Process is being filled by WFProcess.Process which
	cannot be blank. 

***********************************************************************/  

(
	@Process  VARCHAR(20) 
)

RETURNS Table

AS

Return     

(  
--get layer 3 data start - see documentation up above for terminology    
	SELECT      
		3 as ApprovalProcessLevel    
		, 'EM' as VPModule    
		, pem.EMCo as ModuleCompanyNumber
		, pem.DocType as ModuleProcessDocTypeID     
		, pem.Process as ModuleProcessID     
		, pem.Active as ModuleProcessActiveFlag     
		, pem.Department as ModuleUniqueFieldValue      
		, 'EM Department' as ModuleUniqueFieldColumnName     
	FROM      
		EMDepartmentApprovalProcess pem      
	WHERE       
		pem.Process = @Process          

	UNION ALL      

	SELECT      
		3       
		, 'IN'      
		, pin.INCo      
		, pin.DocType      
		, pin.Process      
		, pin.Active      
		, pin.Loc      
		, 'IN Location'      
	FROM      
		INLocationApprovalProcess pin      
	WHERE       
		pin.Process = @Process   

	UNION ALL      

	SELECT      
		3       
		, 'JC'      
		, pjc.JCCo      
		, pjc.DocType      
		, pjc.Process      
		, pjc.Active      
		, pjc.Job      
		, 'JC Job'      
	FROM      
		JCJobApprovalProcess pjc      
	WHERE       
		pjc.Process = @Process    
		
--get layer 3 data end
--get layer 2 data start - see documentation up above for terminology

	UNION ALL      

	SELECT      
		2      
		, h.Mod      
		, h.HQCo      
		, h.DocType      
		, h.Process      
		, h.Active      
		, ''      
		, ''      
	FROM      
		HQCompanyProcess h      
	WHERE      
		h.Process = @Process  
		
--get layer 2 data end    
)
	
GO
GRANT SELECT ON  [dbo].[vf_rptHQGetDocTypePerProcess] TO [public]
GO
