SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBACOVal]
    /***********************************************************
     * CREATED BY: bc 12/27/99
     * MODIFIED By: bc  08/23/00
     * MODIFIED by: TJL 03/01/01	**** Process only 'E' external type change orders ****
     *              bc  03/21/02 - issue #16732
     *
     * USAGE:
     *   Validates a JB approved changed order against an existing aco in JC that was aprroved prior to the ToDate in JBIN
     *
     * INPUT PARAMETERS
     *   JBCo - JC Company to validate against
     *   Job - Job to validate against
     *   ACO - Approved Change Order to validate
     *   ToDate - ToDate from JBIN
     *
     * OUTPUT PARAMETERS
     *   @msg - error message if error occurs otherwise Description of ACO in JCOH
     * RETURN VALUE
     *   0 - Success
     *   1 - Failure
     *****************************************************/
     @jbco bCompany, @billmth bMonth, @billnum int, @job bJob, @aco bACO, 
     @todate bDate = null, @approvaldate bDate output, @msg varchar(255) output
   
    as
    set nocount on
   
    declare @IntExt char(1), @jcoh_contract bContract, @rcode int, @jbin_contract bContract
    select @rcode = 0
   
    if @jbco is null
    	begin
    	select @msg = 'Missing JB Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @job is null
    	begin
    	select @msg = 'Missing Job!', @rcode = 1
    	goto bspexit
    	end
   
    if @aco is null
    	begin
    	select @msg = 'Missing ACO!', @rcode = 1
    	goto bspexit
    	end
   
    select @msg = Description, @approvaldate = ApprovalDate, @IntExt = IntExt, @jcoh_contract = Contract
    from JCOH
    where JCCo = @jbco and Job = @job and ACO = @aco
   
    if @@rowcount = 0
    	begin
    	select @msg = 'ACO not on file!', @rcode = 1
    	goto bspexit
    	end
   
    if @IntExt <> 'E'
   	begin
   	select @msg = 'ACO not an External type ACO', @rcode = 1
   	goto bspexit
   	end
   
    if @todate is not null and @approvaldate >= @todate
   	begin
   	select @msg = 'Approval date in JC is not prior to the To Date in JB Progress Edit.', @rcode = 1
   	goto bspexit
   	end
   
    select @jbin_contract = Contract
    from bJBIN
    where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
    if @jcoh_contract <> @jbin_contract
   	begin
   	select @msg = 'ACO is not assigned to Contract ' + isnull(@jbin_contract,''), @rcode = 1
   	goto bspexit
   	end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBACOVal] TO [public]
GO
