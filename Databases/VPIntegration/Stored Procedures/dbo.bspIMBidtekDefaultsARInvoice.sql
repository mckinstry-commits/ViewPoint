SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspIMBidtekDefaultsARInvoice]
    /***********************************************************
     * CREATED BY: Danf
     * MODIFIED BY: RBT 09/09/03 - 20131, Allow rectype <> tablename.
     *			  RBT 04/08/05 - issue #28366, use ImportTemplate when getting Form.
     *
     * Usage:
     *	Used by Imports to create values for needed or missing
     *      data based upon Bidtek default rules. This will call 
     *      coresponding bsp based on record type.
     *
     * Input params:
     *	@ImportId	Import Identifier
     *	@ImportTemplate	Import ImportTemplate
     *
     * Output params:
     *	@msg		error message
     *
     * Return code:
     *	0 = success, 1 = failure
     ************************************************************/
    
     (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
    
    as
    
    set nocount on
    
    declare @rcode int, @recode int, @desc varchar(120), @tablename varchar(10)
    
    /* check required input params */
    select @rcode = 0
    
     select @Form = Form from IMTR where RecordType = @rectype and ImportTemplate = @ImportTemplate
    
    if @Form = 'ARInvoiceEntry'
       begin
       exec @rcode = dbo.bspIMBidtekDefaultsARBH @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
       end
    if @Form = 'ARInvoiceEntryLines'
       begin
       exec @rcode = dbo.bspIMBidtekDefaultsARBL @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
       end
    
    
    
    bspexit:
        select @msg = isnull(@desc,'AR Invoice') + char(13) + char(10) + '[bspIMBidtekDefaultsARInvoice]'
    
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsARInvoice] TO [public]
GO
