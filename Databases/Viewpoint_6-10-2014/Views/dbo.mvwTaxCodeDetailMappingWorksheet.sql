SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[mvwTaxCodeDetailMappingWorksheet]
as
SELECT
	hqtl.TaxGroup
,	parenttx.TaxCode
,	geo.City
,	geo.PostOffice
,	geo.County
,	geo.State
,	geo.ZipCode
--,	COUNT(childtx.TaxCode) AS ChildTaxCodeMembers
,	childtx.NewRate AS TaxRate
,	childtx.udReportingCode
FROM
	bHQTL hqtl FULL JOIN
	bHQTX parenttx ON
		hqtl.TaxGroup=parenttx.TaxGroup
	AND hqtl.TaxCode=parenttx.TaxCode FULL JOIN
	bHQTX childtx ON
		hqtl.TaxGroup=childtx.TaxGroup
	AND hqtl.TaxLink=childtx.TaxCode FULL JOIN
	dbo.budGeographicLookup geo ON
		geo.McKCityId = CASE WHEN parenttx.TaxCode LIKE '%X' THEN LEFT(parenttx.TaxCode, LEN(parenttx.TaxCode)-1) ELSE parenttx.TaxCode END

GO
GRANT SELECT ON  [dbo].[mvwTaxCodeDetailMappingWorksheet] TO [public]
GRANT INSERT ON  [dbo].[mvwTaxCodeDetailMappingWorksheet] TO [public]
GRANT DELETE ON  [dbo].[mvwTaxCodeDetailMappingWorksheet] TO [public]
GRANT UPDATE ON  [dbo].[mvwTaxCodeDetailMappingWorksheet] TO [public]
GO
