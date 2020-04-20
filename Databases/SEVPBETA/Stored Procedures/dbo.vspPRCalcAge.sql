SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRCalcAge    Script Date: 5/20/05 9:32:34 AM ******/
CREATE  proc [dbo].[vspPRCalcAge]
/***********************************************************
* CREATED BY	: EN 5/20/05
* MODIFIED BY	: EN 3/19/08 #127420  modified age computation code to something more concise
*
* USED IN: PREmpl to compute employee's age from birthdate
*
* INPUT PARAMETERS
*	@birthdate	employee's birthdate
*
* OUTPUT PARAMETERS
*   @msg      string describing employee's age
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/

(@birthdate bDate, @msg varchar(255) output)
as

set nocount on

declare @rcode int, @today smalldatetime, @age int

select @rcode = 0

select @age = floor(datediff(day, @birthdate, getdate()) / 365.25)

---- New code that will correct Issue #140204
--SET @age = YEAR(GETDATE()) - YEAR(@birthdate)  
 
---- If the birthday has not yet arrived this year we subtract 1  
--IF (MONTH(GETDATE()) < MONTH(@birthdate)) OR (MONTH(GETDATE()) = MONTH(@birthdate) AND DAY(GETDATE()) < DAY(@birthdate))    
--SET @age = @age - 1  
---- End New code for Issue #140204

select @msg = 'Age ' + convert(varchar,@age) + ' years'

bspexit:

	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRCalcAge] TO [public]
GO
