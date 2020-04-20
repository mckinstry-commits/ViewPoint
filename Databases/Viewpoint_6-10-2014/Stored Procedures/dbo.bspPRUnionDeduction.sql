SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRUnionDeduction]
      /********************************************************
      * CREATED BY: 	AW 9/20/07 ISSUE #125597 & #125598
      * MODIFIED BY:	
      *
      * USAGE:
      * 	Calculates Union Dues Specific to Griffith Company
      *
      * INPUT PARAMETERS:
      * @prco 
      * @prgroup 
      * @prendate
      * @employee
      * @payseq
      * @cacraft Craft
      * @class
      * @dlcode
      * @dltype
      *	@calcbasis 	calculated earnings
      * @rate = miscAmt1
      *
      * OUTPUT PARAMETERS:
      *	@amt		calculated tax amount
      *	@msg		error message if failure
      *
      * RETURN VALUE:
      * 0 	    	success
      *	1 		failure
      **********************************************************/
     (@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
   	  @cacraft bCraft, @class bClass, @rate bUnitCost, @calcbasis bDollar = 0, 
      @amt bDollar = 0 output, @eligamt bDollar = 0 output, @msg varchar(255) = null output)
      as
      set nocount on

    declare @rcode int, @prevdlcode bEDLCode, @prevdltype char(1), @prevamount bDollar
    set @rcode = 0
    set @prevdlcode=56
    set @prevdltype='D'
    set @prevamount = 0


-- select the amount calculated by @prevdlcode
        select @prevamount=Amt 
            from bPRCA 
        where PRCo=@prco and PRGroup=@prgroup and PREndDate=@prenddate and
        Employee=@employee and PaySeq=@payseq and Craft=@cacraft and 
        Class=@class and EDLCode=@prevdlcode and EDLType=@prevdltype
    if @@rowcount<>1
    begin
      select @rcode=1, @msg = 'bspPRUnionDeduction: unable to determine amount for dlcode '+convert(varchar(6),@prevdlcode)
      goto bspexit
    end

-- subtract amount from @calcbasis
    select @eligamt = (@calcbasis - @prevamount)
    select @amt = @eligamt * @rate

      bspexit:
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUnionDeduction] TO [public]
GO
