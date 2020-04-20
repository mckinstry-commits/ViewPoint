SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspIMViewpointDefaultsINMO]
     /***********************************************************
      * CREATED BY:  RBT 09/08/04 - issue #22564
      * MODIFIED BY: 
      *			  RBT 04/08/05 - issue #28366, use ImportTemplate when getting Form.
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
     
     select @rcode = 0, @msg = ''
    
     select @Form = Form from IMTR where RecordType = @rectype and ImportTemplate = @ImportTemplate
    
     if @Form = 'INMOEntry'
        begin
        exec @rcode = dbo.bspIMViewpointDefaultsINMB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
        end
     if @Form = 'INMOEntryItems'
        begin
        exec @rcode = dbo.bspIMViewpointDefaultsINIB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
        end
     
     
     
     bspexit:
         select @msg = isnull(@desc,'IN Material Orders') + char(13) + char(10) + '[bspIMViewpointDefaultsINMO]'
     
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsINMO] TO [public]
GO
