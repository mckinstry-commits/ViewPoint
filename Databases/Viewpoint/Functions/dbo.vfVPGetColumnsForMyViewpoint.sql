SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************
* Created:	CC 8/25/2010
*			CC 04/12/2011 - include datatype masks
*			CC 04/27/2011 - better handle computed columns, hide 99 control types by default
*			AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function., Fixing performance issue by using an inline table function.
*			GPT - 7/28/11 - TK-06982 Alias computed columns that start with dbo.vf correctly.
*           GPT 08/25/2011 - Extract CustomGridColHeadings for custom fields.  TK-07950  
*			
* 
*
* Inputs:
*	@FormName		The name of the form in DDFH
*	
*
* Output:
*	resultset	Query Columns
*
* Return code:
*
****************************************************/
CREATE FUNCTION [dbo].[vfVPGetColumnsForMyViewpoint] ( @FormName VARCHAR(30) )
RETURNS TABLE
AS
RETURN
(
	SELECT  REPLACE(REPLACE(COALESCE(COALESCE(CustomGridColHeading, GridColHeading), ColumnName), 
					'[', ''),']', '') AS Name,
			COALESCE(DDFIShared.Datatype, '') AS Datatype,
			COALESCE(DDFIShared.InputMask, dbo.DDDTShared.InputMask, '') AS InputMask,
			COALESCE(DDFIShared.InputLength, dbo.DDDTShared.InputLength, 8000) AS InputLength, 
			GridCol,
			COALESCE(DDFIShared.InputType, dbo.DDDTShared.InputType, 0) AS InputType,
			ControlType,
			CASE WHEN DDFIShared.ControlType = 99 THEN 'N'
				 ELSE ShowGrid
			END AS ShowGrid,
			CASE WHEN ViewName IS NOT NULL AND (Computed = 'N' OR NOT [ColumnName] LIKE '% %')
					THEN [ColumnName]
				WHEN Computed = 'Y' AND (LEFT([ColumnName],2) = 'vf' OR LEFT([ColumnName], 6) = 'dbo.vf')
					THEN REPLACE(REPLACE(COALESCE(GridColHeading, ColumnName), '[', '' ), ']', '')
				WHEN Computed = 'Y' AND  [ColumnName] LIKE '% %' OR GridColHeading Is Not Null
					THEN REPLACE(REPLACE(COALESCE(GridColHeading, ColumnName), '[', '' ), ']', '')
				ELSE [ColumnName]
			END AS ColumnName,
			'N' AS IsDescriptionColumn,
			ExcludeFromAggregation
	FROM dbo.vfDDFIShared(@FormName) AS DDFIShared
	LEFT OUTER JOIN dbo.DDDTShared ON DDFIShared.Datatype = dbo.DDDTShared.Datatype
	WHERE Form = @FormName
	AND ColumnName IS NOT NULL
	AND ( ControlType <> 5 OR ShowGrid = 'Y')
	
	UNION ALL
	
	SELECT	REPLACE(REPLACE(
				CASE WHEN PATINDEX( '% as %', LOWER(DescriptionColumn)) <> 0
						THEN REVERSE(LEFT(REVERSE(DescriptionColumn),PATINDEX('% sa %',REVERSE(LOWER(DescriptionColumn))) - 1))
				ELSE DescriptionColumn			
				END , '[', '' ), ']', '') 
			AS Name,
			COALESCE(DDFIShared.Datatype, dbo.DDDTShared.Datatype, '') AS Datatype,
			COALESCE(DDFIShared.InputMask, dbo.DDDTShared.InputMask, '') AS InputMask,
			COALESCE(DDFIShared.InputLength, dbo.DDDTShared.InputLength, 8000) AS InputLength, 
			GridCol,
			COALESCE(DDFIShared.InputType, dbo.DDDTShared.InputType, 0) AS InputType,
			ControlType,
			CASE WHEN ShowDesc < 2 THEN ShowGrid
			     ELSE 'N'
			END AS ShowGrid,    
			REPLACE(REPLACE(
				CASE WHEN PATINDEX( '% as %', LOWER(DescriptionColumn)) <> 0
						THEN REVERSE(LEFT(REVERSE(DescriptionColumn),PATINDEX('% sa %',REVERSE(LOWER(DescriptionColumn))) - 1))
				ELSE DescriptionColumn			
				END , '[', '' ), ']', '') AS ColumnName,
			'Y' AS IsDescriptionColumn,
			ExcludeFromAggregation
	FROM dbo.vfDDFIShared(@FormName) AS DDFIShared
	LEFT OUTER JOIN dbo.DDDTShared ON DDFIShared.Datatype = dbo.DDDTShared.Datatype
	WHERE Form = @FormName	
	AND ColumnName IS NOT NULL
	AND DescriptionColumn IS NOT NULL
	
	UNION ALL
	
	SELECT	p.ColumnName AS Name,
			'' AS Datatype,
			'' AS InputMask,
			8000 AS InputLength,
			0 AS GridCol,
			0 AS InputType,
			0 AS ControlType, 
			'N' AS ShowGrid,
			p.ColumnName AS ColumnName,
			'N' AS IsDescriptionColumn,
			'Y' AS ExcludeFromAggregation
	FROM VPPartFormChangedMessages m
	INNER JOIN VPPartFormChangedParameters p ON p.FormChangedID = m.KeyID
	WHERE FormName = @FormName and ColumnName <> '' And ViewName <> ''
)
GO
GRANT SELECT ON  [dbo].[vfVPGetColumnsForMyViewpoint] TO [public]
GO
