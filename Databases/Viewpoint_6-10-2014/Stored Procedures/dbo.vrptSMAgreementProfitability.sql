SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
        
          
CREATE PROCEDURE [dbo].[vrptSMAgreementProfitability]           
(              
 @SMCompany bCompany    
 , @SMCustomer int  
 , @Agreement varchar(15)  
 , @ShowOtherDollars bYN  
)           
                
/*=================================================================================                        
                  
Author:  
DML  
Scott Alvey                                              
                  
Create date:  
7/17/2012   
  
Originating V1 reference:  
B-07779 - Create SM Agreement Profitablity report                                      
                          
Usage:  
This proc is used to drive the above listed report.       
    
Development Notes:  
The related report has the unique requirement of showing work completed records  
that are not directly related to an agreement via a field, but related via an   
outside the software understanding that an agreement exists and that we would not  
have had this unrelated work if there was no agreement. This is similar to the following  
scenario:  
  
 I buy a car and have an agreement with the dealer that I will take my car to them  
 for service. As they work on my car over time a recorded history builds up in  
 their service database. At some point in time my friend needs his car worked on   
 as well. I recomend the dealer and decides to do business with them. Now the   
 businees the dealership gained from my friend would not have occured if they   
 did not have a service agreement with me. So the business they gained is related  
 to the service agreement they had with me, but not directly, and that loose   
 relationship is not defined clearly in the database.  
   
So the problem here is summed up as:   
  
 If there is no direct relationship between agreement work and non-agreement   
 work that is realted to an existing agreement, how do you create that relationship?  
  
The answer we have settled on is this:  
  
 Agreements have a Date Activated field and any non-agreement work completed  
 records that occur on or after this date are considered related to the agreement.  
 Even if the agreement has expired and no new agreement has taken it's place  
 the 'relationship' with the customer is considered to have started on that date  
 and if work still continues for that customer, it falls under that 'relationship'  
 umbrella.  
   
Futhermore this date field that is used to determine when to start looking at  
non-agreement related work complete records is based on if there is an Agreement  
value for the @Agreement paramter:  
   
 If @Agreement <> '' then the date used to determine when to start accumulating  
 non-agreement dollars is the DateActivated value of this agreement.   
 Otherwise (@Agreement = '') we get the first DateActive date found for the   
 @SMCustomer value in the SMAgreement view. If no value for @SMCustomer is given,  
 meaning the report is being ran wide open on Agreement and Customer then we  
 just grab the earliest Agreement date we can find, regardless of the customer.  
   
This is all based on the premise that this is an 'Agreement Profitability Report' or  
in the context of agreements what dollars are directly related and what are loosly related.  
Either way there has to be an agreement to start the whole relationship.  
  
We understand that this is a very fluid relationship and as of writing this proc we   
have not created a way to more robust way of making a direct link between agreement  
and non-agreement work.   
  
So, on to the rest of the proc and what it does. The proc divides up billable and   
cost dollars into the 8 different categories (four pairs):  
  
 Agreement Related dollars:  
  1 - Maintenance billable  
  2 - Maintenance cost  
  3 - Addon\Extra billable  
  4 - Addon\Extra cost  
  5 - Full Coverage billable  
  6 - Full Coverage cost  
 Non-Agreement dollars  
  7 - Other billable  
  8 - Other cost  
    
The first category cannot be found using work completed records but the rest can.   
Maintenance billable comes from SM Agreement Billing records. To get the data we   
have the second part of the union statement looking to SMAgreementInvoiceList. All  
other categories look to SMWorkCompleted, SMWorkOrder, and SMWorkOrderScope for  
their information. The last line in the where statement of the first part of the  
union calls a function that is able to compare null values to see if they equal  
each other (you cannot just check to see if they are equal via an '=' operator).  
If the user, by setting the @ShowOtherDollars flag to 'N', says I do not want to  
see other (non-agreement related) dollars, then the where statement returns ' ' for  
each null wc.Agreement value. It then compares that to its unaltered self. Since ' '   
does not equal null it gets dropped. If the user sets the flag to 'Y' then the where  
statement just compares native wc.Agreement value to native wc.Agreement value.  
  
Parameters:  
@SMCompany - filter for SM Company value  
@SMCustomer - filter for SM Customer value  
@Agreement - filter for SM Agreement value  
@ShowOtherDollars - flag to control non-agreement related dollars showing or not  
      
Related reports or other objects:    
SM Agreement Profitability (ID: 1221)           
          
Revision History          
Date  Author  Issue     Description        
06/26/2013	ScottAlvey TFS-52921 - Added FP details. Modified to understand 
	Non-Billable. Also corrected issue where the final select was looking to the 
	wrong place to get Invoice Date          
                
==================================================================================*/         
  
