SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Eric Vaterlaus>
-- Create date: <Create Date, ,8/9/2010>
-- Description:	<Description, ,Format address fields into a sigle string with embedded CR LFs.>
-- =============================================
CREATE FUNCTION [dbo].[vfSMAddressFormat]
(
	-- Add the parameters for the function here
	@Address1 varchar(60) = '',
	@Address2 varchar(60) = '',
	@City varchar(20) = '',
	@State varchar(5) = '',
	@Zip varchar(15) = '',
	@Country varchar(2) = ''
)
RETURNS varchar(240)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar varchar(240)

	-- Add the T-SQL statements to compute the return value here
	IF(@Address1 <> '')
	BEGIN
		SELECT @ResultVar = @Address1 + char(13) + char(10)
	END
	IF(@Address2 <> '')
	BEGIN
		SELECT @ResultVar = @ResultVar + @Address2 + char(13) + char(10)
	END
	IF(@City <> '')
	BEGIN
		SELECT @ResultVar = @ResultVar + @City + ', '
	END
	SELECT @ResultVar = @ResultVar + @State
	IF(@Zip <> '')
	BEGIN
		SELECT @ResultVar = @ResultVar + ' ' + @Zip
	END
	IF(@Country <> '')
	BEGIN
		SELECT @ResultVar = @ResultVar + ' ' + @Country
	END

	-- Return the result of the function
	RETURN @ResultVar

END

GO
GRANT EXECUTE ON  [dbo].[vfSMAddressFormat] TO [public]
GO
