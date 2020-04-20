SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE View [dbo].[viDim_ARCustomer]    
  
/********************************************************    
Mike Brewer    
5/7/2010    
MS Cube     
Issue #127131      
********************************************************/    
    
AS    

select 
bARCM.KeyID as 'CustomerID',
bARCM.Customer as 'Customer',
bARCM.Name as 'CustomerName',
case bARCM.Status
	when 'A' then 'Active'
	when 'H' then 'On Hold'
	when 'I' then 'Inactive'
end as 'CustomerStatus'
from
bARCM  

union all

select
 0 -- CustomerID
, null --Customer
, 'Unassigned' --CustomerName
, null --CustomerStatus






GO
GRANT SELECT ON  [dbo].[viDim_ARCustomer] TO [public]
GRANT INSERT ON  [dbo].[viDim_ARCustomer] TO [public]
GRANT DELETE ON  [dbo].[viDim_ARCustomer] TO [public]
GRANT UPDATE ON  [dbo].[viDim_ARCustomer] TO [public]
GO
