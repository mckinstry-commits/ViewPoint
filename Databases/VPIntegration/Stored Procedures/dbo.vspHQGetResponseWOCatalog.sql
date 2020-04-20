SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspHQGetResponseWOCatalog    Script Date: 03/31/2011 ******/
CREATE  proc [dbo].[vspHQGetResponseWOCatalog]
/*************************************
 * Created By:	GPT 03/31/2011 
 *
 *
 * called to get document object definitions by template name
 * filter by ResponseField definitions.
 *
 * Pass:
 * TemplateName		PM Document Template Name
 *
 * Success returns:
 *	0 and Document Object information
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@templatename bReportTitle, @msg varchar(255) output)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode INT

	SELECT @rcode = 0, @msg = ''

	---- get response fields and avlaues
	IF ISNULL(@templatename,'') <> ''
		BEGIN
			IF NOT EXISTS ( SELECT TOP 1 1 FROM HQWD WHERE TemplateName = @templatename)
			BEGIN
				SELECT @msg = 'Invalid Template Name', @rcode = 1
				GOTO vspexit
			END
			
 		    -- get docobject definition by template name filtered by response field instances
			SELECT DISTINCT 
					d.[TemplateName], 
					w.[DocObject], 
					w.[ObjectTable], 
					w.[Alias], 
					COALESCE(w.[JoinClause], 
							-- If Null joinclause, attempt key column extract from DDFH/DDFI and then add CoColumn
							STUFF
							(
								  (
								   SELECT ddfh_clause.Alias + '.' + ddfh_clause.ColumnName + ' ' +
										  ddfh_clause.Alias + '.' + ddfh_clause.CoColumn + ' '
								   FROM (
											SELECT DISTINCT so.Alias, 
															si.[ColumnName], 
															so.ObjectTable,
															sh.CoColumn
											FROM dbo.HQWO so
											JOIN dbo.HQWD sd ON sd.TemplateType = so.TemplateType
											JOIN dbo.DDFH sh ON sh.ViewName=so.ObjectTable
											JOIN dbo.DDFI si ON si.Form=sh.Form
											WHERE so.JoinClause IS NULL AND sd.TemplateName = @templatename AND si.FieldType = 2
										) ddfh_clause 
									WHERE ddfh_clause.ObjectTable = w.ObjectTable for xml path('')
								  )
							, 1, 0, '') -- +
						-- Get the first CoColumn
						--(	SELECT TOP 1 ddfh_clause.Alias + '.' + ddfh_clause.CoColumn + ' '
						--	FROM (
						--		SELECT DISTINCT so.Alias, 
						--						si.[ColumnName], 
						--						so.ObjectTable, 
						--						sh.CoColumn
						--		FROM HQWO so
						--		JOIN HQWD sd ON sd.TemplateType = so.TemplateType
						--		JOIN DDFH sh ON sh.ViewName=so.ObjectTable
						--		JOIN DDFI si ON si.Form=sh.Form
						--		WHERE so.JoinClause IS NULL AND sd.TemplateName = @templatename AND si.FieldType = 2
						--	) ddfh_clause 
						--	WHERE ddfh_clause.ObjectTable = w.ObjectTable
						--)
					) as [JoinClause],
					w.[JoinOrder]
			FROM dbo.HQWO w
			INNER JOIN dbo.HQWD d ON d.TemplateType = w.TemplateType
			INNER JOIN dbo.HQDocTemplateResponseField r ON r.TemplateName = d.TemplateName 
			WHERE r.TemplateName=@templatename and r.DocObject = w.DocObject
			
			---- get docobject definition by template name filtered by response field instances
			---- original save ---
			--select distinct d.[TemplateName], w.[DocObject], w.[ObjectTable], w.[Alias], w.[JoinClause], w.[JoinOrder] 
			--from HQWO w
			--inner join HQWD d ON d.TemplateType = w.TemplateType
			--inner join HQDocTemplateResponseField r ON r.TemplateName = d.TemplateName 
			--where r.TemplateName=@templatename and r.DocObject = w.DocObject
			
	END
		
	vspexit:
		RETURN @rcode
END


				





				
				
				
GO
GRANT EXECUTE ON  [dbo].[vspHQGetResponseWOCatalog] TO [public]
GO
