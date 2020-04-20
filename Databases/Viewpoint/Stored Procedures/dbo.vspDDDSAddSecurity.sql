SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL
-- Create date: 2/13/2007
-- Description:	This procedure removes a record from the 
--				DDDS table which secures the datatype.
-- =============================================
CREATE PROCEDURE [dbo].[vspDDDSAddSecurity]

	-- Add the parameters for the stored procedure here
	(@datatype char (30), @qualifier tinyint, @instance char (30), @securitygroup smallint,
		@msg varchar(80) = '' output)
 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @rcode int
select @rcode = 0

    
      
      if (select count(*) from dbo.vDDDT with (nolock) where  Datatype = @datatype)<>1
   	begin
   	select @msg = 'Datatype not in DDDT!', @rcode = 1
   
   	goto bsperror
   	end
      if (select count(*) from dbo.vDDSG with (nolock) where  SecurityGroup = @securitygroup)<1
   	begin
   	select @msg = 'Invalid Security Group!', @rcode = 1
   	goto bsperror
   	end

delete DDDS 
where Datatype = @datatype and Qualifier = @qualifier 
and Instance = @instance and SecurityGroup = @securitygroup  
	


    
   return @rcode
   
   bsperror:
    
    return @rcode
   
  end

GO
GRANT EXECUTE ON  [dbo].[vspDDDSAddSecurity] TO [public]
GO