as  

/*    
Keep in mind here that while an Agreement can have multiple Revisions, the Agreement   
is always related to the same customer, regardless of Revisions.   

The reason why this   
is here is that if we want to filter on a specific agreement, but want to see the other  
dollar amount categories (7 and 8 in the documentation above) we can't just rely on the  
agreement to do the filtering. Because if we do, the other (non-agreement related) values  
will be excluded. But if we take away the agreement filter then all other non-agreement  
related data will show, regardless of the customer.   

So here we get the customer of the agreement we are filtering on and then set the   
@SMCustomer to this value so we can use it as a filter later on both the CTE and the   
final select. This way we can pull in non-agreement related values that are related  
to the customer of the agreement we are filtering.  
*/    

DECLARE @BegSMCustomer int, @EndSMCustomer int        

	IF @SMCustomer = 0 and @Agreement <> ' '       
		BEGIN        
			select @SMCustomer = max(Customer) from SMAgreement where SMCo = @SMCompany and Agreement = @Agreement               
		END            
;     

with  

/*       
We need get the the starting date of the customer relationship of either:  
the customer we are filtering on  
or the agreement we are filtering on  
or, if we are running this report wide open, the date for each customer  
with an agreement (active or expired)  
We use this date to determine what non-agreement related records we can look at  
in the final select. Please read the starting documentation for more about why  
we are doing this.      

Links:          
SMAgreement(smag) to get Agreement information       
*/   

DateRangeForOtherDollars  

as  

(  
	select  
		smag.SMCo  
		, smag.CustGroup  
		, smag.Customer  
		, min(smag.DateActivated) as OtherDollarsStartDate  
	from  
		SMAgreement smag   
	where    
		smag.SMCo = @SMCompany  
		and (case when @SMCustomer = 0 then smag.Customer else @SMCustomer end) = smag.Customer  
		and (case when @Agreement = ' ' then smag.Agreement else @Agreement end) = smag.Agreement  
		and smag.Status > 1  
		and smag.DateCancelled is null  
	group by  
		smag.SMCo  
		, smag.CustGroup  
		, smag.Customer  
),

/*       
    

Links:          
   
*/   
  
WorkCompletedFlatPriceDetails as
(
	select
		c.SMCo
		, c.WorkOrder
		, c.Scope
		, c.Agreement
		, c.Revision
		, c.UseAgreementRates
		, c.Date
		, c.NoCharge
		, c.NonBillable
		, isnull(c.ActualCost,0) as ActualCost
		, isnull(c.ProjCost,0) as ProjCost
		, isnull(c.PriceTotal,0) as PriceTotal
		, c.Coverage
	from	
		SMWorkOrderScope s
	join
		SMWorkCompleted c on
			s.SMCo = c.SMCo
			and s.WorkOrder = c.WorkOrder
			and s.Scope = c.Scope

	union

	select
		s.SMCo
		, s.WorkOrder
		, s.Scope
		, s.Agreement
		, s.Revision
		, 'N' as UseAgreementRates
		, max(w.EnteredDateTime) as Date
		, 'N' as NoCharge
		, 'N' as NonBillable
		, 0 as ActualCost
		, 0 as Projcost
		, sum(isnull(f.Amount,0)) as PriceTotal
		, null as Coverage
	from
		SMWorkOrder w
	join
		SMWorkOrderScope s on
			w.SMCo = s.SMCo
			and w.WorkOrder = s.WorkOrder
	join
		SMEntity e on
			s.SMCo = e.SMCo
			and s.WorkOrder = e.WorkOrder
			and s.Scope = e.WorkOrderScope
	join
		SMFlatPriceRevenueSplit f on
			e.SMCo = f.SMCo
			and e.EntitySeq = f.EntitySeq
	where
		s.PriceMethod = 'F'
	group by
		s.SMCo
		, s.WorkOrder
		, s.Scope
		, s.Agreement
		, s.Revision
)

