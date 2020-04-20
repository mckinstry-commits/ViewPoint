SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVAWDTableLayout]
/***********************************************************************
* Created by: 	HH 11/05/2012
*
* Usage: Get table layout based on WDJBTableLayout and WDJBTableColumns
*
***********************************************************************/
@JobName VARCHAR(150)

AS  

-- table info
SELECT	JobName
		,IsPivot
		,WidthMode
		,Width
		,BorderStyle
		,BorderColor
		,BorderWidth
		,HeaderIsVisible
		,HeaderBackgroundColor
		,HeaderCellpadding
		,DetailBackgroundColor
		,DetailCellpadding
FROM WDJBTableLayout 
WHERE JobName = @JobName;

IF (SELECT IsPivot FROM WDJBTableLayout WHERE JobName = @JobName) = 'N'
BEGIN
	-- cell info		
	IF (SELECT HeaderIsVisible FROM WDJBTableLayout WHERE JobName = @JobName) = 'Y'
	BEGIN
		SELECT	JobName
				,REPLACE(REPLACE(ColumnName, '[', ''), ']', '') AS ColumnName
				,Seq
				,'header' AS LineType
		FROM WDJBTableColumns 
		WHERE JobName = @JobName AND Include = 'Y'
		UNION ALL
		SELECT	JobName
				,ColumnName
				,Seq
				,'detail' AS LineType
		FROM WDJBTableColumns 
		WHERE JobName = @JobName AND Include = 'Y'
		ORDER BY LineType DESC, Seq;
		
		SELECT	2 AS [RowCount]
				,COUNT(ColumnName) AS ColumnCount
		FROM WDJBTableColumns 
		WHERE JobName = @JobName AND Include = 'Y'
	END
	ELSE
	BEGIN
		SELECT	JobName
					,ColumnName
					,Seq
					,'detail' AS LineType
		FROM WDJBTableColumns 
		WHERE JobName = @JobName AND Include = 'Y'
		ORDER BY LineType DESC, Seq;
		
		SELECT	1 AS [RowCount]
				,COUNT(ColumnName) AS ColumnCount
		FROM WDJBTableColumns 
		WHERE JobName = @JobName AND Include = 'Y'
	END
END
ELSE
BEGIN
	-- cell info		
	IF (SELECT HeaderIsVisible FROM WDJBTableLayout WHERE JobName = @JobName) = 'Y'
	BEGIN
		;WITH cte
		AS
		(
			SELECT	JobName
				,REPLACE(REPLACE(ColumnName, '[', ''), ']', '') AS ColumnName
				,Seq
				,'header' AS LineType
			FROM WDJBTableColumns 
			WHERE JobName = @JobName AND Include = 'Y'
			UNION ALL
			SELECT	JobName
					,ColumnName
					,Seq
					,'detail' AS LineType
			FROM WDJBTableColumns 
			WHERE JobName = @JobName AND Include = 'Y'
		)
		SELECT * 
		FROM cte
		ORDER BY Seq, ColumnName;
		
		SELECT	COUNT(ColumnName) AS [RowCount]
				,2 AS ColumnCount
		FROM WDJBTableColumns 
		WHERE JobName = @JobName AND Include = 'Y'
	END
	ELSE
	BEGIN
		SELECT	JobName
					,ColumnName
					,Seq
					,'detail' AS LineType
		FROM WDJBTableColumns 
		WHERE JobName = @JobName AND Include = 'Y'
		ORDER BY LineType DESC, Seq;
		
		SELECT	COUNT(ColumnName) AS [RowCount]
				,1 AS ColumnCount
		FROM WDJBTableColumns 
		WHERE JobName = @JobName AND Include = 'Y'
	END
END








GO
GRANT EXECUTE ON  [dbo].[vspVAWDTableLayout] TO [public]
GO
