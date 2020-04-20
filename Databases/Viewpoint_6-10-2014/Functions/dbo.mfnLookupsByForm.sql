SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/12/2014
-- Description:	Function to return default and custom lookups based on a form name.  Pass a null or empty string for all.
-- =============================================
CREATE FUNCTION [dbo].[mfnLookupsByForm] 
(	
	-- Add the parameters for the function here
	@Form varchar(255)
)
RETURNS TABLE 
AS
RETURN 
(
	
	-- Add the SELECT statement with parameter references here
	SELECT 'DEFAULT' AS Type, l1.Form, l1.LoadSeq, l1.Lookup, l1.LookupParams, l1.Seq, ISNULL((SELECT Active FROM dbo.vDDFLc WHERE l1.Form = Form AND l1.Seq = Seq AND l1.LoadSeq = LoadSeq),'Y') AS [Active]
	FROM dbo.DDFL l1
	WHERE Form = @Form OR @Form IS NULL OR @Form = ''
	UNION ALL
	SELECT 'CUSTOM' AS TYPE, l2.Form, l2.LoadSeq, l2.Lookup, l2.LookupParams, l2.Seq, l2.Active 
	FROM dbo.vDDFLc l2
	WHERE Form = @Form OR @Form IS NULL OR @Form = ''
)
GO