--Get all agreements regardless if there are related work complete records  

select      
	'1' as UnionFlag       
	, agmt.SMCo      
	, null as WorkOrder       
	, null as SMWorkOrderID       
	, null as WOSScope      
	, null as SMWorkOrderScopeID            
	, null as WCScope      
	, agmt.Agreement as SMAgmtAgmt  
	, isnull(agmt.Revision,0) as Revision
	, agmt.DateActivated as SMAgmtDateActivated  
	, isnull(agmt.DateTerminated, '01/01/1950') as SMAgmtDateTerminated
	, agmt.ExpirationDate as SMAgmtExpirationDate  
	, null as OtherDollarsStartDate    
	, null as UseAgreementRates    
	, null as SMAgmtDesc      
	, agmt.Agreement as WCAgmt      
	, agmt.SMAgreementID       
	, cust.Customer as SMCust      
	, cm.Name as ARCustName        
	, null as WOSPrice           
	, null as Date          
	, null as Service      
	, 'N' as NoCharge
	, 'N' as NonBillable
	, null as ActProjFlag      
	, null as AgmtBill      
	, null as AgmtCost      
	, null as AddonBill      
	, null as AddonCost      
	, null as InsBill      
	, null as InsCost      
	, null as DemandBill      
	, null as DemandCost      
	, null as Pricetotal      
	, null as ActualCost      
	, null as PriceMethod  
	, null as Coverage      
	, HQCO.HQCo        
	, HQCO.Name         
from      
	SMAgreement agmt    
join       
	SMCustomer cust on       
		agmt.SMCo = cust.SMCo        
		and agmt.CustGroup = cust.CustGroup        
		and agmt.Customer = cust.Customer        
inner join       
	HQCO on       
		agmt.SMCo = HQCO.HQCo        
inner join       
	ARCM cm on       
		agmt.Customer = cm.Customer        
		and agmt.CustGroup = cm.CustGroup       
where      
	agmt.SMCo = @SMCompany  
	and (case when @SMCustomer = 0 then agmt.Customer else @SMCustomer end) = agmt.Customer  
	and (case when @Agreement = ' ' then agmt.Agreement else @Agreement end) = agmt.Agreement  
	and agmt.Status > 1  
	and agmt.DateCancelled is null    

union all  

-- get all billing and cost that is defined at the work completed level
-- of the four pairs of data this gets all but Maintenance billable 

