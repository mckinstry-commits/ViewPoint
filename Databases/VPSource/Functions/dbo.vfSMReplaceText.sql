SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/23/10
-- Description:	Replaces all text between a given start and end commented tags with the text supplied
-- =============================================
CREATE FUNCTION [dbo].[vfSMReplaceText]
(	
	@text nvarchar(max), @insertText nvarchar(max), @xmlTag varchar(128)
)
RETURNS nvarchar(max)
AS
BEGIN
	DECLARE @startIndex int, @endIndex int
	
	SET @startIndex = 1
	
	WHILE @startIndex <> 0
	BEGIN
		SET @startIndex = CHARINDEX('<' + @xmlTag + '>', @text, @startIndex)

		IF @startIndex <> 0
		BEGIN
			SET @startIndex = @startIndex + LEN(@xmlTag) + 2
			
			SET @endIndex = CHARINDEX('</' + @xmlTag + '>', @text, @startIndex)
			
			IF @endIndex <> 0
			BEGIN
				SET @text = STUFF(@text, @startIndex, @endIndex - @startIndex, @insertText)
			END
		END
	END
	
	RETURN @text
END

GO
GRANT EXECUTE ON  [dbo].[vfSMReplaceText] TO [public]
GO
