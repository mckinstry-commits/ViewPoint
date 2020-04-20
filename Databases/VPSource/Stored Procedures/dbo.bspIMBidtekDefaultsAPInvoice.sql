SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[bspIMBidtekDefaultsAPInvoice]
     /***********************************************************
      * CREATED BY: Danf
      * MODIFIED BY: RBT 09/05/03 - Issue #20131, Allow rectypes <> tablenames.
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
     
     select @rcode = 0, @msg = ''
    
     select @Form = Form from IMTR where RecordType = @rectype and ImportTemplate = @ImportTemplate
    
     if @Form = 'APEntry'
        begin
        exec @rcode = dbo.bspIMBidtekDefaultsAPHB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
        end
     if @Form = 'APEntryDetail'
        begin
        exec @rcode = dbo.bspIMBidtekDefaultsAPLB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
        end
     
     
     
     bspexit:
         select @msg = isnull(@desc,'AP Invoice') + char(13) + char(10) + '[bspBidtekDefaultAPInvoice]'
     
         return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsAPInvoice] TO [public]
GO
