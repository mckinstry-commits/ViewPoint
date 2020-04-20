SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVADataTypeSecurityGet    Script Date: 8/28/99 9:35:53 AM ******/
   CREATE    proc [dbo].[bspVADataTypeSecurityGet]
   /**************************************************************
   * Object:  Stored Procedure dbo.bspVADataTypeSecurityGet
   ***************************************************************
   * Created By : DANF 03/18/2004
   * Modified By :
   * Returns Security default group and Status
   * input:  Data type, Default Security Group, Data Security Status, msg as output
   * output:  InstanceCol, DatType, ColType, QualifyCol
   *         
   * 
   **************************************************************/
   
   (@DataType varchar(30)=null,
    @DflSecurtiyGroup int = null output,
    @Secure bYN = null output,
    @msg varchar(60) output) as
   
   set nocount on 
   begin
     declare @rcode int	/* error return code for any errors */
     select @rcode=0
   
     select @DflSecurtiyGroup = DfltSecurityGroup, @Secure = isnull(Secure,'N')
     from dbo.DDDTShared d with (nolock)
     where  Datatype = @DataType
     if @@rowcount = 0
   	begin
   		select @msg = 'Invalid Data Type ' + isnull(@DataType,'') + '!', @rcode = 1
   		goto bspexit
   	end
   
   bspexit:
   	return @rcode   
   end

GO
GRANT EXECUTE ON  [dbo].[bspVADataTypeSecurityGet] TO [public]
GO
