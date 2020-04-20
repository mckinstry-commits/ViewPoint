SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
      
CREATE Procedure [dbo].[vrptSMLEMWorkCompleted]       
(          
 @Co bCompany      
 , @WO int      
 , @WOScope int      
 , @BegDate bDate      
 , @EndDate bDate       
)       
            
/*=================================================================================                    
              
Author:                 
Scott Alvey            
Debra McKelvey-Linden                
              
Create date:                 
05/24/2012                 
              
Usage: 
Used to drive the SM Daily Work Ticket report.      
              
Things to keep in mind regarding this report and proc: 
Nothing fancy to see here, just collecting data from SMSMWorkOrder and SMWorkCompleted
with hops to some maintenance tables to get some definition data. Row Number and the case
statement to come up with the LEMTypeDescription value are used in the report.

Parameters:
@Co - SM Company
@WO - Work Order
@WOScope - Scope under the Work Order 
@Begdate\@EndDate - Dates for Work Completed records             
              
Related reports: 
SM Daily Work Ticket (ID 1216)
           
Revision History                    
Date  Author   Issue      Description              
            
==================================================================================*/                 
            
as  

/*  
 The @BegWO and @EndWO variables are used by the code below to define  
 what work orders will be filtered on. We will look to the proc parameter of @WO  
 and if @WO = 0 than this means we do not want to filter on a specific work order. So  
 The related variables are set to the extreems of the datatype value. If @WO <> 0   
 then there IS a specific work order to filter on. The variables are both set to the same value.  
 We do a range here so that we do not have to introduce an case\when\end statement in the   
 where clause which could be more of a performance impact then desired.  
 
 We are using this same logic for the @BegWOScope and @EndWOScope variables related to 
 the @WOScope variable
*/        
      
DECLARE @BegWO int, @EndWO int            
      
 IF @WO = 0            
  BEGIN            
   SET @BegWO = 0            
   SET @EndWO = 2147483647            
  END            
 ELSE            
  BEGIN            
   SET @BegWO = @WO            
   SET @EndWO = @WO            
  END           
        
DECLARE @BegWOScope int, @EndWOScope int            
      
 IF @WOScope = 0            
  BEGIN            
   SET @BegWOScope = 0            
   SET @EndWOScope = 2147483647            
  END            
 ELSE            
  BEGIN            
   SET @BegWOScope = @WOScope            
   SET @EndWOScope = @WOScope            
  END        
; 

With

CustJobWorkOrder

as

(

	select
		wo.SMCo
		, wo.WorkOrder
		, isnull(wo.Customer, jcm.Customer) as Customer
		, isnull(wocm.Name, jcm.Name) as Name
		, wo.ServiceSite        
		, wo.Description     
		, wo.ServiceCenter        
		, wo.RequestedDate        
		, wo.RequestedTime        
		, wo.ContactName          
		, wo.ContactPhone
	from
		SMWorkOrder wo
	left join        
		SMCustomer sc on        
		wo.SMCo = sc.SMCo and        
		wo.CustGroup = sc.CustGroup and        
		wo.Customer = sc.Customer        
	left join        
		ARCM wocm on        
		sc.Customer = wocm.Customer and        
		sc.CustGroup = wocm.CustGroup  
	left join
		JCJM job on 
		wo.JCCo = job.JCCo
		and wo.Job = job.Job
	left join
		JCCM cont on
		job.JCCo = cont.JCCo
		and job.Contract = cont.Contract
	left join        
		ARCM jcm on        
		cont.Customer = jcm.Customer and        
		cont.CustGroup = jcm.CustGroup
	where
		 wo.SMCo = @Co      
		and wo.WorkOrder between @BegWO and @EndWO  
)
            
select            
--Common            
   row_number() OVER          
      (PARTITION BY         
        wo.SMCo           
        , wo.WorkOrder        
        , wc.Scope        
        , wc.Type        
        , smct.SMCostTypeCategory         
       Order BY              
        wc.KeyID          
      ) AS RowNum         
 , wc.KeyID as KeyID            
 , wo.SMCo as SMCompanyID            
 , wo.WorkOrder as WorkOrderID            
 , wc.Scope as WorkOrderScopeID            
 , wc.Type as LEMTypeID            
 , isnull(wc.SMCostType,0) as SMCostTypeID              
 , isnull(smct.SMCostTypeCategory,'') as SMCostTypeCategoryID             
 , Case             
  when wc.Type = 1 then 'Equipment'            
  when wc.Type = 2 then 'Labor'            
   when wc.Type = 3 and smct.SMCostTypeCategory = 'E' then 'Equipment - Other'            
   when wc.Type = 3 and smct.SMCostTypeCategory = 'L' then 'Labor - Other'            
   when wc.Type = 3 and smct.SMCostTypeCategory = 'M' then 'Material - Other'            
   when wc.Type = 3 and smct.SMCostTypeCategory = 'S' then 'Subcontract'            
  when wc.Type = 4 then 'Material'            
  else 'Miscellaneous'            
   End as LEMTypeDescription            
 , wc.NoCharge as NoChargeFlag            
 , wc.Date as WorkCompleteDate         
 , wo.Customer        
 , wo.Name as 'CustomerName'        
 , wo.ServiceSite        
 , wo.Description as 'WODescription'        
 , wo.ServiceCenter        
 , wo.RequestedDate        
 , wo.RequestedTime        
 , wo.ContactName          
 , wo.ContactPhone         
