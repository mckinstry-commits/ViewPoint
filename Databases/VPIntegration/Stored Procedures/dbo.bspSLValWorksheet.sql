SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.bspSLValWorksheet    Script Date: 8/28/99 9:35:47 AM ******/   
    CREATE       proc [dbo].[bspSLValWorksheet]
    /***********************************************************
     * CREATED BY	: kf 6/5/97
     * MODIFIED BY	: kb 1/25/99 
     *             : GR 8/11/99 - modified get compliance info to loop through all compliance codes to get compliance flag
     *             : kb 6/5/00 - took out ChangePrev flag from SLCO per issue #7119
     *             : kb 5/22/2 - issue #17404
     *				: mv 03/12/03 - #20534 - check compliance codes where verify = Y
     *				: mv 08/12/03 - #21703 - handle Complied=null for Flag type compliance codes
     *				: MV 03/30/05 - #27462 - validate job billed % < 9999%
     *				: CHS 01/22/09 - #26087
     *				: DC 02/25/09 - #132186 - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
     *				DC 01/0/10 - #136833 - Arithmetic overflow error when initing SL because of high bPCT
     *				DC 06/25/10 - #135813 - expand subcontract number 
     *
     *
     * USAGE:
     * Called by SL Worksheet form to validate and return information
     * about a Subcontract on the Worksheet.
     *
     * INPUT PARAMETERS
     *	@slco		SL Co#
     *   	@sl		Subcontract to validate
     *
     * OUTPUT PARAMETERS
     *	@vendorname	Vendor name
     *	@vendor		Vendor #
     *	@job		Job
     *	@jobdesc	Job description
     *	@jcco		JC Co#
     *	@curcost	Current Subcontract total cost
     *	@previnvcd	Previous Invoiced total
     *	@wccost		Current Work Complete
     *	@smcost		Current Stored Materials
     *	@total		Total This Invoice
     *	@retcost	Total Retainage This Invoice
     *	@todate		To Date Total
     *	@pctbill	Percent Billed (To Date / Current Contract)
     *	@comply		Compliance flag - 'Y' complied, 'N' out of compliance
     *	@alloweditprev	Allow Edit to Previous Values flag
     *	@msg      	Subcontract description, or error message
     *
     * RETURN VALUE
     *  	0         	success
     *   	1         	failure
     *****************************************************/   
    	(@slco bCompany, @sl VARCHAR(30), --bSL,  DC #135813
    	@vendorname char(30) output, @vendor bVendor output,
    	@job bJob output, @jobdesc bItemDesc output, @jcco bCompany output, @curcost
    	bDollar output, @previnvcd bDollar output, @wccost bDollar output,   
    	@smcost bDollar output, @total bDollar output, @retcost bDollar output,
    	@todate bDollar output,@pctbill bPct output, @comply bYN output,
    	@msg varchar(255) output)
    as
   
    set nocount on
   
    declare @rcode int, @status tinyint, @vendorgroup bGroup, @expdate bDate, @invdate bDate,
    	@comptype char(1), @opencompliance int, @jobbillpct float
   
    select @rcode = 0
   
    if @slco is null
    	begin
    	select @msg = 'Missing SL Company!', @rcode = 1
    	goto bspexit
    	end
      
    if @sl is null
    	begin   
    	select @msg = 'Missing Subcontract!', @rcode = 1
    	goto bspexit
    	end
   
    select @jcco = JCCo, @job = Job, @msg = Description, @vendorgroup = VendorGroup, @vendor = Vendor,
    	@status = Status
    from bSLHD
    where SLCo = @slco and SL = @sl
    if @@rowcount = 0
    	begin
    	select @msg = 'Subcontract not on file!', @rcode = 1
    	goto bspexit
    	end
    if @status <> 0 	-- hardcoded 'open' status
    	begin    
   		select @msg = 'Subcontract is not Open!', @rcode = 1
    	goto bspexit   
    	end
   
   /*took out ChangePrev flag from SLCO per issue #7119*/
    -- get Previous Edit flag from SL Company
   -- select @alloweditprev  =ChangePrev from bSLCO where SLCo = @slco
   
    -- get Compliance info
    select @comply='Y'
   /* select @expdate = s.ExpDate, @comply = s.Complied, @comptype = h.CompType
    from bSLCT s
    join bHQCP h on h.CompCode = s.CompCode
    where s.SLCo = @slco and s.SL = @sl
   
    -- get Invoice date from SL Worksheet header
    select @invdate = InvDate from bSLWH where SLCo = @slco and SL = @sl
   
    if @comptype = 'D' and @invdate > @expdate
    	begin
    	select @comply = 'N'
    	end*/
   
   declare compliance_cursor cursor for
   select s.ExpDate, s.Complied, h.CompType
   from bSLCT s
   join bHQCP h on h.CompCode = s.CompCode
   where s.SLCo = @slco and s.SL = @sl and s.Verify='Y' --#20534
	AND s.APRef is null  --DC #132186
		
   	open compliance_cursor
   	select @opencompliance=1
   
   	compliance_cursor_loop:     --loop through all compliances
   
   	fetch next from compliance_cursor into @expdate, @comply, @comptype
   	if @@fetch_status=0
   	     begin
   	     	if @comptype = 'F' and isnull(@comply,'N') = 'N'	--21703
   	     		begin
   				select @comply = 'N'	--21703
   	     	    goto compliance_cursor_end
   	     		end
   
   			-- get Invoice date from SL Worksheet header
   			select @invdate = InvDate from bSLWH where SLCo = @slco and SL = @sl
   	
   			if @comptype = 'D' and (@invdate > @expdate or @expdate is null) -- issue 17404
   			  begin
   			     select @comply = 'N'
   			     goto compliance_cursor_end
   			  end
   		     	goto compliance_cursor_loop       --get the next record
   	    end
   
   
   	compliance_cursor_end:      -- close and deallocate cursor
   	if @opencompliance=1
              begin
        		close compliance_cursor
        		deallocate compliance_cursor
        		select @opencompliance=0
        	   end     
   
    -- get Current Contract and Invoiced Cost from SL Items
    select @curcost = sum(CurCost), @previnvcd = sum(InvCost)
   
    from bSLIT
    where SLCo = @slco and SL = @sl
   
    -- get Current Work Complete, Stored Materials, and Retainage from SL Worksheet Items
    select 	@wccost=sum(WCCost),
    	@smcost = sum(Purchased - Installed),
    	@retcost=sum(WCRetAmt + SMRetAmt)
    	from bSLWI
    	where SLCo = @slco and SL = @sl
   
    select @total = @wccost + @smcost	-- Total this Invoice
    select @todate = @previnvcd + @total	-- To Date Total
   
    -- calculate % Billed
    select @pctbill = 0, @jobbillpct=0
    if @curcost <> 0
    	begin
   	--#27462 - check that job bill % doesn't exceed 9999%
    	select @jobbillpct= @todate / @curcost
   	if @jobbillpct > 99.9999 or @jobbillpct < -99.9999  --DC #136833
   			begin
   				select @msg = '% Complete to Date is greater than 9,999% or less than -9,999% - Change the Contract.'
   				select @rcode = 1
   			end
   	else
   		begin
   			select @pctbill = @jobbillpct
   		end
    	end
      
    select @vendorname = 'Missing'
    select @vendorname = Name from bAPVM where VendorGroup = @vendorgroup and Vendor = @vendor
    select @jobdesc = 'Missing'
    select @jobdesc = Description from bJCJM where JCCo= @jcco and Job = @job
      
    --close and deallocate cursor
    if @opencompliance=1
        begin
        	close compliance_cursor
        	deallocate compliance_cursor
        	select @opencompliance=0
        end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLValWorksheet] TO [public]
GO
