SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspDDDTVal    Script Date: 8/28/99 9:34:19 AM ******/
	-- JRK, 11/8/06: Created from vspDDDTGetDatatypeInfo and changed reference of "DDDT" to "vDDDT" and
	--	column name SystemDatatype to SQLDatatype.

   CREATE  proc [dbo].[vspDDDTGetDatatypeInfo]
   	(@datatype char(30) = null, @inputtype tinyint output, @inputmask varchar(30) output,
   	@inputlength tinyint output, @prec tinyint output, @systemdatatype varchar(30) output,
       @msg varchar(60) output)
   
   
   
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @datatype is null
   
   	begin
   	select @msg = 'Missing Datatype!', @rcode = 1
   	goto bspexit
   	end
   
   select @inputtype = InputType, @inputmask = InputMask, @inputlength = InputLength,
     @prec = Prec, @systemdatatype = SQLDatatype
   	from vDDDT
   	where Datatype = @datatype
   if @@rowcount = 0
   	begin
   	select @msg = 'Datatype not setup in DDDT!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDTGetDatatypeInfo] TO [public]
GO