--Equipment specific           
 , wc.EMCo as EquipmentCompanyID            
 , wc.Equipment as EquipmentID            
 , Case when wc.Type = 1 or (wc.Type = 3 and smct.SMCostTypeCategory = 'E') then wc.Description else '' end as EquipmentDescription            
 , wc.EMGroup as EquipmentGroupID            
 , wc.RevCode            
 , CASE WHEN erc.Basis = 'H' THEN erc.TimeUM ELSE eco.HoursUM END AS EquipmentBillableTimeUM            
 , wc.TimeUnits as EquipmentBillableTimeUnits            
 , wc.PriceRate as EquipmentBillableRate            
 , wc.PriceTotal as EquipmentPriceTotal          
--Labor specific                      
 , wc.Technician as TechnicianID            
 , Case when wc.Type = 2 or (wc.Type = 3 and smct.SMCostTypeCategory = 'L') then wc.Description else '' end as TechnicianActivityDescription            
 , pr.FullName as TechnicianFullName            
 , craft.Craft as TechnicianCraft            
 , craft.Description as TechnicianCraftDescription            
 , wc.PayType as TechnicianPayTypeID            
 , pt.Factor as TechnicianPayFactor            
 , wc.PriceRate as TechnicianPayRate            
 , wc.CostQuantity as TechnicianPayQuantity 
 , wc.PriceTotal as TechnicianPriceTotal     
--Material specific                      
 , wc.Part as MaterialID            
 , wc.MatlGroup as MaterialGroupID            
 , Case when wc.Type = 4 or (wc.Type = 3 and smct.SMCostTypeCategory = 'M') then wc.Description else '' end as MaterialDescription            
 , wc.Quantity as MaterialQuantity            
 , wc.PriceUM as MaterialUM            
 , wc.PriceRate as MaterialPriceRate            
 , wc.PriceTotal as MaterialPriceTotal            
--Misc specific                      
 , Case when wc.Type = 3 and smct.SMCostTypeCategory = 'S' then wc.Description else '' end as MiscDescription            
 , wc.PriceQuantity as MiscPriceQuantity            
 , wc.PriceRate as MiscPriceRate            
 , wc.PriceTotal as MiscPriceTotal            
from          
 CustJobWorkOrder wo        
left join        
 SMWorkCompleted wc on        
  wo.SMCo = wc.SMCo         
  and  wo.WorkOrder = wc.WorkOrder        
left join            
 SMCostType smct on            
  smct.SMCo = wc.SMCo            
  and smct.SMCostType = wc.SMCostType            
left join            
 EMRC erc on            
  erc.EMGroup = wc.EMGroup            
  and erc.RevCode = wc.RevCode            
left join             
 EMCO eco on             
  eco.EMCo = wc.EMCo            
left join            
 SMTechnician tech on            
  tech.SMCo = wc.SMCo            
  and tech.Technician = wc.Technician            
left join            
 PREHName pr on            
  pr.PRCo = tech.PRCo            
  and pr.Employee = tech.Employee            
left join            
 PRCM craft on            
  craft.PRCo = wc.PRCo            
  and craft.Craft = wc.Craft            
left join            
 SMPayType pt on            
  pt.SMCo = wc.SMCo            
  and pt.PayType = wc.PayType             
where      
 isnull(wc.Scope,0) between @BegWOScope and @EndWOScope      
 and case when isnull(wc.KeyID,0) <> 0 then wc.Date else '01/01/1950' end >= @BegDate      
 and case when isnull(wc.KeyID,0) <> 0 then wc.Date else '12/31/2050' end <= @EndDate      
         
         
        
GO
GRANT EXECUTE ON  [dbo].[vrptSMLEMWorkCompleted] TO [public]
GO
