SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspIMXHRecTypeVal]
   /************************************************************************
   * CREATED:    MH 3/30/00    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *    Verify RecordType entered in IMXH resides in IMTD for 
   *    the respective import template
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
           --Parameter list goes here
       (@template varchar(10) = null , @recordtype varchar(30) = null, @msg varchar(255) output)
   
   as
   set nocount on
   
           --Local variable declarations list goes here
   
       declare @rcode int
   
       if @template is null
   
   	begin
   	select @msg = 'Missing Template!', @rcode = 1
   	goto bspexit
   	end
   
       if @recordtype is null
   
   	begin
   	select @msg = 'Missing RecordType!', @rcode = 1
   	goto bspexit
   	end
   
       select @rcode = 0
   
       select * from IMTD where ImportTemplate = @template and RecordType = @recordtype
   
       if @@rowcount > 0
           select @msg = Description from IMTR where ImportTemplate=@template and RecordType=@recordtype
       else
           begin
               select @msg = 'Record type does not exist in IMTemplate Detail for this Template'
               select @rcode = 1
           end    
   
   bspexit:
   
       if @rcode <> 0 
           select @msg=isnull(@msg,'Record Type Val') + char(13) + char(10) + '[bspIMXHRecTypeVal]'
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMXHRecTypeVal] TO [public]
GO
