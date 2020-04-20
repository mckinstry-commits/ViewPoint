SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMPRTB_PRENDDATE    Script Date: 10/16/2002 10:28:16 AM ******/
   /****** Object:  Stored Procedure dbo.bspIMPRTB_PRENDDATE    Script Date: 8/28/99 9:34:28 AM ******/
   CREATE proc [dbo].[bspIMPRTB_PRENDDATE]
    /********************************************************
    * CREATED BY: 	DANF 05/16/00
    * MODIFIED BY:  mh 10/16/02.  Not using 'Top'.  It returns the
    * 								the first or lowest open PREndDate.
    *								Need the most recent.
    *
    * USAGE:
    * 	Retrieves PR END DATE FROM PRCT
    *
    * INPUT PARAMETERS:
    *	PR Company
    *   PR Group
    *
    * OUTPUT PARAMETERS:
    *	PRENDDATE from bPRPC
    *	Error Message, if one
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
    *
    **********************************************************/
    
    (@prco bCompany = 0, @prgroup bGroup, @prenddate bDate output, @msg varchar(60) output) as
    set nocount on
    declare @rcode int
    select @rcode = 0
    
    select @msg = ''
   
    if @prco = 0
    	begin
    	select @msg = 'Missing PR Company#!', @rcode = 1
    	goto bspexit
    	end
    
    if @prgroup is null
    	begin
    	select @msg = 'Missing PR group!', @rcode = 1
    	goto bspexit
    	end
   /* 
    select TOP 1 @prenddate = PREndDate
    from bPRPC
    where PRCo = @prco and PRGroup = @prgroup and Status = 0
    Order By PRCo, PRGroup, PREndDate
   */
    
    select @prenddate = Max(PREndDate)
    from bPRPC
    where PRCo = @prco and PRGroup = @prgroup and Status = 0
   
   
    bspexit:
    	if @rcode<>0 select @msg=isnull(@msg,'Payroll End Date') + char(13) + char(10) + '[bspIMPRTB_PRENDDATE]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMPRTB_PRENDDATE] TO [public]
GO
