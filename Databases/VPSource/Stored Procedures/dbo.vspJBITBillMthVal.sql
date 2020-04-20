SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspJBITBillMthVal]
    /***********************************************************
     * CREATED BY: DC 6/14/07
     * MODIFIED By :  DC #127792 - SQL failure error when adding a subcontract 
	*							previously deleted from worksheet
	*					GF 06/25/2010 - expanded SL to varchar(30)
     *
     * USAGE:
     * validates the billing month entered in SLWorksheetAdd 
     *
     * INPUT PARAMETERS
     *   Co				JB Co to validate against
     *   SubContract	Contract for bill
	 *	 JCCo			JC Co for subcontract
	 *   Job			Job for Subcontract
     *   Bill Month		Contract Item for bill
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of Contract
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
   
    	(@slco bCompany = 0, @sl VARCHAR(30), @jcco bCompany, @job bJob, 
		@billmth bMonth, @msg varchar(255) output)
   
    as
    set nocount on
   
    declare @rcode int, @slitem bItem, @phasegroup bGroup,
        	@phase bPhase, @contractitem bContractItem, @contract bContract

    select @rcode = 0
   
   
    if @slco is null
    	begin
    	select @msg = 'Missing SL Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @sl is null
    	begin
    	select @msg = 'Missing Contract!', @rcode = 1
    	goto bspexit
    	end
   
    if @jcco is null
    	begin
    	select @msg = 'Missing JC Company!', @rcode = 1
    	goto bspexit
    	end

    if @job is null
    	begin
    	select @msg = 'Missing JC Job!', @rcode = 1
    	goto bspexit
    	end

    if @billmth is null
    	begin
    	select @msg = 'Missing Contract item!', @rcode = 1
    	goto bspexit
    	end

     -- use a cursor to validate SL
     declare bcSLIT CURSOR LOCAL FAST_FORWARD for  --DC #127792
     	select SLItem, PhaseGroup, Phase
     	from SLIT
     	where SLCo = @slco and SL = @sl
   
     /* open cursor */
     open bcSLIT

     /* get first row */
     fetch next from bcSLIT into @slitem, @phasegroup, @phase 

     /* loop through all rows */
	WHILE (@@fetch_status = 0)
     	BEGIN
            /*get jb stuff*/
            select @contract = Contract from bJCJM where JCCo = @jcco and Job = @job

            select @contractitem = Item from bJCJP where JCCo = @jcco and Job = @job and
                  PhaseGroup = @phasegroup and Phase = @phase

			SELECT 1 FROM JBIT 
			WHERE JBCo = @jcco
				and Contract = @contract 
				and Item = @contractitem
				and BillMonth = @billmth
			if @@rowcount = 0
			   begin
			   select @msg = 'Invalid Job Billing Month for contract item ' + rtrim(@contractitem) + '.  It is recomended that you leave the Bill Month blank.', @rcode = 1
			   goto bspexit
			   end

			/* get first row */
			fetch next from bcSLIT into @slitem, @phasegroup, @phase 

		END
	

    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBITBillMthVal] TO [public]
GO
