SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAULookup    Script Date: 8/28/99 9:35:27 AM ******/
   CREATE   proc [dbo].[bspPRAULookup]
   (@prco bCompany, @leavecode bLeaveCode, @earncode bEDLCode,
   	@autype varchar(1), @basis varchar(1) output,
   	@rate bUnitCost output,	@msg varchar(60) output)
   /***********************************************************
   
    * CREATED BY: EN 12/10/97
    * MODIFIED By : EN 6/8/98
    *				EN 10/7/02 - issue 18877 change double quotes to single
    *
    * Usage:
    *	First validates earnings code and gets the description from PREC.
    *	Then looks up the defaults for Type, Basis and Rate in PRAU to be
    *	used as return parameters.
    *	If no defaults are found, only the description is returned.
    *
    * Input params:
    *	@prco		PR company
    *	@leavecode	Leave Code
    *	@earncode	Earnings Code
    *	@autype		AU Type
    *
    * Output params:
    *	@basis		default basis (if found)
    *	@rate		default rate (if found)
    *	@msg		Earnings code description or error message
    *
    * Return code:
    *	0 = success, 1 = failure, 5 = entry not found
    ************************************************************/
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   /* check required input params */
   if @leavecode is null
   	begin
   	select @msg = 'Missing Leave Code.', @rcode = 1
   	goto bspexit
   	end
   if not exists(select * from PRLV where PRCo=@prco and LeaveCode=@leavecode)
   	begin
   	select @msg = 'Invalid Leave Code.', @rcode = 1
   	goto bspexit
   	end
   
   if @earncode is null
   	begin
   	select @msg = 'Missing Earnings Code.', @rcode = 1
   	goto bspexit
   	end
   if @autype is null
   	begin
   	select @msg = 'Missing Accrual/Usage Type.', @rcode = 1
   	goto bspexit
   	end
   
   /* look up PRAU defaults */
   select @basis=Basis, @rate=Rate from bPRAU
   	where PRCo=@prco and LeaveCode=@leavecode and EarnCode=@earncode and Type=@autype
   if @@rowcount=0	select @basis=null, @rate=0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAULookup] TO [public]
GO
