SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APOnCostVendorTypesYN] as 
SELECT DISTINCT
	w.APCo,
	w.Mth,
	w.APTrans,
	CASE ISNULL(v.OnCostID,'') WHEN '' THEN 'Y' ELSE 'N' END as 'OnCostYN'
FROM dbo.APOnCostWorkFileHeader w
JOIN dbo.APTH h ON 
	w.APCo=h.APCo
	AND w.Mth=h.Mth
	AND w.APTrans=h.APTrans
LEFT JOIN dbo.APVendorMasterOnCost v
ON w.APCo=v.APCo AND h.VendorGroup = v.VendorGroup AND h.Vendor = v.Vendor

GO
GRANT SELECT ON  [dbo].[APOnCostVendorTypesYN] TO [public]
GRANT INSERT ON  [dbo].[APOnCostVendorTypesYN] TO [public]
GRANT DELETE ON  [dbo].[APOnCostVendorTypesYN] TO [public]
GRANT UPDATE ON  [dbo].[APOnCostVendorTypesYN] TO [public]
GO
