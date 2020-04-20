IF OBJECT_ID (N'[dbo].[fnGetEffectiveDepartmentRate]', N'FN') IS NOT NULL
    DROP FUNCTION [dbo].[fnGetEffectiveDepartmentRate];
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 09/03/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE FUNCTION [dbo].[fnGetEffectiveDepartmentRate] (@co tinyint, @glDept varchar(4), @rateType varchar(30))
RETURNS numeric(12,2)
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE @rate numeric(8,6)
	
	SELECT @rate = f.Rate
	FROM dbo.udGLDepartmentRates f JOIN
		(SELECT cr.Co, cr.GLDept, cr.RateType, max(cr.EffectiveDate) AS EffectiveDate 
		FROM dbo.udGLDepartmentRates cr
		WHERE cr.EffectiveDate <= getdate()
		GROUP BY cr.Co, GLDept, cr.RateType
		HAVING cr.Co = @co 
			AND cr.GLDept = @glDept
			AND cr.RateType = @rateType
		) s
	ON f.Co = s.Co AND f.GLDept = s.GLDept AND f.RateType = s.RateType AND f.EffectiveDate = s.EffectiveDate
	
	IF (@rate IS NULL)
		SET @rate = 0
	RETURN(@rate)
END
GO

-- Test Script
SELECT dbo.fnGetEffectiveDepartmentRate (1, '0201', 'XDEPTSTAFF')
SELECT dbo.fnGetEffectiveDepartmentRate (1, '0201', 'XDEPTUNION')
SELECT dbo.fnGetEffectiveDepartmentRate (10, '0001', 'XDEPTUNI')