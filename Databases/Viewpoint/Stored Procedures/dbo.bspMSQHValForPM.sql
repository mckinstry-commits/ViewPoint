SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspMSQHValForPM]
   /*************************************
   * Created By:   GF 02/20/2002
   * Modified By:
   *
   * validates MS Quote for PM. If + passed, will create quote header
   *
   * Pass:
   *	MS Company
   *	MS Quote
   *	PM Company
   *	PM Project
   *
   * Success returns:
   *	New Quote
   *	Allow Change Flag
   *	0 and Description from bMSQH
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @quote varchar(10) = null, @pmco bCompany = null, @project bJob = null,
    @newquote varchar(10) = null output, @allowchange bYN output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int, @msquote varchar(10), @autoquote bYN, @msjcco bCompany, @msjob bJob
   
   select @rcode = 0, @allowchange = 'Y'
   
   if isnull(@msco,0) = 0
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@pmco,0) = 0
   	begin
   	select @msg = 'Missing PM Company number', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@project,'') = ''
   	begin
   	select @msg = 'Missing PM Project', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@quote,'') = ''
   	begin
   	select @msg = 'Missing MS Quote', @rcode = 1
   	goto bspexit
   	end
   
   -- validate MSCo
   select @autoquote=AutoQuote from bMSCO where MSCo=@msco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid MS company', @rcode = 1
   	goto bspexit
   	end
   
   if @autoquote = 'N' and @quote = '+'
   	begin
   	select @msg = 'Auto quote feature is turned off in MS. Enter a new quote manually.', @rcode = 1
   	goto bspexit
   	end
   
   -- validate MSQH for msco, type, pmco, job
   select @msquote=Quote, @msg=Description
   from bMSQH where MSCo=@msco and QuoteType='J' and JCCo=@pmco and Job=@project
   if @@rowcount <> 0
   	begin
   	if isnull(@msquote,'') <> isnull(@quote,'')
   		begin
   		select @msg = 'MS Quote already exists for this PM company and Project', @rcode = 1
   		goto bspexit
   		end
   	else
   		goto MSQD_CHECK
   	end
   
   -- if @quote = '+' get next sequential quote from MSCO
   if isnull(@quote,'') = '+'
   	begin
   	exec @rcode = dbo.bspMSGetNextQuote @msco, @newquote output
   	if isnull(@newquote,'') = ''
   		begin
   		select @msg = 'Error getting next sequential quote from MS company', @rcode = 1
   		goto bspexit
   		end
   	else
   		select @quote = @newquote
   	end
   else
   	begin
   	select @msjcco=JCCo, @msjob=Job
   	from bMSQH where MSCo=@msco and Quote=@quote
   	if @@rowcount <> 0
   		begin
   		if isnull(@msjcco,0) <> @pmco or isnull(@msjob,'') <> @project
   			begin
   			select @msg = 'Invalid quote, already set up with different quote type parameters', @rcode = 1
   			goto bspexit
   			end
   		end
   	end
   
   MSQD_CHECK:
   -- check MSQD if detail exists and status of any record is not bid set AllowChange flag to 'N'
   select @validcnt = count(*) from bMSQD where MSCo=@msco and Quote=@quote and Status <> 0
   if @validcnt = 0 
   	select @allowchange = 'Y'
   else
   	select @allowchange = 'N'
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQHValForPM] TO [public]
GO
