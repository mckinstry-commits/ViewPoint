SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[viFact_EMWarranty] AS

--EM Warranty Fact
with APInvoiceByVendor as
(Select APCo,
         Vendor,
		 VendorGroup,
         APRef,
         sum(isnull(InvTotal, 0)) as Cost
From bAPTH APTH
Group By APCo, Vendor, VendorGroup, APRef),

Warranty as

(select bEMWF.EMCo,
		bEMWF.Equipment,
		bEMWF.KeyID as WarrantyID,
		bEMWF.APCo,    
		bEMWF.APVendor,
		bEMWF.VendorGroup,
		bEMWF.APRef,
		bEMWF.WarrantyExpirationDate,
		bEMWF.DatePurchased,
		datediff(dd, Getdate(),bEMWF.WarrantyExpirationDate) as 'DaysLeft',
		datediff(mm, Getdate(),bEMWF.WarrantyExpirationDate) as 'MonthsLeft',
		datediff(yy, Getdate(),bEMWF.WarrantyExpirationDate) as 'YearsLeft',
		case when isnull(bEMWF.WarrantyMiles,0)>0 
			 then isnull(bEMWF.MilesAtInstall, 0) + isnull(bEMWF.WarrantyMiles,0) - isnull(bEMEM.OdoReading, 0)
		else 0 end as 'MilesLeft',
		case when isnull(bEMWF.WarrantyHours, 0)>0
			 then  isnull(bEMWF.HoursAtInstall, 0) + isnull(bEMWF.WarrantyHours, 0) - isnull(bEMEM.HourReading, 0)
		else 0 end as 'HoursLeft',
		case when bEMWF.Status = 'A' then 1 else 0 end as 'ActiveWarrantyCount'
 from bEMWF
 join bEMEM 
	on  bEMEM.EMCo = bEMWF.EMCo
	and bEMEM.Equipment = bEMWF.Equipment	
)

select 
Company.KeyID as 'EMCoID',
Department.KeyID as 'DepartmentID',
Category.KeyID as 'CategoryID',
Equipment.KeyID as 'EquipmentID',
Warranty.WarrantyID,
Warranty.DaysLeft,
Warranty.MonthsLeft,
Warranty.YearsLeft,
Warranty.MilesLeft,
Warranty.HoursLeft,
datediff(dd, '1/1/1950',Warranty.WarrantyExpirationDate) as 'WarrantyExpirationDateID',
isnull(Cast(cast(Company.GLCo as varchar(3))
+cast(Datediff(dd,'1/1/1950',cast(cast(DATEPART(yy,WarrantyExpirationDate) as varchar) 
+ '-'+ DATENAME(m, WarrantyExpirationDate) +'-01' as datetime)) as varchar(10)) as int),0) as FiscalMthID,
datediff(dd, '1/1/1950', Warranty.DatePurchased) as 'DatePurchasedID',	
APInvoiceByVendor.Cost as 'WarrantyCost',
Case when DaysLeft <= 0 then 1
	 when MilesLeft <= 0 then 1
	 when HoursLeft <= 0 then 1
end as 'IsExpired',
Warranty.ActiveWarrantyCount

from bEMEM Equipment
join Warranty
	on  Equipment.EMCo = Warranty.EMCo
	and Equipment.Equipment = Warranty.Equipment
left join APInvoiceByVendor
	on  Warranty.APCo        = APInvoiceByVendor.APCo
	and Warranty.APVendor    = APInvoiceByVendor.Vendor
	and Warranty.VendorGroup = APInvoiceByVendor.VendorGroup  
	and Warranty.APRef	     = APInvoiceByVendor.APRef
left join bEMCO Company
		ON  Equipment.EMCo = Company.EMCo
left join bEMDM Department 
		ON  Equipment.EMCo			 = Department.EMCo
		AND Equipment.Department = Department.Department
left join bEMCM Category 
		ON  Equipment.EMCo			= Category.EMCo
		AND Equipment.Category	= Category.Category
Inner Join vDDBICompanies on vDDBICompanies.Co=Warranty.EMCo


GO
GRANT SELECT ON  [dbo].[viFact_EMWarranty] TO [public]
GRANT INSERT ON  [dbo].[viFact_EMWarranty] TO [public]
GRANT DELETE ON  [dbo].[viFact_EMWarranty] TO [public]
GRANT UPDATE ON  [dbo].[viFact_EMWarranty] TO [public]
GO
