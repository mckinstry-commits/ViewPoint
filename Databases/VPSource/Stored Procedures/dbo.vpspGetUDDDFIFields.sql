SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Chris G
-- Create date: 8/29/12
-- Description:	Returns all the DDFI fields associated
--				with the V6 form for the given view/column.
-- =============================================
CREATE PROCEDURE [dbo].[vpspGetUDDDFIFields] 
	(@view VARCHAR(128), @columnName VARCHAR(128))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @form VARCHAR(30)	
  
	SELECT @form = [Form]
	  FROM DDFIc
     WHERE ViewName = @view
	   AND ColumnName = @columnName
	  
	SELECT Seq
	      ,ColumnName
	  FROM DDFIShared
     WHERE [Form] = @form
       AND ColumnName IS NOT NULL
END
GO
GRANT EXECUTE ON  [dbo].[vpspGetUDDDFIFields] TO [VCSPortal]
GO
