SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[viDim_MSCustomerJob]

as

With CustJob

as

--combine distinct Customer Jobs from MSTD and MSQH.  Union operator removes duplicates

(
select 
	  bMSTD.MSCo
	, bMSCO.KeyID AS MSCoID	  
	, CustGroup
	, Customer
	, CustJob

From bMSTD	
Inner Join bMSCO With (NoLock) on bMSCO.MSCo = bMSTD.MSCo
Where SaleType = 'C' and Customer is not null and CustJob is not null
Group By 
	  bMSTD.MSCo
	, bMSCO.KeyID	  
	, CustGroup
	, Customer
	, CustJob
	
union

select    bMSQH.MSCo
		, bMSCO.KeyID AS MSCoID	  
		, CustGroup
		, Customer
		, CustJob	
From bMSQH
Inner Join bMSCO With (NoLock) on bMSCO.MSCo = bMSQH.MSCo
Where QuoteType = 'C' and CustJob is not null
Group By   bMSQH.MSCo
		 , bMSCO.KeyID
		 , CustGroup
		 , Customer		
		 , CustJob
)		 
	
select 
	  MSCo
	, MSCoID	
	, CustGroup
	, Customer
	, CustJob
	, row_number() over (order by CustGroup, Customer, CustJob) as CustJobID
From CustJob	

union all

Select
	  Null
	, Null
	, Null
	, Null
	, 'Unassigned'
	, 0


	



GO
GRANT SELECT ON  [dbo].[viDim_MSCustomerJob] TO [public]
GRANT INSERT ON  [dbo].[viDim_MSCustomerJob] TO [public]
GRANT DELETE ON  [dbo].[viDim_MSCustomerJob] TO [public]
GRANT UPDATE ON  [dbo].[viDim_MSCustomerJob] TO [public]
GRANT SELECT ON  [dbo].[viDim_MSCustomerJob] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_MSCustomerJob] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_MSCustomerJob] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_MSCustomerJob] TO [Viewpoint]
GO
