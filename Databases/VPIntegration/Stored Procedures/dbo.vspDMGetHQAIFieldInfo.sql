SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMGetHQAIFieldInfo]
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
@Sequences VARCHAR(MAX)

AS  
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @SQL NVARCHAR(MAX);
	
	SET @SQL = 'SELECT	DDFI.Seq, 
		ColumnName, 
		ISNULL(DDFI.InputType, DDDTShared.InputType) AS InputType, 
		ISNULL(DDFI.InputLength, DDDTShared.InputLength) AS InputLength, 
		COALESCE(DDFI.InputMask, DDDTShared.InputMask,'''') AS InputMask, 
		COALESCE(DDFI.Prec, DDDTShared.Prec,0) AS Prec, 
		CASE WHEN DDFL.Lookup IS NULL AND DDFI.ActiveLookup = ''N'' THEN 0 ELSE 1 END AS HasLookup
	FROM DDFI 
	LEFT OUTER JOIN DDFL ON dbo.DDFI.Form = dbo.DDFL.Form AND dbo.DDFI.Seq = dbo.DDFL.Seq
	LEFT OUTER JOIN dbo.DDDTShared (nolock) on  DDFI.Datatype = DDDTShared.Datatype    
	WHERE DDFI.Form = ''HQAttIndex'' AND DDFI.Seq IN (' +  @Sequences +  ')';
	
	EXEC(@SQL);
		
	SET @SQL = 'SELECT  s.Seq,
		d.Lookup as [Lookup],
		ISNULL(s.LookupParams, '''') AS LookupParams
		FROM dbo.DDFI s (nolock)
		LEFT OUTER JOIN dbo.DDDT d (nolock) on d.Datatype = s.Datatype 
				LEFT OUTER JOIN dbo.DDLH h (nolock) on (h.Lookup = d.Lookup)
		WHERE s.Form = ''HQAttIndex'' AND d.Lookup IS NOT NULL AND s.ActiveLookup = ''Y'' AND s.Seq IN (' +  @Sequences +  ')

		UNION 

		SELECT  s.Seq,
				l.Lookup as [Lookup],
				ISNULL(l.LookupParams, '''') AS LookupParams
		FROM dbo.DDFI s (nolock)
		INNER JOIN dbo.DDFL l (nolock) on s.Form = l.Form and s.Seq = l.Seq
		LEFT OUTER JOIN dbo.DDLH h (nolock) on h.Lookup = l.Lookup
		WHERE s.Form = ''HQAttIndex'' AND s.Seq IN (' +  @Sequences +  ')';
		
	EXEC(@SQL);
	
END
GO
GRANT EXECUTE ON  [dbo].[vspDMGetHQAIFieldInfo] TO [public]
GO
