SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vspIMViewpointDefaultsPayEdit]
     /***********************************************************
      * CREATED BY: MV 07/29/09
      * MODIFIED BY: 
      *
      * Usage:
      *	Used by Imports to create values for needed or missing
      *      data based upon default rules. This will call 
      *      coresponding procedures based on record type.
      *
      * Input params:
      *	@ImportId		Import Identifier
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
    
     if @Form = 'APPayEdit'
        begin
        exec @rcode = dbo.vspIMViewpointDefaultsAPPB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
        end
     if @Form = 'APPayEditDetail'
        begin
        exec @rcode = dbo.vspIMViewpointDefaultsAPTB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
        end
     
     
     
     bspexit:
         select @msg = isnull(@desc,'AP Pay Edit') + char(13) + char(10) + '[vspIMViewpointDefaultsPayEdit]'
     
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsPayEdit] TO [public]
GO
