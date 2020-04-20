SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/12/2014
-- Description:	Returns Form and Columns information based on a Datatype
-- =============================================
CREATE FUNCTION [dbo].[mfnFormTableColumnByDatatype] 
(	
	-- Add the parameters for the function here
	@Datatype varchar(255) = 'bTaxCode'
)
RETURNS TABLE 
AS
RETURN 
(
	 --Add the SELECT statement with parameter references here
	--DECLARE @Datatype VARCHAR(255) = 'bTaxCode'

	SELECT 'DEFAULT Form/Column Settings' AS ValueType, h.Form, h.Title, i.ColumnName, i.ComboType, i.Description, h.OrderByClause, i.Seq 
	FROM dbo.DDFH h
	INNER JOIN dbo.DDFI i ON i.Form = h.Form
	WHERE Datatype = @Datatype OR @Datatype IS NULL OR @Datatype = ''
	UNION ALL
	SELECT 'OVERRIDE Form/Column Settings' AS ValueType, hc.Form, hc.Title, ic.ColumnName, ic.ComboType, ic.Description,  hc.OrderByClause, ic.Seq
	FROM vDDFHc hc
	INNER JOIN dbo.vDDFIc ic ON ic.Form = hc.Form
	WHERE Datatype = @Datatype OR @Datatype IS NULL OR @Datatype = ''
	UNION ALL
	SELECT 'OTHER Form/Column Settings' AS ValueType, hs.Form, hs.Title, si.ColumnName, si.ComboType, si.Description,  hs.OrderByClause, si.Seq
	FROM dbo.DDFHShared hs
	INNER JOIN dbo.DDFIShared si ON si.Form = hs.Form
	WHERE Datatype = @Datatype OR @Datatype IS NULL OR @Datatype = ''
	--SELECT 'DEFAULT Form/Column Settings' AS ValueType, h.Form, h.Title, i.ColumnName, i.ComboType, i.Description, h.OrderByClause, i.Seq 
	--FROM dbo.DDFHSharedSingleForm h 
	--INNER JOIN dbo.DDFIShared i ON i.Form = h.Form

)
GO
