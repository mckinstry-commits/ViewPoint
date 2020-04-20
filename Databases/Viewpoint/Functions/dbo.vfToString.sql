SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/22/2011
-- Description:	Like .net's Convert.ToString this will return the given value regardless of its
--				type the varchar representation of the value and if NULL is passed in an empty
--				string value will be returned. This is very useful when concatenating values to 
---				build a string like we do in our batch validation procs.
-- =============================================
CREATE FUNCTION [dbo].[vfToString]
(
	@value nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
	IF @value IS NULL
	BEGIN
		RETURN ''
	END

	RETURN @value
END

GO
GRANT EXECUTE ON  [dbo].[vfToString] TO [public]
GO
