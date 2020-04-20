SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[mfnGetCombinedTaxRate]
(
	@TaxGroup bGroup
,	@TaxCode  bTaxCode
)
RETURNS numeric(18,3)
BEGIN

DECLARE @combinedrate numeric(18,3)

SELECT @combinedrate=cr.CombinedRate FROM
(
SELECT
	tl.TaxGroup, tl.TaxCode, COALESCE(SUM(tx2.NewRate),0.00) AS CombinedRate--, SUM(tx.NewRate)
FROM 
	Viewpoint.dbo.bHQTX tx LEFT OUTER JOIN
	Viewpoint.dbo.bHQTL tl ON
		tx.TaxGroup=tl.TaxGroup
	AND tx.TaxCode=tl.TaxLink LEFT OUTER JOIN
	Viewpoint.dbo.bHQTX tx2 ON
		tx2.TaxGroup=tl.TaxGroup
	AND tx2.TaxCode IN (tl.TaxLink,tl.TaxCode)

GROUP BY
	tl.TaxGroup, tl.TaxCode
UNION 
SELECT
	tx.TaxGroup, tx.TaxCode, COALESCE(SUM(tx.NewRate),0.00) AS CombinedRate--, SUM(tx.NewRate)
FROM 
	Viewpoint.dbo.bHQTX tx
GROUP BY
	tx.TaxGroup, tx.TaxCode
) cr 
WHERE
	cr.TaxGroup=@TaxGroup
AND cr.TaxCode=@TaxCode

RETURN @combinedrate
END
GO
