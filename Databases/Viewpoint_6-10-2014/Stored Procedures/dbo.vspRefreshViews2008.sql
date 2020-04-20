SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************
* Create Date:	7/19/2011
* Created By:	AR 
* Modified By:	AR - 7/28/2011 - TK-06542 - realized I don't have an order to run so I need a recursive CTE to make a level and order by it
*		     
* Description: TK-06542 - Proc refreshes child and parent views of a view
				If the server is running 2008 or higher
*
* Inputs: 
*
* Outputs:
*
*************************************************/
CREATE PROCEDURE dbo.vspRefreshViews2008
	@viewname VARCHAR(128)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rfrshView VARCHAR(128),
			@level INTEGER;
	-- yep im using a curosor to loop through views :(
	DECLARE ViewCursor CURSOR LOCAL FAST_FORWARD FOR
		-- new system views that track dependencies better
		WITH ObjectDepends(entity_name,referenced_schema, referenced_entity, referenced_id,level)
		AS (
			SELECT entity_name = v.name
				,referenced_schema_name
				,referenced_entity_name
				,referenced_id
				,-1 AS level 
			FROM sys.sql_expression_dependencies AS sed 
				JOIN sys.views AS v ON v.[object_id] = sed.referencing_id
			WHERE OBJECT_NAME(referencing_id) = @viewname 
			
			UNION ALL
			
			SELECT entity_name = v.name
				,sed.referenced_schema_name
				,sed.referenced_entity_name
				,sed.referenced_id
				,level + 1   
			FROM ObjectDepends AS o
				JOIN sys.sql_expression_dependencies AS sed ON sed.referencing_id = o.referenced_id
				JOIN sys.views AS v ON v.[object_id] = sed.referencing_id
				-- if we go 5 levels we have a circular refresh so bail out and refresh what we got
			WHERE level < 5
			),
		    
		ObjectParent(entity_name,referenced_schema, referenced_entity, referencing_id,level)
		AS (
			SELECT entity_name = v.name
				,referenced_schema_name
				,referenced_entity_name
				,referencing_id
				,0 AS level 
			FROM sys.sql_expression_dependencies AS sed 
				JOIN sys.views AS v ON v.[object_id] = sed.referencing_id
			WHERE OBJECT_NAME(referenced_id) = @viewname
			
			UNION ALL
			
			SELECT entity_name = v.name
				,sed.referenced_schema_name
				,sed.referenced_entity_name
				,sed.referencing_id
				,level + 1   
			FROM ObjectParent AS o
				JOIN sys.sql_expression_dependencies AS sed ON sed.referenced_id = o.referencing_id
				JOIN sys.views AS v ON v.[object_id] = sed.referencing_id
				-- if we go 5 levels we have a circular refresh so bail out and refresh what we got
			WHERE level < 5
		    
			)

			SELECT entity_name,level
			FROM ObjectDepends

			UNION ALL

			SELECT entity_name,level
			FROM ObjectParent
			ORDER BY level
			-- lets not get crazy or we have some issues
			OPTION (MAXRECURSION 1000);
			
	OPEN ViewCursor		
		-- Get the first child view to fresh.
		FETCH NEXT FROM ViewCursor INTO @rfrshView, @level
	
		WHILE @@FETCH_STATUS = 0
			BEGIN	
				EXEC sys.sp_refreshview @rfrshView
				-- Get the first child view to fresh.
				FETCH NEXT FROM ViewCursor INTO @rfrshView,@level
			END
	CLOSE ViewCursor
	DEALLOCATE ViewCursor

END
GO
GRANT EXECUTE ON  [dbo].[vspRefreshViews2008] TO [public]
GO
