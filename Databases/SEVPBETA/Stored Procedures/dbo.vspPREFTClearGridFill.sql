SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspPREFTClearGridFill]
  
  /***********************************************************
   * CREATED BY: MV 05/14/07
   * MODIFIED By : 
   *
   * Usage:
   *	Used by PREFT to get paid seq to fill clear grid 
   *
   * Input params:
   *	@prco		Company
   *	@prgroup	PR Group
   *	@preenddate	PREndDate
   *	@cmref		CMRef
   *
   * Output params:
   *	@msg		error message
   *
   * Return code:
   *	0 = success, 1 = failure
   *****************************************************/
  (@prco bCompany ,@prgroup bGroup ,@prenddate bDate, @cmref bCMRef = null, @msg varchar(255)=null output)

  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  /* check required input params */
  if @prco is null
  	begin
  	select @prco = 'Missing Company.', @rcode = 1
  	goto bspexit
  	end
  
  if @prgroup is null
  	begin
  	select @msg = 'Missing PR Group.', @rcode = 1
  	goto bspexit
  	end

 if @prenddate is null
  	begin
  	select @msg = 'Missing PR End Date.', @rcode = 1
  	goto bspexit
  	end
  
 select 'Employee#' = e.Employee, 'Name' = isnull(e.LastName,'') + ', ' + isnull(e.FirstName,'') + ' ' + 
		isnull(e.MidName,'') + ' ' + isnull(e.Suffix,''), 'Pay Seq' = s.PaySeq, 'CMRef#' = s.CMRef,'EFT Seq#'= s.EFTSeq
		FROM PRSQ s join PREH e on s.PRCo = e.PRCo and s.Employee = e.Employee 
        WHERE s.PRCo = @prco AND s.PRGroup = @prgroup AND s.PREndDate = @prenddate
        AND s.PayMethod = 'E' AND (s.CMRef IS NOT NULL and s.CMRef=isnull(@cmref,s.CMRef))
		ORDER BY s.CMRef

	  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPREFTClearGridFill] TO [public]
GO
