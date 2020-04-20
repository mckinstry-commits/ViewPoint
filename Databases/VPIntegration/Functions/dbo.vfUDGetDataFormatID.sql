SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Chris G
-- Create date: 8/23/12
-- Description:	Maps a DDFIc record to Connects pPortalDataFormat.ID
--				for use with UD Mapping.
-- =============================================
CREATE FUNCTION [dbo].[vfUDGetDataFormatID]
  (@view VARCHAR(128), @columnName VARCHAR(128))
RETURNS INTEGER
AS
BEGIN
	DECLARE @inputMask AS VARCHAR(30), @inputType AS TINYINT, @prec AS TINYINT, @dataFormatID AS Integer
	
	SELECT @inputMask = InputMask, @inputType = InputType, @prec = Prec
	FROM DDFIc
	WHERE ViewName = @view AND ColumnName = @columnName
	
	-- Any input mask will return a String field since Connects can't support masks
	-- Otherwise if 0 - Text or 5 - Multi-part use string
	IF @inputMask IS NOT NULL OR @inputType = 0 OR @inputType = 5
	BEGIN
		Return 11 -- String
	END
	
	-- Do the conversion from DDFI.InputType -> pPortalDataFormat
	SELECT @dataFormatID =
		CASE 
			-- Date
			WHEN @inputType = 2 THEN 1 -- Date		
			-- Month
			WHEN @inputType = 3 THEN 7 -- Year & Month
			-- Numeric, must take precision into account
			WHEN @inputType = 1 THEN 
				CASE
				    -- Numeric/Decimal
					WHEN @prec = 3 THEN 9 -- Number (Commas, 3 decimalys
					-- Big Int
					WHEN @prec = 4 THEN 13 -- Large Integer
					ELSE 10 -- Default Integer
				END
			ELSE 11 -- default to string
		END			
		
	Return @dataFormatID
END
GO
GRANT EXECUTE ON  [dbo].[vfUDGetDataFormatID] TO [public]
GO
