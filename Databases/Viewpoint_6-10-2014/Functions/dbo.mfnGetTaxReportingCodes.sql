SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[mfnGetTaxReportingCodes]( @TaxGroup bGroup, @ParentTaxCode bTaxCode )
RETURNS varchar(255)
AS
BEGIN

DECLARE @retStr varchar(255)
DECLARE @udReportingCode VARCHAR(30)
DECLARE @taxCodeType VARCHAR(3)
DECLARE @taxRate VARCHAR(10)

SELECT @retStr=' '

IF @ParentTaxCode IS NOT NULL
BEGIN
	DECLARE txCur CURSOR FOR
	SELECT
		CASE 
			WHEN childtx.TaxCode LIKE '%[_]C' THEN 'C'
			WHEN childtx.TaxCode LIKE '%[_]CX' THEN 'C'
			WHEN childtx.TaxCode LIKE '%[_]P' THEN 'P'
			WHEN childtx.TaxCode LIKE '%[_]PX' THEN 'P'
			WHEN childtx.Description LIKE '% State %' AND childtx.TaxCode NOT LIKE '%[_]%' THEN 'S'
			WHEN childtx.Description LIKE '% County,%' AND childtx.TaxCode NOT LIKE '%[_]%'  THEN 'N'
			ELSE 'U'
		END AS Type		
	,	CASE 
			WHEN childtx.Description LIKE '% State %' AND childtx.TaxCode NOT LIKE '%[_]%' THEN LEFT(hqtl.TaxCode,2)
			ELSE childtx.udReportingCode
		END AS udReportingCode	
	,	CAST(COALESCE(childtx.NewRate,0.00) AS VARCHAR(10)) AS Rate
	FROM
		bHQTL hqtl JOIN
		bHQTX parenttx ON
			hqtl.TaxGroup=parenttx.TaxGroup
		AND hqtl.TaxCode=parenttx.TaxCode JOIN
		bHQTX childtx ON
			hqtl.TaxGroup=childtx.TaxGroup
		AND hqtl.TaxLink=childtx.TaxCode
	WHERE
		hqtl.TaxGroup=@TaxGroup
	AND parenttx.TaxCode=@ParentTaxCode 
	ORDER BY
		1,2
	FOR READ ONLY

	OPEN txCur
	FETCH txCur INTO @taxCodeType, @udReportingCode,@taxRate

	WHILE @@fetch_status=0
	BEGIN
		IF LTRIM(RTRIM(COALESCE(@udReportingCode,''))) <> ''
			SELECT @retStr=@retStr + @taxCodeType + ':' + LTRIM(RTRIM(COALESCE(@udReportingCode,''))) + ' [' + @taxRate + ']; '

		SELECT @taxCodeType=null,@udReportingCode=NULL,@taxRate=0.00
		FETCH txCur INTO @taxCodeType,@udReportingCode,@taxRate
	END

	CLOSE txCur
	DEALLOCATE txCur

	--SELECT @retStr=LTRIM(RTRIM(LEFT(@retStr,LEN(@retStr)-1)))
END

return @retStr

END
GO
