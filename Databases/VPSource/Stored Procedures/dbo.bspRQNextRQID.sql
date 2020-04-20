SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQNextRQID    Script Date: 7/6/2004 7:46:46 AM ******/
     CREATE       proc [dbo].[bspRQNextRQID]
     /*************************************
     * Created By:   DC 07/06/2004
     * Modified By:	DC 03/08/2005 -- 27131
     *				DC 12/4/08  #130129  -Combine RQ and PO into a single module
     *				DC 5/19/09  #133612 - Permission error on bPOCO when app role security is turned on
     * 	
     * 	
     * 
     * Usage:
     *	Gets next RQ ID stored in POCO file.  
     *	Forms using this routine are:
     *	RQEntry		
     *
     *
     * Pass In:
     *	RQCO
     *
     * Success returns:
     *	0
     *
     * Error returns:
     *	1
     *
     **************************************/
     (@co bCompany = 0, @nextid varchar(10) output, @errmsg varchar(255) output)
     as
     set nocount on
     
     declare @rcode int, @rqlastid varchar(10)
     
     select @rcode = 0, @rqlastid = null
     
     if @co = 0
     	begin
     	select @errmsg = 'Missing Company number!', @rcode = 1
     	goto bspexit
     	end
     
     /* validate HQ Company number */
     exec @rcode = bspHQCompanyVal @co, @errmsg output
     if @rcode <> 0 goto bspexit
     
     /* Get POCo Information */
     select @rqlastid = LastRQ
     from POCO with (nolock)
     where POCo = @co
     if @@rowcount = 0
     	begin
     	select @errmsg = 'Unable to get next available RQ ID!'
     	select @rcode = 1
     	goto bspexit
     	end
     
     /* Can only auto process true Numeric style RQ ID. */
     if isnumeric(@rqlastid) = 1
     	begin
     	/* Adding +1 to @rqlastid */
     	select @nextid = convert(bigint,@rqlastid)
     
     	/* Once the initial RQID value is determined, check for its existence in RQRH.
     	   If it does already exist, Increment it by +1 and do the check again. */
     	RQIDloop:
     	if exists(select 1 from RQRH with (nolock) where RQCo=@co and RQID=str(@nextid,10))
     		begin
     		select @nextid = convert(bigint,@nextid) + 1
     		goto RQIDloop
     		end
   
   		select @nextid = str((convert(bigint,@nextid)),10)
   
		--DC #133612
		update bPOCO
		Set ByPassTriggers = 'Y'
		Where POCo = @co

     	--ALTER TABLE bPOCO DISABLE TRIGGER ALL  --DC #130129
		update POCO
      	set LastRQ = @nextid
      	where POCo=@co           	
		--ALTER TABLE bPOCO ENABLE TRIGGER ALL  --DC #130129

		--DC #133612
		update bPOCO
		Set ByPassTriggers = 'N'
		Where POCo = @co           	     	
     	
     	end
     else
     	begin
     	select @errmsg = 'PO Company LastRQ is not numeric and may not be Automatically incremented!'
     	select @rcode = 1
     	goto bspexit
     	end	
     
     bspexit:
     if @rcode<>0 
     	begin
     	select @nextid = null
     	select @errmsg=@errmsg + char(13) + char(10) + '[bspRQNextRQID]'
     	end
     
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQNextRQID] TO [public]
GO
