SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspIMTmpDtlReqFldVal]
   /************************************************************************
   * CREATED:    MH 4/7/2000    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Validates 'Required' field in IMTD.  If Identifier for the 'Required' field
   *    exists in IMXF, inform user cross referenced identfier must be deleted first.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@template varchar(10), @identifier int, @requiredflag int, @msg varchar(150) = '' output)
   
   as
   set nocount on
   
   
       declare @xrefname varchar(30), @validcount int, @rcode int
   
       select @rcode = 0, @validcount = 0
   
       if @template is null
       begin
           select @msg = 'Missing ImportTemplate', @rcode = 1
           goto bspexit
       end
   
       if @identifier is null
       begin
           select @msg = 'Missing Identifier', @rcode = 1
           goto bspexit
       end
   
       if @requiredflag <> 1
       begin
           select @validcount = count(*) from IMXF where ImportTemplate = @template and ImportField = @identifier
   
           if @validcount > 0
           begin
               select @xrefname = XRefName from IMXF where ImportTemplate = @template and ImportField = @identifier
               select @msg = 'Identifier must be deleted from cross reference ' 
               select @msg = isnull(@msg,' ') + @xrefname + ' prior to changing required flag.'
               select @rcode = 1
               goto bspexit
           end
       end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMTmpDtlReqFldVal] TO [public]
GO
