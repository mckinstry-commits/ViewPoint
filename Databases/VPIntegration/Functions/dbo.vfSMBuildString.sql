SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/7/11
-- Description:	This function is meant to build a string by concatenating a value and a valuetoadd.
--				If the value is not null or an empty string then the seperator is added to the concatenation. 
--				This is especially handy when you want to turn a column of values into a comma seperated list of values.
-- =============================================
CREATE FUNCTION [dbo].[vfSMBuildString]
(
	@Value nvarchar(max), @ValueToAdd nvarchar(max), @Seperator nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
	RETURN
		CASE WHEN @Value IS NULL OR @Value = '' THEN ISNULL(@ValueToAdd, '')
			ELSE @Value + CASE WHEN @ValueToAdd IS NULL THEN '' ELSE ISNULL(@Seperator, '') + @ValueToAdd END
		END
END

GO
GRANT EXECUTE ON  [dbo].[vfSMBuildString] TO [public]
GO
