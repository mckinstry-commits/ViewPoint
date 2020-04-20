SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[JulianDate]
	(@Date		SMALLDATETIME)
	 RETURNS	VARCHAR(30) WITH SCHEMABINDING
/****************************************************************
* Author:		VCS Tech Services Jake Fisher
* Create Date:	08/06/2013
* Description:	Project VU8085 - Returns the Julian date.  The number of days since 1990-01-01.
****************************************************************/
AS BEGIN
	RETURN 
	RIGHT('00' + CAST(YEAR(@Date) AS CHAR(4)),2) + RIGHT('000' + CAST(DATEPART(dy, @Date) AS varchar(3)),3)
END

GO
