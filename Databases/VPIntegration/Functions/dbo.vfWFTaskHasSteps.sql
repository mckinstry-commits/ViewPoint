SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Charles Courchaine
-- Create date: 12/19/2007
-- Description:	This functions returns Y for tasks that have associated step records
-- =============================================
CREATE FUNCTION [dbo].[vfWFTaskHasSteps] 
(
	-- Add the parameters for the function here
	@Checklist varchar(20),
	@Task int,
	@Company bCompany
)
RETURNS bYN
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(1)
	set @Result =''	
	-- Add the T-SQL statements to compute the return value here
	if exists(select * from WFChecklistSteps where Task = @Task and Checklist = @Checklist and Company = @Company)
		SELECT @Result = 'Y'
	else
		SELECT @Result = 'N'
	-- Return the result of the function
	RETURN @Result

END

GO
GRANT EXECUTE ON  [dbo].[vfWFTaskHasSteps] TO [public]
GO
