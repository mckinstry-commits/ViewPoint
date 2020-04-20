SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mary Ann Vollbrecht
-- Create date: 11/1/11
-- Description:	returns current single level tax rate or GST/PST tax rates from multilevel taxcodes
-- =============================================
CREATE FUNCTION dbo.vfHQTaxRatesForPSTGST 
(
	-- Add the parameters for the function here
	@TaxGroup bGroup, @TaxCode bTaxCode
)
RETURNS 
@retPSTGSTTaxRates TABLE 
(
	-- Add the column definitions for the TABLE variable here
	TaxRate bRate NOT NULL DEFAULT 0,
	PSTRate bRate NOT NULL DEFAULT 0
)
AS
BEGIN
	DECLARE @TaxRate bRate, @PSTRate bRate,@ValueAdd char(1), @MultiLevel char(1)
	SELECT @TaxRate = 0, @PSTRate = 0
	IF @TaxGroup IS NULL
	BEGIN
		GOTO ExitFunction
	END
	IF @TaxCode IS NULL
	BEGIN
		GOTO ExitFunction
	END
		-- Add the T-SQL statements to compute the return value here
		SELECT @ValueAdd = ValueAdd, @MultiLevel = MultiLevel
		FROM dbo.bHQTX with (nolock)
		WHERE TaxGroup = @TaxGroup and TaxCode = @TaxCode
		IF @@ROWCOUNT = 0
			BEGIN
			GOTO ExitFunction
   			END
		 
		IF @ValueAdd = 'N'
		BEGIN
			GOTO ExitFunction
		END
		ELSE
		BEGIN
			/* International - VAT */
			IF @MultiLevel = 'N'
			BEGIN
				--Single Level - GST only or (HST)Harmonized:  Pulls from the base taxcode.
				SELECT @TaxRate = ISNULL(base.NewRate,0) 
				FROM dbo.bHQTX base with(nolock)
				WHERE base.TaxGroup = @TaxGroup and base.TaxCode = @TaxCode
			END
			ELSE
			BEGIN
				--MultiLevel - GST & PST or HST(Harmonized with breakout)
				/* Get GST rate for conversion */
				SELECT @TaxRate = ISNULL(comp.NewRate,0)
				FROM dbo.bHQTX base with(nolock)
				FULL OUTER JOIN dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
				FULL OUTER JOIN dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
				WHERE base.TaxGroup = @TaxGroup and base.TaxCode = @TaxCode and comp.GST = 'Y' 

				/* Determine Tax Rate */
				SELECT @PSTRate = SUM(CASE comp.InclGSTinPST WHEN 'Y'
					THEN
   						--MultiLevel (GST included in PST):  Pulls from the component taxcode and performs conversion
						((1.0 + @TaxRate) * ISNULL(comp.NewRate,0))
					ELSE
						--MultiLevel:  Pulls from the component without conversion
						ISNULL(comp.NewRate,0)
					end)
				FROM dbo.bHQTX base with(nolock)
				FULL OUTER JOIN  dbo.bHQTL l with(nolock) ON l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
				FULL OUTER JOIN  dbo.bHQTX comp with(nolock) ON comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
				WHERE base.TaxGroup = @TaxGroup and base.TaxCode = @TaxCode and comp.GST = 'N'
				GROUP BY base.TaxCode, base.MultiLevel
			END
		END 

	ExitFunction:
	  -- copy the required columns to the result of the function 
   INSERT @retPSTGSTTaxRates (TaxRate, PSTRate)
   VALUES (@TaxRate,@PSTRate)
   	
	RETURN 
END
GO
GRANT SELECT ON  [dbo].[vfHQTaxRatesForPSTGST] TO [public]
GO
