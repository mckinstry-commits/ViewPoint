SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspIMViewpointDefaultsSL]
    /***********************************************************
     * CREATED BY:  JimE
     * MODIFIED BY: 
     *
     * Usage:
     *	Used by Imports to create values for needed or missing
     *      data based upon Viewpoint default rules. This will call 
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
    
    select @rcode = 0, @msg = ''
    
    select @Form = Form from IMTR where RecordType = @rectype and ImportTemplate = @ImportTemplate
    
    if @Form = 'SLEntry'
       begin
       exec @rcode = dbo.bspIMViewpointDefaultsSLHB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
       end
    if @Form = 'SLEntryItems'
       begin
       exec @rcode = dbo.bspIMViewpointDefaultsSLIB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
       end
    
    bspexit:
        select @msg = isnull(@desc,'SL Entry') + char(13) + char(10) + '[bspViewpointDefaultSLEntry]'
    
        return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsSL] TO [public]
GO