Select    
	'2' as UnionFlag        
	, wc.SMCo       
	, wc.WorkOrder       
	, wo.SMWorkOrderID       
	, wos.Scope as WOSScope      
	, wos.SMWorkOrderScopeID         
	, wc.Scope as WCScope      
	, agmt.Agreement as SMAgmtAgmt  
	, isnull(agmt.Revision,0) as Revision  
	, agmt.DateActivated as SMAgmtDateActivated  
	, isnull(agmt.DateTerminated, '01/01/1950') as SMAgmtDateTerminated    
	, agmt.ExpirationDate as SMAgmtExpirationDate 
	, isnull(drfod.OtherDollarsStartDate, '01/01/1950') as OtherDollarsStartDate   
	, wos.UseAgreementRates    
	, agmt.Description as SMAgmtDesc      
	, wc.Agreement as WCAgmt      
	, agmt.SMAgreementID       
	, cust.Customer as SMCust      
	, cm.Name as ARCustName        
	, wos.Price as WOSPrice      
	, wc.Date            
	, wos.Service      
	, wc.NoCharge   
	, wc.NonBillable 
	, (case when wos.PriceMethod <> 'F'
			then (case when wc.ActualCost = 0 then 'P' else 'A' end)
			else null end
	  ) as ActProjFlag
	, 'AgmtBill' =   
	CASE when   
			wc.Scope is not null       
			and wos.Service is not null       
			and wc.Agreement is not null  
			and wos.PriceMethod = 'F'    
		then wc.PriceTotal
		else 0 
	end    
	, 'AgmtCost' =   
	CASE when   
			wc.Scope is not null       
			and wos.Service is not null       
			and wc.Agreement is not null      
		then (case when wc.ActualCost = 0 then wc.ProjCost else wc.ActualCost end)
		else 0 
	end       
	, 'AddonBill' =   
	CASE when   
			wc.Scope is not null       
			and wos.Service is null       
			and wc.Agreement is not null       
			and (  
					(wos.PriceMethod = 'T' and wc.UseAgreementRates = 'N') 
					or wos.PriceMethod = 'F'  
				)    
			and (wc.NoCharge <> 'Y' and wc.NonBillable <> 'Y')
		then wc.PriceTotal   
		else 0 
	end      
	, 'AddonCost' =   
	CASE when   
			wc.Scope is not null       
			and wos.Service is null       
			and wc.Agreement is not null       
			and (  
					(wos.PriceMethod = 'T' and wc.UseAgreementRates = 'N') 
					or wos.PriceMethod = 'F'   
				)    
		then (case when wc.ActualCost = 0 then wc.ProjCost else wc.ActualCost end) 
		else 0 
	end
	, 'InsBill' =   
	CASE when   
			wc.Scope is not null     
			and wos.Service is null       
			and wc.Agreement is not null       
			and (  
					(wos.PriceMethod = 'T' and wc.UseAgreementRates = 'Y')    
					or wos.PriceMethod = 'N'
				)    
			and (wc.NoCharge <> 'Y' and wc.NonBillable <> 'Y')    
		then wc.PriceTotal   
		else 0 
	end        
	, 'InsCost' =   
	CASE when   
			wc.Scope is not null      
			and wos.Service is null       
			and wc.Agreement is not null       
			and (  
					(wos.PriceMethod = 'T' and wc.UseAgreementRates = 'Y')    
					or wos.PriceMethod = 'N'    
				)        
		then (case when wc.ActualCost = 0 then wc.ProjCost else wc.ActualCost end)  
		else 0 
	end      
	, 'DemandBill' =   
	CASE when   
			wc.Agreement is null     
			and (wc.NoCharge <> 'Y' and wc.NonBillable <> 'Y')    
			and wc.Date >= isnull(drfod.OtherDollarsStartDate, '01/01/1950')  
		then wc.PriceTotal   
		else 0 
	end      
	, 'DemandCost' =   
	CASE when   
			wc.Agreement is null  
			and wc.Date >= isnull(drfod.OtherDollarsStartDate, '01/01/1950')  
		then (case when wc.ActualCost = 0 then wc.ProjCost else wc.ActualCost end)   
		else 0 
	end      
	, wc.PriceTotal       
	, wc.ActualCost       
	, wos.PriceMethod  
	, wc.Coverage      
	, HQCO.HQCo        
	, HQCO.Name        
From   
	SMWorkOrder wo        
inner join   
	SMWorkOrderScope wos on   
		wo.SMCo = wos.SMCo         
		and wo.WorkOrder = wos.WorkOrder  
left join   
	DateRangeForOtherDollars drfod on   
		wo.SMCo = drfod.SMCo  
		and wo.CustGroup = drfod.CustGroup  
		and wo.Customer = drfod.Customer     
