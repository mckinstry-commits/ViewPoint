SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  User Defined Function dbo.JustifyStringToDatatype    Script Date: 4/11/2002 2:10:46 PM ******/
  
  CREATE  function [dbo].[bfJustifyStringToDatatype]
   /********************************************************
   * CREATED BY: JM 4/10/02
   * MODIFIED BY: GG 5/2/07 - mods for V6.0 
   *
   * USAGE: Returns a string reformatted to a char-type Datatype
   *
   * INPUT PARAMETERS:
   *	@String		String to reformat
   *	@Datatype	Datatype to format to
   *
   * RETURN VALUE:
   *	Reformatted @String
   *********************************************************/
  (@String varchar(255), 
  @Datatype varchar(30))
  
  returns varchar(255) as
  begin 
  
  	declare 	@InputLength tinyint, 
  		@InputMask varchar(30), 
  		@k tinyint,
  		@diff tinyint 
  
  	select @InputLength = InputLength, @InputMask = InputMask from dbo.DDDTShared where Datatype = @Datatype
  	if @InputMask = 'R'
  		begin
  		select @diff = @InputLength - len(@String), @k = 1
  		while @k <= @diff
  			select @String = ' ' + @String, @k = @k + 1
  		end
  
  	return @String
  
  end

GO
GRANT EXECUTE ON  [dbo].[bfJustifyStringToDatatype] TO [public]
GO
