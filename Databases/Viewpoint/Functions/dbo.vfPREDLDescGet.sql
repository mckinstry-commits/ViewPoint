SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		EN (based on Mark Holcomb's vfCanadaT4DescGet)
-- Create date: 1/10/2011
-- Description:	Returns an EDLCode Description from PREC
--				or PRDL depending on type parameter.
-- =============================================
create FUNCTION [dbo].[vfPREDLDescGet]
(
	-- Add the parameters for the function here
	@prco bCompany, @type char(1), @code bEDLCode
)
RETURNS bDesc
AS
BEGIN
	-- Declare the return variable here
	declare @codedesc bDesc

	-- Add the T-SQL statements to compute the return value here
	if @type = 'E'
	begin
		select @codedesc = [Description] from PREC where PRCo = @prco and EarnCode = @code
	end
	else
	begin
		select @codedesc = [Description] from PRDL where PRCo = @prco and DLCode = @code and DLType = @type
	end
	

	-- Return the result of the function
	return @codedesc

END


GO
GRANT EXECUTE ON  [dbo].[vfPREDLDescGet] TO [public]
GO
