SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create PROCEDURE [dbo].[vrptSMServicableItems]  
(
	@SMCo bCompany = 0
	, @Customer bCustomer = 0
	, @ServiceSite varchar(20) = ''
	, @Class varchar(15) = ''
	, @Type varchar(15) = ''
	, @Make varchar(20) = ''
	, @Model varchar(20) = ''
	, @SiteStatus varchar(1) = 'B'
)

/**********************************************************************    
 * Created:		ScottAlvey 10/28/2011    
 * Modified:	
 *    
 * Usage:	Returns Serviceable Items details and most recent WorkOrder
 *	that last saw the item. 
 *
 * Parameters:	@SMCo - SM Company - if no value provided returns data for all SM companys found
				@Customer - Customer filter - related to service site of item
				@ServiceSite - service site filter - site of service item
				@Class - Class filter - Class of service item
				@Type - Type filter - Type of service item
				@Make - Make filter - Make of service item
				@Model - Model filter - Model of service item
				@SiteStatus - is the service site active or not - (A)ctive, (I)nactive, (B)oth
 *
 * Related reports:	SM Serviceable Items List (Rpt ID: 1196)
 *    
 **********************************************************************/    
  
AS  



set nocount on;

with

/*

	First we need to select all Service Items that related to the given filters.
	ISNull wrappers around the Class, Type, Make, and Model parameters in the 
	where statement is to ensure null values are not trying to be equated to eachother.
	Later on we will get the list of related work orders. The ss.Active where portion has a 
	case statement that does a bit translation due to the nature of the @SiteStatus 
	parameter. The @SiteStatus parameter returns B, A, or I. B is easy to understand
	but A really means Y and I really means N. So the case statements changes
	the value as necessary.
	
	Links:
		SMServiceItems (si) to get Service Item info
		SMServiceSite (ss) to get Service Site info
		ARCM (ar) to get Customer info
		HQCO (hq) to get Company name
	
*/

ItemsInfo as

( 
	SELECT
		hq.Name as CompanyName
		, si.SMCo
		, si.ServiceItem
		, si.Description as ServiceItemDescription
		, si.Class
		, si.Type
		, si.YearManufactured
		, si.Manufacturer
		, si.Model
		, si.LaborWarrantyExpDate
		, si.MaterialWarrantyExpDate
		, si.Location
		, ss.ServiceSite
		, ss.Description as ServiceSiteDescription
		, ss.Active
		, ar.Customer
		, ar.SortName
		, ar.Name as CustomerName
	FROM   
		SMServiceItems si 
	INNER JOIN 
		SMServiceSite ss ON 
			si.SMCo=ss.SMCo	AND 
			si.ServiceSite=ss.ServiceSite 
	INNER JOIN 
		ARCM ar ON 
			ss.CustGroup=ar.CustGroup AND 
			ss.Customer=ar.Customer
	INNER JOIN
		HQCO hq on
			si.SMCo = hq.HQCo		
	Where
		si.SMCo = (case when @SMCo <> 0 then @SMCo else si.SMCo end) and
		ar.Customer = (case when @Customer <> 0 then @Customer else ar.Customer end) and
		ss.ServiceSite = (case when @ServiceSite <> '' then @ServiceSite else ss.ServiceSite end) and
		isnull(si.Class,'') = (case when @Class <> '' then @Class else isnull(si.Class,'') end) and
		isnull(si.Type,'') = (case when @Type <> '' then @Type else isnull(si.Type,'') end) and
		isnull(si.Manufacturer,'') = (case when @Make <> '' then @Make else isnull(si.Manufacturer,'') end) and
		isnull(si.Model,'') = (case when @Model <> '' then @Model else isnull(si.Model,'') end) and
		ss.Active = (case when @SiteStatus <> 'B' then --see above CTE note for how this portion works
						(case when @SiteStatus = 'A' then 'Y' else 'N' end) 
					 else ss.Active end)
),

/*
	Secondly we need to get a list of WorkOrders associated with the serviceable item.
	The SMServiceableItemWOList does most of the heavy lifting for us, we just need to 
	link in the Service Site to get the name (ss.Description) of the site. Finally, since
	we need the LAST Work Order to touch the item we can rely on the fact that WOs are
	sequential. We group the data on Site and Item and then grab the max value of the WO related
	to that grouping. Since ss.Description will always be the same for each entry in that group
	we just grab the max value of that as well.
	
	Links:
		SMServiceableItemWOList (siwo) to WorkOrders associated with Serviceable Items
		SMServiceSite (ss) to get Service Site info	
*/

WorkOrderInfo as

(
	select
		max(siwo.WorkOrder) as WorkOrder
		, siwo.ServiceItem as WOServiceItem
		, siwo.ServiceSite as WOServiceSite
		, max(ss.Description) as WOServiceSiteDescription
	FROM
		SMServiceableItemWOList siwo
	Inner Join
		SMServiceSite ss on
			siwo.SMCo=ss.SMCo	AND 
			siwo.ServiceSite=ss.ServiceSite 
	Where
		siwo.SMCo = (case when @SMCo <> 0 then @SMCo else siwo.SMCo end) and
		siwo.ServiceSite = (case when @ServiceSite <> '' then @ServiceSite else siwo.ServiceSite end)
	Group by
		siwo.ServiceSite, siwo.ServiceItem
)

/* 
	Finally we join the two CTEs together and return the set to the report
	
	Links:
		(CTE) ItemsInfo (ii) Serviceable Item info
		(CTE) WorkOrderInfo (woi) Last WO to touch the item
*/

Select
	*
From
	ItemsInfo ii
Left Outer Join
	WorkOrderInfo woi on
		ii.ServiceSite = woi.WOServiceSite and
		ii.ServiceItem = woi.WOServiceItem

--select * from ItemsInfo
	

GO
GRANT EXECUTE ON  [dbo].[vrptSMServicableItems] TO [public]
GO
