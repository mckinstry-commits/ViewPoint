SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspMSQuotePurge]
    /****************************************************************************
    * Created By:	GF 09/20/2000
    * Modified By:	GF 03/16/2004 - issue #24036 - new table bMSHO for haul code overrides
    *
    * USAGE:
    *   Purges a quote select from MSQuoteClose
    *
    * INPUT PARAMETERS:
    *   MS Company, Quote
    *
    * OUTPUT PARAMETERS:
    *
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
    *
    *****************************************************************************/
    (@msco bCompany = null, @quote varchar(10) = null, @msg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int
    
    select @rcode = 0
    
    if @msco is null
        begin
        select @msg = 'Missing MS Company', @rcode = 1
        goto bspexit
        end
    
    if @quote is null
        begin
        select @msg = 'Missing Quote', @rcode = 1
        goto bspexit
        end
    
    -- close the quote first to update IN
    -- set Active flag to 'N', this will close quote
    Update bMSQH set Active = 'N', PurgeYN = 'Y'
    where MSCo=@msco and Quote=@quote
    if @@rowcount = 0
        begin
        select @msg = 'Unable to update Quote ' + isnull(@quote,'') + ' in bMSQH', @rcode = 1
        goto bspexit
        end
    
    -- delete bMSQD
    delete bMSQD where MSCo=@msco and Quote=@quote
    
    -- delete bMSDX
    delete bMSDX where MSCo=@msco and Quote=@quote
    
    -- delete bMSPX
    delete bMSPX where MSCo=@msco and Quote=@quote
    
    -- delete bMSMD
    delete bMSMD where MSCo=@msco and Quote=@quote
    
    -- delete bMSHX
    delete bMSHX where MSCo=@msco and Quote=@quote
   
    -- delete bMSHO
    delete bMSHO where MSCo=@msco and Quote=@quote
    
    -- delete bMSJP
    delete bMSJP where MSCo=@msco and Quote=@quote
    
    -- delete bMSZD
    delete bMSZD where MSCo=@msco and Quote=@quote
    
    -- delete bMSQH
    delete bMSQH where MSCo=@msco and Quote=@quote
   
   
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'') + ' - [bspMSQuotePurge]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQuotePurge] TO [public]
GO
