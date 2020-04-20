SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang
-- Create date: 2/8/07
-- Description:	This procedure is used to insert a row 
--				of data into the DDDS table. Once a row
--				is inserted the security group will have access to 
--				the datatype inserted.
-- =============================================
CREATE PROCEDURE [dbo].[vspDDDSRemoveSecurity]

	--Parameters
	(@datatype char (30), @qualifier tinyint, @instance char (30), @securitygroup int,
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

insert into DDDS 
values
(@datatype, @qualifier, @instance, @securitygroup)
  

 return @rcode
   
   bsperror:
    
    return @rcode
   
   end

GO
GRANT EXECUTE ON  [dbo].[vspDDDSRemoveSecurity] TO [public]
GO
