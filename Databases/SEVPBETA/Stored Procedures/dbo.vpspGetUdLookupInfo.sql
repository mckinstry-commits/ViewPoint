SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ken E / Chris G
-- Create date: 9/18/2012
-- Description:	Gets the lookup information for a 
--				ud field in connects
-- =============================================
CREATE PROCEDURE [dbo].[vpspGetUdLookupInfo] 
	(@viewName varchar(30),
	 @columnName varchar(500))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT TOP 1 b.[Lookup], b.LookupParams,
    c.FromClause, c.WhereClause, c.JoinClause,
    c.OrderByColumn, c.GroupByClause
	FROM [dbo].[vDDFIc] a
	JOIN [dbo].[vDDFLc] b 
	on a.Form = b.Form and a.Seq = b.Seq and b.Active = 'Y'
	JOIN [dbo].[DDLHShared] c
	on b.[Lookup] = c.[Lookup]
	Where a.ViewName=@viewName and a.ColumnName=@columnName
	Order By b.LoadSeq
	
END
GO
GRANT EXECUTE ON  [dbo].[vpspGetUdLookupInfo] TO [VCSPortal]
GO
