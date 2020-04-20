SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMGetHQAILookup]
/***********************************************************************
*  Created by: 	CC 03/18/2010
*
*  Altered by: 	
*              	
*              	
*							
* Usage: Gets a subset of DDFI data for the outlook integration to use with its index forms
*
***********************************************************************/
@Sequences VARCHAR(MAX),
@Lookup VARCHAR(150)

AS  
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX);
	
	SET @SQL = 'SELECT  
					s.Seq,
					d.Lookup as Lookup,
					h.Title,
					s.LookupParams,
					s.LookupLoadSeq as LoadSeq,
					''Y'' as StdLookup,
					h.FromClause,
					h.WhereClause,
					h.JoinClause,
					h.OrderByColumn,
					h.GroupByClause    
		FROM dbo.DDFI s (nolock)
		LEFT OUTER JOIN dbo.DDDT d (nolock) on d.Datatype = s.Datatype 
				LEFT OUTER JOIN dbo.DDLH h (nolock) on (h.Lookup = d.Lookup)
		WHERE s.Form = ''HQAttIndex'' 
				AND d.Lookup IS NOT NULL 
				AND s.ActiveLookup = ''Y'' AND s.Seq IN (' +  @Sequences +  ')
				AND d.Lookup = ''' + @Lookup + '''

		UNION 

		SELECT  
			s.Seq, 
			l.Lookup,
			h.Title,
			l.LookupParams,
			l.LoadSeq,
			''N'' as StdLookup,
			h.FromClause,
			h.WhereClause,
			h.JoinClause,
			h.OrderByColumn,
			h.GroupByClause
		FROM dbo.DDFI s (nolock)
		INNER JOIN dbo.DDFL l (nolock) on s.Form = l.Form and s.Seq = l.Seq
		LEFT OUTER JOIN dbo.DDLH h (nolock) on h.Lookup = l.Lookup
		WHERE	s.Form = ''HQAttIndex'' 
				AND s.Seq IN (' +  @Sequences +  ')
				AND l.Lookup = ''' + @Lookup + '''';
		
	EXEC(@SQL);
END
GO
GRANT EXECUTE ON  [dbo].[vspDMGetHQAILookup] TO [public]
GO
