SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDDTVal    Script Date: 8/28/99 9:34:19 AM ******/
  CREATE proc [dbo].[vspDDCIcInsert]
  /***************************************
  * Created: JRK 10/31/06
  * Modified: 
  *
  * Insert DDCIc (custom combobox items) items.
  *
  **************************************/
  	(@combotype varchar(20) = null, @seq int = null,
	 @databasevalue varchar(30) = null, @displayvalue varchar(100) = null,
	 @msg varchar(60) output)
  
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
  
if @combotype is null
    	begin
  	select @msg = 'Missing ComboType!', @rcode = 1
  	goto bspexit
  	end

if @seq is null
    	begin
  	select @msg = 'Missing Seq!', @rcode = 1
  	goto bspexit
  	end

if @databasevalue is null
    	begin
  	select @msg = 'Missing DatabaseValue!', @rcode = 1
  	goto bspexit
  	end

if @displayvalue is null
    	begin
  	select @msg = 'Missing DisplayValue!', @rcode = 1
  	goto bspexit
  	end

  INSERT INTO DDCIc (ComboType, Seq, DatabaseValue, DisplayValue)
  Values (@combotype, @seq, @databasevalue, @displayvalue)

  if @@rowcount = 0
  	begin
  	select @msg = 'DDCIc insert failed!', @rcode = 1
  	end

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDCIcInsert] TO [public]
GO
