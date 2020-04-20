SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                  procedure [dbo].[bspPREDSeqOrderVal]
    /***********************************************************
     * CREATED BY: 	EN  3/01/04
     * MODIFIED BY: 
     *
     * USAGE:
     * Called from PR Employe D/L Entry.
     * Checks PRED processing seq #'s and garnishment allocation groups
     * set up for an employee against the processing seq and/or allocation
     * group being modified to make sure the order is correct for
     * payroll processing.
     *
     * INPUT PARAMETERS
     *   @prco	    PR Company
     *   @employee	Employee to process
     *	  @dlcode 	DL Code being modified
     *	  @procseq	Procession sequence
     *   @allocgrp Garnishment Allocation Group
     *
     * OUTPUT PARAMETERS
     *   @errmsg  	Error message if something went wrong
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
    	@prco bCompany, @employee bEmployee, @dlcode bEDLCode, @procseq tinyint, 
   	@allocgrp bGroup, @errmsg varchar(255) output
    
    as
    set nocount on
    
    declare @rcode int, @numrows int
   
    declare @PREDAllocDLs table (ProcessSeq tinyint, DLCode smallint, CSAllocGroup tinyint)
   
    select @rcode = 0
    
    if @prco is null
   	begin
   	select @errmsg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
    if @employee is null
   	begin
   	select @errmsg = 'Missing Employee!', @rcode = 1
   	goto bspexit
   	end
   
    -- set up data to check in table variable: should include PRED rows with updated info in the row specified
    insert @PREDAllocDLs
    select ProcessSeq, DLCode, CSAllocGroup from dbo.PRED with (nolock)
    where PRCo=@prco and Employee=@employee and DLCode<>@dlcode and CSAllocYN='Y' and CSAllocGroup is not null
   
    insert @PREDAllocDLs (ProcessSeq, DLCode, CSAllocGroup)	values (@procseq, @dlcode, @allocgrp)
   
    -- if allocation groups are set up for employee, make sure they are in ascending order when PRED entries 
    -- are arranged in ProcessSeq/DLCode order
    if exists (select * from dbo.PRED e with (nolock)
   			where e.PRCo = @prco and e.Employee = @employee and e.CSAllocYN = 'Y' and
   			e.CSAllocGroup is not null)
   	begin
   	select @numrows = count(*) from @PREDAllocDLs e
   	where (select count(*) from dbo.PRED ed with (nolock) 
   				where ed.PRCo = @prco and ed.Employee = @employee and ed.CSAllocYN = 'Y' and
					((ed.CSAllocGroup > e.CSAllocGroup and isnull(str(ed.ProcessSeq, 3), '   ') < isnull(str(e.ProcessSeq, 3), '   '))
					or (ed.CSAllocGroup < e.CSAllocGroup and isnull(str(ed.ProcessSeq,3), '   ') > isnull(str(e.ProcessSeq, 3), '   ')))
					) > 0

   	if @numrows > 0
   		begin
   		select @errmsg= 'Processing sequences and Garnishment Allocations Groups out of order', @rcode=1
   		goto bspexit
   		end
   	end
   
   
    bspexit:
    
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREDSeqOrderVal] TO [public]
GO
