SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[mvwTaxCodeDetailMappingWorksheet_AllInc]
as
SELECT
	parenttx.TaxGroup
,	parenttx.TaxCode
,	geo.City
,	geo.PostOffice
,	geo.County
,	geo.State
,	geo.ZipCode
--,	COUNT(childtx.TaxCode) AS ChildTaxCodeMembers
,	COALESCE(childtx.NewRate,0.00) AS TaxRate
,	COALESCE(childtx.udReportingCode,'') AS ReportingCode
FROM 
	dbo.budGeographicLookup geo LEFT OUTER JOIN
	bHQTX parenttx ON
		geo.McKCityId = CASE WHEN parenttx.TaxCode LIKE '%X' THEN LEFT(parenttx.TaxCode, LEN(parenttx.TaxCode)-1) ELSE parenttx.TaxCode END LEFT OUTER JOIN
	bHQTL hqtl ON
		hqtl.TaxGroup=parenttx.TaxGroup
	AND hqtl.TaxCode=parenttx.TaxCode LEFT OUTER JOIN
	bHQTX childtx ON
		hqtl.TaxGroup=childtx.TaxGroup
	AND hqtl.TaxLink=childtx.TaxCode


GO