inner join   
	WorkCompletedFlatPriceDetails wc on   --SMWorkCompleted
		wos.SMCo = wc.SMCo         
		and wos.WorkOrder = wc.WorkOrder        
		and wos.Scope = wc.Scope        
left join   
	SMAgreement agmt on   
		wc.SMCo = agmt.SMCo         
		and wc.Agreement = agmt.Agreement        
		and wc.Revision = agmt.Revision       
inner join   
	SMCustomer cust on   
		wo.SMCo = cust.SMCo        
		and wo.CustGroup = cust.CustGroup        
		and wo.Customer = cust.Customer        
inner join   
	HQCO on   
		wo.SMCo = HQCO.HQCo        
inner join   
	ARCM cm on   
		wo.Customer = cm.Customer        
		and wo.CustGroup = cm.CustGroup  
where    
	wo.SMCo = @SMCompany  
	and (case when @SMCustomer = 0 then wo.Customer else @SMCustomer end) = wo.Customer  
	and dbo.vfIsEqual((case when @ShowOtherDollars = 'Y' then wc.Agreement else isnull(wc.Agreement,' ') end),wc.Agreement) = 1  

union all

-- gets Maintenance billable dollara from agreement billing    

select      
	'3' as UnionFlag       
	, smabse.SMCo      
	, null as WorkOrder       
	, null as SMWorkOrderID       
	, null as WOSScope      
	, null as SMWorkOrderScopeID          
	, null as WCScope      
	, agmt.Agreement as SMAgmtAgmt  
	, isnull(agmt.Revision,0) as Revision   
	, agmt.DateActivated as SMAgmtDateActivated  
	, isnull(agmt.DateTerminated, '01/01/1950') as SMAgmtDateTerminated   
	, agmt.ExpirationDate as SMAgmtExpirationDate
	, null as OtherDollarsStartDate    
	, null as UseAgreementRates    
	, null as SMAgmtDesc      
	, smabse.Agreement as WCAgmt      
	, agmt.SMAgreementID       
	, cust.Customer as SMCust      
	, cm.Name as ARCustName        
	, null as WOSPrice        
	, smil.InvoiceDate as Date           
	, null as Service      
	, 'N' as NoCharge  
	, 'N' as NonBillable
	, null as ActProjFlag       
	, isnull(smabse.BillingAmount,0) + isnull(smabse.TaxAmount,0) as AgmtBill      
	, null as AgmtCost      
	, null as AddonBill      
	, null as AddonCost      
	, null as InsBill      
	, null as InsCost      
	, null as DemandBill      
	, null as DemandCost      
	, null as Pricetotal      
	, null as ActualCost      
	, null as PriceMethod  
	, null as Coverage      
	, HQCO.HQCo        
	, HQCO.Name         
from      
	SMAgreementBillingScheduleExt smabse
INNER JOIN
	SMInvoiceList smil on
		smil.SMInvoiceID = smabse.SMInvoiceID      
join      
	SMAgreement agmt  on      
		smabse.SMCo = agmt.SMCo         
		and smabse.Agreement = agmt.Agreement        
		and smabse.Revision = agmt.Revision      
join       
	SMCustomer cust on       
		agmt.SMCo = cust.SMCo        
		and agmt.CustGroup = cust.CustGroup        
		and agmt.Customer = cust.Customer        
inner join       
	HQCO on       
		agmt.SMCo = HQCO.HQCo        
inner join       
	ARCM cm on       
		agmt.Customer = cm.Customer        
		and agmt.CustGroup = cm.CustGroup       
where      
	smil.InvoiceDate is not null  
	and agmt.SMCo = @SMCompany  
	and (case when @SMCustomer = 0 then agmt.Customer else @SMCustomer end) = agmt.Customer  
	and (case when @Agreement = ' ' then agmt.Agreement else @Agreement end) = agmt.Agreement     
GO
GRANT EXECUTE ON  [dbo].[vrptSMAgreementProfitability] TO [public]
GO
