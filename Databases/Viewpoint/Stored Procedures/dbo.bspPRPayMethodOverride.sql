SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPayMethodOverride    Script Date: 12/06/01 9:36:34 AM ******/
    CREATE    procedure [dbo].[bspPRPayMethodOverride]
    /****************************************************************
     * CREATED BY: EN 12/06/01
     * MODIFIED BY: EN 10/8/02 - issue 18877 change double quotes to single
     *
     * USAGE:
     * This procedure is used by the PRPayMethodOverride to change
     * one pay method to another for all bPRSQ entries for a specific
     * pay sequence in a pay period.
     *
     * Entries which have been paid (i.e. CMRef is not null and CMRef <> ''
     * will not be changed.
     *
     *
     * INPUT PARAMETERS
     *   @co        	PR Co
     *   @prgroup		PR Group
     *   @prenddate	Payroll Period Ending Date
     *   @payseq		Payment Sequence
     *   @frommethod	Payment Method to change from
     *   @tomethod		Payment Method to change to
     *
     * OUTPUT PARAMETERS
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
     ****************************************************************/
   
    	@co bCompany, @prgroup bGroup, @prenddate bDate, @payseq tinyint, 
   	@frommethod char(1), @tomethod char(1), @errmsg varchar(200) output
   
    as
    set nocount on
    declare @rcode int, @employee bEmployee, @count smallint, @opencursor tinyint,
   	@chktype char(1)
   
    select @rcode = 0, @count=0
   
    -- set open cursor flags to false
    select @opencursor = 0
   
    -- validate pay period sequence
    if (select count(*) from bPRPS where PRCo=@co and PRGroup=@prgroup and PREndDate=@prenddate and PaySeq=@payseq)=0
   	begin
   	select @errmsg = 'Invalid pay period/sequence - did not update.', @rcode=1
   	goto bspexit
   	end	
   
    -- set check type (if pay method is 'C', check type is 'C' / if method is 'E', type is null
    if @tomethod = 'C'
   	select @chktype = 'C'
    else
   	select @chktype = null
   
    begin transaction
   
    -- declare cursor
    declare bcPRSQ cursor for select Employee from bPRSQ 
    where PRCo=@co and PRGroup=@prgroup and PREndDate=@prenddate and PaySeq=@payseq 
   	and PayMethod=@frommethod and (CMRef is null or CMRef = '')
   
    -- open cursor
    open bcPRSQ
   
    -- set open cursor flag to true
    select @opencursor = 1
   
    -- loop through all rows in PRSQ and update method
    prsq_loop:
    -- get row from PRSQ
    fetch next from bcPRSQ into @employee
   
    if @@fetch_status <> 0
       goto prsq_end
   
    update bPRSQ
    set PayMethod = @tomethod, ChkType = @chktype
    where PRCo=@co and PRGroup=@prgroup and PREndDate=@prenddate and Employee=@employee and PaySeq=@payseq 
    if @@rowcount <> 1
    	begin
    	select @errmsg = 'Unable to update payment method for employee ' + convert(varchar,@employee) + ' - did not update!', @rcode = 1
   	rollback transaction
    	goto bspexit
    	end
   
    select @count = @count + 1
    goto prsq_loop
   
    prsq_end:
    commit transaction
   
    if @count=0
    	begin
       select @errmsg='No matching entries were found to change.'
    	end
    else
    	begin
    	select @errmsg=convert(varchar(6),@count) + ' entries have been added to this batch.'
    	end
   
   
    bspexit:
   
    if @opencursor = 1
    		begin
    		close bcPRSQ
    		deallocate bcPRSQ
    		end
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPayMethodOverride] TO [public]
GO
