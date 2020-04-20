SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Gil Fox>
-- Create date: <02.05.2011>
-- Description:	< This function will return a time with the date removed.
-- You will pass in a small date time and this function will return a
-- a time formatted: hh.mm AM/PM >
-- 
-- =============================================
CREATE FUNCTION [dbo].[vfFormatTime] (@DateTime SMALLDATETIME)

RETURNS NVARCHAR(28)

AS
BEGIN

	---- return empty string if null
	IF @DateTime IS NULL RETURN ''
	---- return empty string if time is 00:00:00
	IF SUBSTRING(CONVERT(CHAR(20), @DateTime),13,5) = '00:00' RETURN ''
	---- takes a small date time input parameter and formats a varchar
	----- formatted to the time. hh:mm AM/PM
	RETURN SUBSTRING(convert(CHAR, @DateTime, 109),13,5) + ' ' + RIGHT(convert(varchar(28), @DateTime, 109),2)

END

GO
GRANT EXECUTE ON  [dbo].[vfFormatTime] TO [public]
GO
