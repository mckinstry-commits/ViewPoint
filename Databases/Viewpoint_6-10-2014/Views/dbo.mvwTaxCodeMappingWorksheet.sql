SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[mvwTaxCodeMappingWorksheet]
as
SELECT
	hqtl.TaxGroup
,	parenttx.TaxCode
,	geo.City
,	geo.PostOffice
,	geo.County
,	geo.State
,	geo.ZipCode
,	COUNT(childtx.TaxCode) AS ChildTaxCodeMembers
,	SUM(childtx.NewRate) AS TaxRate
,	dbo.mfnGetTaxReportingCodes(hqtl.TaxGroup,parenttx.TaxCode) AS ReportingCodes
FROM
	bHQTL hqtl JOIN
	bHQTX parenttx ON
		hqtl.TaxGroup=parenttx.TaxGroup
	AND hqtl.TaxCode=parenttx.TaxCode JOIN
	bHQTX childtx ON
		hqtl.TaxGroup=childtx.TaxGroup
	AND hqtl.TaxLink=childtx.TaxCode LEFT OUTER JOIN
	dbo.budGeographicLookup geo ON
		geo.McKCityId = CASE WHEN parenttx.TaxCode LIKE '%X' THEN LEFT(parenttx.TaxCode, LEN(parenttx.TaxCode)-1) ELSE parenttx.TaxCode END
GROUP BY
	hqtl.TaxGroup
,	parenttx.TaxCode
,	geo.City
,	geo.PostOffice
,	geo.County
,	geo.State
,	geo.ZipCode


GO
GRANT SELECT ON  [dbo].[mvwTaxCodeMappingWorksheet] TO [public]
GRANT INSERT ON  [dbo].[mvwTaxCodeMappingWorksheet] TO [public]
GRANT DELETE ON  [dbo].[mvwTaxCodeMappingWorksheet] TO [public]
GRANT UPDATE ON  [dbo].[mvwTaxCodeMappingWorksheet] TO [public]
GO
