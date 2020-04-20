SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPDatatypeVal    Script Date: 8/28/99 9:33:37 AM ******/
   /****** Object:  Stored Procedure dbo.bspRPDatatypeVal    Script Date: 3/28/99 12:00:38 AM ******/
   CREATE  PROCEDURE [dbo].[bspRPDatatypeVal]
   (@datatype varchar(30)= null, @fieldname varchar(60)=null,
    @msg varchar(60) output)
   AS
   /* validates Report Datatype exits in RPRT */
   /* pass Datatype, fieldtype */
   /* returns error message if error */
   set nocount on
   declare @rcode int
   declare @fieldtype tinyint
   select @rcode=0
   select @fieldtype=0
   if @fieldname is null
   	begin
   		select @msg='Missing fieldname!',@rcode=1
   		goto bspexit
   	end
   if SubString(@fieldname,1,1)='@' 
   	begin	
   		select @fieldtype=1
   	end
   if @fieldtype=1 and @datatype is null
   
   	begin
   		select @msg='Missing datatype!',@rcode=1
   		goto bspexit
   	end
   if (select count(*) from systypes where name=@datatype)<>1
   	begin
   		select @msg='Invalid datatype',@rcode=1
   		goto bspexit
   	end
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRPDatatypeVal] TO [public]
GO
