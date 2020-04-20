SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAddAllEarnings    Script Date: 8/28/99 9:35:28 AM ******/
   CREATE    procedure [dbo].[bspPRAddAllEarnings]
/***********************************************************
* CREATED BY:	GG 02/05/98
* MODIFIED By:	EN 10/7/02		- issue 18877 change double quotes to single
*				CHS 10/15/2010	- #140541 - change bPRDB.EarnCode to EDLCode
*				CHS 10/19/2010	- #140541 - added DL codes to insert
*
* USAGE:
* Called by PR Dedn/Liab maintenance form to initlaize all
* earnings codes as subject to the current deduction/liability.
*
* INPUT PARAMETERS
*   PRCo    	PR Company
*   DLCode	Deduction/liability code to initialize
* OUTPUT PARAMETERS
*   @msg      error message if falure
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
   
(@prco bCompany = null, @dlcode bEDLCode = null,  @msg varchar(60) output)
as

set nocount on

declare @rcode int

select @rcode = 0

if @prco is null
begin
	select @msg = 'Missing PR Company!', @rcode = 1
	goto bspexit
end

if @dlcode is null
begin
	select @msg = 'Missing Dedn/Liab Code!', @rcode = 1
	goto bspexit
end

insert bPRDB (PRCo, DLCode, EDLType, EDLCode, SubjectOnly)
select distinct PRCo = @prco, DLCode = @dlcode, 'E', EarnCode, SubjectOnly = 'N' from bPREC
where PRCo=@prco and EarnCode not in(select EDLCode from bPRDB where PRCo = @prco and DLCode = @dlcode and EDLType = 'E')
   	
IF EXISTS(SELECT TOP 1 1 FROM bPRDL WHERE PRCo=@prco AND DLCode=@dlcode AND CalcCategory in ('F', 'S', 'L') AND Method IN ('G', 'R'))
BEGIN
	INSERT bPRDB (PRCo, DLCode, EDLType, EDLCode, SubjectOnly)
	SELECT DISTINCT PRCo = @prco, DLCode = @dlcode, DLType, DLCode, SubjectOnly = 'N' FROM bPRDL
	WHERE PRCo=@prco AND PreTax='Y' AND DLCode <> @dlcode AND DLCode not in (select EDLCode from bPRDB where PRCo = @prco and DLCode = @dlcode AND EDLType = 'D')

END
   
   
bspexit:

RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAddAllEarnings] TO [public]
GO
