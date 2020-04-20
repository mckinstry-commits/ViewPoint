SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[viDim_MSCustomerPO]

as

With CustPO

as

--combine distinct Customer PO from MSTD and MSQH.  Union operator removes duplicates

(
select 
	  bMSTD.MSCo
	, bMSCO.KeyID AS MSCoID	  	  
	, CustGroup
	, Customer
	, CustPO

From bMSTD
Inner Join bMSCO With (NoLock) on bMSCO.MSCo = bMSTD.MSCo	
Where SaleType = 'C' and Customer is not null and CustPO is not null
Group By 
	  bMSTD.MSCo
	, bMSCO.KeyID	  
	, CustGroup
	, Customer
	, CustPO
	
union

select    bMSQH.MSCo
		, bMSCO.KeyID AS MSCoID	  	  
		, CustGroup
		, Customer
		, CustPO	
From bMSQH
Inner Join bMSCO With (NoLock) on bMSCO.MSCo = bMSQH.MSCo
Where QuoteType = 'C' and CustPO is not null
Group By   bMSQH.MSCo
		 , bMSCO.KeyID
		 , CustGroup
		 , Customer		
		 , CustPO
)		 
	
select 
	  MSCo
	, MSCoID
	, CustGroup
	, Customer
	, CustPO
	, row_number() over (order by CustGroup, Customer, CustPO) as CustPOID
From CustPO	

union all

Select
	  Null
	, Null
	, Null
	, Null
	, 'Unassigned'
	, 0



GO
GRANT SELECT ON  [dbo].[viDim_MSCustomerPO] TO [public]
GRANT INSERT ON  [dbo].[viDim_MSCustomerPO] TO [public]
GRANT DELETE ON  [dbo].[viDim_MSCustomerPO] TO [public]
GRANT UPDATE ON  [dbo].[viDim_MSCustomerPO] TO [public]
GO
