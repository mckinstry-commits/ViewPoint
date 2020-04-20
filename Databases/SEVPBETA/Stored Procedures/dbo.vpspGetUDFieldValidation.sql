SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Chris G
-- Create date: 8/29/12
-- Description:	Returns the validation information
--				for a UD field from DDFIc.
-- =============================================
CREATE PROCEDURE [dbo].[vpspGetUDFieldValidation] 
	(@view VARCHAR(128), @columnName VARCHAR(128))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT InputMask
		  ,ValProc
	      ,ValParams
	  	  ,MinValue
		  ,MaxValue
		  ,ValExpression
		  ,ValExpError
	  FROM DDFIc
	 WHERE ViewName = @view
	   AND ColumnName = @columnName	  
END
GO
GRANT EXECUTE ON  [dbo].[vpspGetUDFieldValidation] TO [VCSPortal]
GO
