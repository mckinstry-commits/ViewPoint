SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE  PROCEDURE [dbo].[vspIMViewpointDefaultsMSHEntry]
CREATE  PROCEDURE [dbo].[vspIMViewpointDefaultsMSHEntry]
     /***********************************************************
      * CREATED BY: Dan So 04/14/09
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
    
     if @Form = 'MSHaulEntry'
        begin
        exec @rcode = dbo.vspIMViewpointDefaultsMSHB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
        end
     if @Form = 'MSHaulEntryLines'
        begin
        exec @rcode = dbo.vspIMViewpointDefaultsMSLB @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
        end
     
     
     
     bspexit:
         select @msg = isnull(@desc,'MS Haul Entry') + char(13) + char(10) + '[vspIMViewpointDefaultsMSHaulEntry]'
     
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsMSHEntry] TO [public]
GO
