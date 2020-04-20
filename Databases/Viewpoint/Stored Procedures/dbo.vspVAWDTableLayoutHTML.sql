SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVAWDTableLayoutHTML]
/***********************************************************************
* Created by: 	HH 11/05/2012
*
* Usage: Create the HTML table layout based on WDJBTableLayout and WDJBTableColumns
*
***********************************************************************/
@JobName VARCHAR(150),
@TableLayoutString VARCHAR(8000) OUTPUT

AS  

DECLARE @BorderWidth INT
DECLARE @HeaderIsVisible bYN
DECLARE @HeaderBackgroundColor VARCHAR(7)
DECLARE @HeaderCellpadding INT
DECLARE @DetailBackgroundColor VARCHAR(7)
DECLARE @DetailCellpadding INT

SELECT @BorderWidth = BorderWidth
		,@HeaderIsVisible = HeaderIsVisible
		,@HeaderBackgroundColor = HeaderBackgroundColor
		,@HeaderCellpadding = HeaderCellpadding
		,@DetailBackgroundColor = DetailBackgroundColor
		,@DetailCellpadding  =  DetailCellpadding
FROM WDJBTableLayout 
WHERE JobName = @JobName;
		
SET @TableLayoutString = '<table width=100% border="' + CAST(@BorderWidth AS VARCHAR(10)) + '">'
SET @TableLayoutString = @TableLayoutString + '<tr>'
IF @HeaderIsVisible = 'Y'
BEGIN
	SELECT @TableLayoutString = @TableLayoutString + 
			STUFF
			(
				(
					SELECT '<th bgcolor="'+ @HeaderBackgroundColor +'" cellpadding="'+ CAST(@HeaderCellpadding AS VARCHAR(10)) +'">' + REPLACE(REPLACE(ColumnName, '[', ''), ']', '') + '</th>'
					FROM WDJBTableColumns C
					WHERE JobName = @JobName
							AND Include = 'Y'
					ORDER BY Seq
					FOR XML PATH(''), ROOT('Query'), TYPE 
						).value('/Query[1]','VARCHAR(MAX)'), 1, 0, ''
			) 
	SET @TableLayoutString = @TableLayoutString + '</tr><tr>'
END	

SELECT @TableLayoutString = @TableLayoutString + 
		STUFF
		(
			(
				SELECT '<td bgcolor="'+ @DetailBackgroundColor +'" cellpadding="'+ CAST(@DetailCellpadding AS VARCHAR(10)) +'">' + ColumnName + '</td>'
				FROM WDJBTableColumns C
				WHERE JobName = @JobName 
						AND Include = 'Y'
				ORDER BY Seq
				FOR XML PATH(''), ROOT('Query'), TYPE 
					).value('/Query[1]','VARCHAR(MAX)'), 1, 0, ''
		) 
SET @TableLayoutString = @TableLayoutString + '</tr></table>'



GO
GRANT EXECUTE ON  [dbo].[vspVAWDTableLayoutHTML] TO [public]
GO
