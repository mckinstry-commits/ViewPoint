IF OBJECT_ID (N'[dbo].[fnGetEffectiveCompanyRate]', N'FN') IS NOT NULL
    DROP FUNCTION [dbo].[fnGetEffectiveCompanyRate];
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 08/26/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE FUNCTION [dbo].[fnGetEffectiveCompanyRate] (@dept varchar(4), @rateType varchar(30))
RETURNS numeric(8,6)
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE @co tinyint
	DECLARE @rate numeric(8,6)

	SELECT TOP 1 @co = glpi3.GLCo
	FROM [ViewpointAG\Viewpoint].[Viewpoint].[dbo].GLPI glpi3 
	WHERE	glpi3.Instance = @dept 
		AND glpi3.PartNo=3
		--AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4)
	ORDER BY GLCo

	SELECT @rate = f.Rate
	FROM [ViewpointAG\Viewpoint].[Viewpoint].[dbo].[udCompanyRates] f JOIN
		(SELECT cr.Co, cr.RateType, max(cr.EffectiveDate) AS EffectiveDate 
		FROM [ViewpointAG\Viewpoint].[Viewpoint].[dbo].[udCompanyRates] cr
		WHERE cr.EffectiveDate <= getdate()
		GROUP BY cr.Co, cr.RateType
		HAVING cr.Co = @co 
			AND cr.RateType = @rateType
		) s
	ON f.Co = s.Co AND f.RateType = s.RateType AND f.EffectiveDate = s.EffectiveDate
	
	IF (@rate IS NULL)
		SET @rate = CASE @rateType WHEN 'CELLMU' THEN 0.33 WHEN 'CELLJC' THEN 55.00 ELSE 0.0 END
	RETURN(@rate)
END
GO

-- Test Script
--SELECT dbo.fnGetEffectiveCompanyRate ('0000', 'CELLJC')
--SELECT dbo.fnGetEffectiveCompanyRate ('000', 'CELLJ')