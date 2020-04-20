SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAddAllDLs    Script Date: 8/28/99 9:35:28 AM ******/
   CREATE    procedure [dbo].[bspPRAddAllDLs]
   /***********************************************************
    * CREATED BY:	EN 8/5/08
    * MODIFIED By:	CHS 10/15/2010	- #140541 - change bPRDB.EarnCode to EDLCode
    *
    * USAGE:
    * Called by PR Earnings maintenance form to initialize all
    * deduction and liability codes as subject to the current earnings code.
    *
    * INPUT PARAMETERS
    *   PRCo    	PR Company
    *   EarnCode	Earnings code to initialize
    * OUTPUT PARAMETERS
    *   @msg      error message if falure
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = null, @earncode bEDLCode = null,  @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @earncode is null
   	begin
   	select @msg = 'Missing Earnings Code!', @rcode = 1
   	goto bspexit
   	end
   
   insert bPRDB (PRCo, DLCode, EDLCode, SubjectOnly)
   select distinct PRCo = @prco, DLCode, EarnCode = @earncode, SubjectOnly = 'N' from bPRDL
   	where PRCo=@prco and DLCode not in(select DLCode from bPRDB where PRCo = @prco and EDLCode = @earncode)
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAddAllDLs] TO [public]
GO
