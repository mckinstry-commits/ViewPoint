SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 2/14/2014
-- Description:	Function to return table, form and columns that use a certain data type.
-- =============================================
CREATE FUNCTION [dbo].[mfnColumnsByDatatype] 
(	
	-- Add the parameters for the function here
	@DataType VARCHAR(255) 
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT DDFI.Form, Seq, dbo.DDFH.ViewName, ColumnName, Description, DDFH.Title , ValProc
	FROM DDFI
		INNER JOIN DDFH ON dbo.DDFH.Form = dbo.DDFI.Form
	WHERE Datatype = @DataType
UNION
	SELECT DDFIc.Form,  Seq, dbo.vDDFHc.ViewName, ColumnName, Description, vDDFHc.Title, ValProc
	FROM dbo.DDFIc
		LEFT OUTER JOIN dbo.vDDFHc ON dbo.vDDFHc.Form = dbo.DDFIc.Form 
	WHERE Datatype = @DataType
)
GO
