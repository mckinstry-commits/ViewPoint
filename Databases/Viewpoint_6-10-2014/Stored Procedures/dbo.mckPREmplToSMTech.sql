SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 12/30/2013
-- Description:	Procedure to Copy PR Employees to SM Technicians
-- =============================================
CREATE PROCEDURE [dbo].[mckPREmplToSMTech] 
	-- Add the parameters for the stored procedure here
	@PRCo TINYINT,
	@Employee bEmployee = 0
	,@rcode INT, @ReturnMessage varchar(255) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;

	DECLARE --@LastName char(5) = '     ',
	@Technician VARCHAR(30) = NULL

	SELECT --@LastName = LastName, 
		@Technician = SortName
	FROM dbo.PREHName 
	WHERE @PRCo = PRCo AND @Employee = Employee

    -- Insert statements for procedure here
	--IF @LastName IS NULL
	--BEGIN 
	--	SELECT @ReturnMessage = 'Employee does not exist', @rcode = 1
	--	GOTO spexit
	--END
	--ELSE
	BEGIN
		INSERT INTO dbo.SMTechnician
		        ( SMCo ,
		          Technician ,
		          PRCo ,
		          Employee ,
		          Rate ,
		          INCo ,
		          INLocation ,
		          Notes ,
		          UniqueAttchID ,
		          Monday ,
		          MondayWorkStart ,
		          MondayWorkEnd ,
		          MondayBreakStart ,
		          MondayBreakEnd ,
		          Tuesday ,
		          TuesdayWorkStart ,
		          TuesdayWorkEnd ,
		          TuesdayBreakStart ,
		          TuesdayBreakEnd ,
		          Wednesday ,
		          WednesdayWorkStart ,
		          WednesdayWorkEnd ,
		          WednesdayBreakStart ,
		          WednesdayBreakEnd ,
		          Thursday ,
		          ThursdayWorkStart ,
		          ThursdayWorkEnd ,
		          ThursdayBreakStart ,
		          ThursdayBreakEnd ,
		          Friday ,
		          FridayWorkStart ,
		          FridayWorkEnd ,
		          FridayBreakStart ,
		          FridayBreakEnd ,
		          Saturday ,
		          SaturdayWorkStart ,
		          SaturdayWorkEnd ,
		          SaturdayBreakStart ,
		          SaturdayBreakEnd ,
		          Sunday ,
		          SundayWorkStart ,
		          SundayWorkEnd ,
		          SundayBreakStart ,
		          SundayBreakEnd
		        )
		VALUES  ( 101 , -- SMCo - bCompany  WILL NEED TO CHANGE TO SM Company 1 when live.
		          @Technician , -- Technician - varchar(15)
		          @PRCo , -- PRCo - bCompany
		          @Employee , -- Employee - bEmployee
		          NULL , -- Rate - bUnitCost
		          NULL , -- INCo - bCompany
		          NULL , -- INLocation - bLoc
		          'Copied Employee data from PREHName' , -- Notes - varchar(max)
		          NULL , -- UniqueAttchID - uniqueidentifier
		          'N' , -- Monday - bYN
		          NULL , -- MondayWorkStart - datetime
		          NULL , -- MondayWorkEnd - datetime
		          NULL , -- MondayBreakStart - datetime
		          NULL , -- MondayBreakEnd - datetime
		          'N' , -- Tuesday - bYN
		          NULL , -- TuesdayWorkStart - datetime
		          NULL , -- TuesdayWorkEnd - datetime
		          NULL , -- TuesdayBreakStart - datetime
		          NULL , -- TuesdayBreakEnd - datetime
		          'N' , -- Wednesday - bYN
		          NULL , -- WednesdayWorkStart - datetime
		          NULL , -- WednesdayWorkEnd - datetime
		          NULL , -- WednesdayBreakStart - datetime
		          NULL , -- WednesdayBreakEnd - datetime
		          'N' , -- Thursday - bYN
		          NULL , -- ThursdayWorkStart - datetime
		          NULL , -- ThursdayWorkEnd - datetime
		          NULL , -- ThursdayBreakStart - datetime
		          NULL , -- ThursdayBreakEnd - datetime
		          'N' , -- Friday - bYN
		          NULL , -- FridayWorkStart - datetime
		          NULL , -- FridayWorkEnd - datetime
		          NULL , -- FridayBreakStart - datetime
		          NULL , -- FridayBreakEnd - datetime
		          'N' , -- Saturday - bYN
		          NULL , -- SaturdayWorkStart - datetime
		          NULL , -- SaturdayWorkEnd - datetime
		          NULL , -- SaturdayBreakStart - datetime
		          NULL , -- SaturdayBreakEnd - datetime
		          'N' , -- Sunday - bYN
		          NULL , -- SundayWorkStart - datetime
		          NULL , -- SundayWorkEnd - datetime
		          NULL , -- SundayBreakStart - datetime
		          NULL  -- SundayBreakEnd - datetime
		        )
		SELECT @ReturnMessage = 'Employee successfully copied to SM Technicians.', @rcode = 0
	END

	

	spexit:
	RETURN @rcode

END
GO
