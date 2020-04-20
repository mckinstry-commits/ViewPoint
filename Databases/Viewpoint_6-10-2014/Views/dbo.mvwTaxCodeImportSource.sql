SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[mvwTaxCodeImportSource]
AS
SELECT gl.McKCityId AS TaxCode, NULL AS ParentTaxCode, gl.McKCityId, 'COMBINED' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(ts.SalesTaxRate,0.00) AS Rate, '' AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate  
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
UNION ALL
SELECT gl.State AS TaxCode, gl.McKCityId AS ParentTaxCode, null, 'STATE' AS TaxCodeType ,null, null, gl.State, null, null, COALESCE(gl.State,'') + ' State ' AS Description, COALESCE(ts.RateState,0.00) AS Rate, ts.ReportingCodeState AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate    
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateState <> 0 OR LEN(ts.ReportingCodeState) >0
UNION ALL
SELECT gl.State+LEFT(UPPER([dbo].[mfnStripNonAlphaNumeric](gl.County)),7) AS TaxCode, gl.McKCityId AS ParentTaxCode, null, 'COUNTY' AS TaxCodeType, ts.z2t_ID, null, gl.State, gl.County, null, COALESCE(gl.County,'') + ' County, ' + COALESCE(gl.State,'') AS Description, COALESCE(ts.RateCounty,0.00) AS Rate, ts.ReportingCodeCounty AS ReportingCode,(SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate   
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateCounty <> 0 OR LEN(ts.ReportingCodeCounty)>0
UNION ALL	
SELECT gl.McKCityId+'_C' AS TaxCode, gl.McKCityId AS ParentTaxCode, gl.McKCityId, 'CITY' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(ts.RateCity,0.00) AS Rate, ts.ReportingCodeCity AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate  
FROM 
	udGeographicLookup gl  LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateCity <> 0 OR LEN(ts.ReportingCodeCity)>0
UNION ALL
SELECT gl.McKCityId+'_P' AS TaxCode, gl.McKCityId AS ParentTaxCode, gl.McKCityId, 'SPECIAL' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(ts.RateSpecialDistrict,0.00) AS Rate, ts.ReportingCodeSpecialDistrict AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate  
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateSpecialDistrict <> 0 OR LEN(ts.ReportingCodeSpecialDistrict)>0
UNION ALL
SELECT gl.McKCityId+'X' AS TaxCode, NULL AS ParentTaxCode, gl.McKCityId, 'COMBINED' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(0.00,0.00) AS Rate, '' AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate  
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
UNION ALL
SELECT gl.State+'X' AS TaxCode, gl.McKCityId+'X' AS ParentTaxCode, null, 'STATE' AS TaxCodeType ,null, null, gl.State, null, null, COALESCE(gl.State,'') + ' State ' AS Description, COALESCE(0.00,0.00) AS Rate, ts.ReportingCodeState AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate    
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateState <> 0 OR LEN(ts.ReportingCodeState) >0
UNION ALL
SELECT gl.State+LEFT(UPPER([dbo].[mfnStripNonAlphaNumeric](gl.County)),7)+'X' AS TaxCode, gl.McKCityId+'X' AS ParentTaxCode, null, 'COUNTY' AS TaxCodeType, null, null, gl.State, gl.County, null, COALESCE(gl.County,'') + ' County, ' + COALESCE(gl.State,'') AS Description, COALESCE(0.00,0.00) AS Rate, ts.ReportingCodeCounty AS ReportingCode,(SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate   
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateCounty <> 0 OR LEN(ts.ReportingCodeCounty)>0
UNION ALL	
SELECT gl.McKCityId+'_C'+'X' AS TaxCode, gl.McKCityId+'X' AS ParentTaxCode, gl.McKCityId, 'CITY' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(0.00,0.00) AS Rate, ts.ReportingCodeCity AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate  
FROM 
	udGeographicLookup gl  LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateCity <> 0 OR LEN(ts.ReportingCodeCity)>0
UNION ALL
SELECT gl.McKCityId+'_P'+'X' AS TaxCode, gl.McKCityId+'X' AS ParentTaxCode, gl.McKCityId, 'SPECIAL' AS TaxCodeType, ts.z2t_ID, gl.ZipCode, gl.State, gl.County, gl.City, COALESCE(gl.City,'') + ' (' + COALESCE(gl.County,'') + '), ' + COALESCE(gl.State,'') + ' ' + COALESCE(gl.ZipCode,'') AS Description, COALESCE(0.00,0.00) AS Rate, ts.ReportingCodeSpecialDistrict AS ReportingCode, (SELECT IsActive FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS IsActive, (SELECT ManualEntry FROM udGeographicLookup x1 WHERE x1.McKCityId=gl.McKCityId) AS ManualEntry, TaxRateEffectiveDate AS EffectiveDate  
FROM 
	udGeographicLookup gl LEFT OUTER JOIN
	Zip2TaxSourceTaxTable ts ON
		ts.MatchString=gl.MatchString
WHERE
	ts.RateSpecialDistrict <> 0 OR LEN(ts.ReportingCodeSpecialDistrict)>0	

GO
