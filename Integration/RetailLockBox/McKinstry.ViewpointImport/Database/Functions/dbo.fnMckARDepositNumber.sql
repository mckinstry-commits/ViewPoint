USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[fnMckARDepositNumber]') AND xtype IN (N'FN', N'IF', N'TF'))
	DROP FUNCTION [dbo].[fnMckARDepositNumber]
GO

CREATE FUNCTION [dbo].[fnMckARDepositNumber]
(
     @Company [dbo].[bCompany] = NULL
	 ,@TransactionDate datetime = NULL
	 ,@SourceCode varchar(2) = NULL
)
RETURNS varchar(10)
AS
/*************************************************************************************!
*   Procedure:  fnMckARDepositNumber 
*   Database:   Viewpoint
*   Date:       July 2014
*   Author:		Brian Gannon-McKinley
*   Description: Returns AR deposit number. Format is 'two-digit month' + 'two-digit day' + 
*					'two-digit year' + 'code' + '01' (MMDDYYCC01)
!**************************************************************************************/
BEGIN

DECLARE @ret varchar(10), @MonthDayYearString varchar(8), @Code varchar(2)

-----------------------------------
-- Validate Inputs
-----------------------------------

IF @Company IS NULL SET @Company = 0

IF @TransactionDate IS NULL SET @TransactionDate = GETDATE()

IF @SourceCode IS NULL SET @SourceCode = ''
IF @SourceCode = ''
BEGIN
	SET @SourceCode = 'LB'
END

-----------------------------------
-- Set Values
-----------------------------------

SET @MonthDayYearString = REPLACE(CONVERT(varchar(8), @TransactionDate, 1), '/', '')
SET @Code = UPPER(@SourceCode)

-- Build final string
SET @ret = @MonthDayYearString + @Code + '01'

RETURN @ret
END
      

GO