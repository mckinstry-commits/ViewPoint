SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPFileNameVal    Script Date: 8/28/99 9:33:38 AM ******/
   /****** Object:  Stored Procedure dbo.bspRPFileNameVal    Script Date: 3/28/99 12:00:38 AM ******/
   CREATE   proc [dbo].[bspRPFileNameVal]
   /* validates Report Filename
    * pass in filename
    * returns ''
   */
   	(@FileName varchar(132) = null, @Application varchar(50), @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int,
   		@validcnt int
   	select @rcode = 0, @validcnt = 0 

   	
   if @FileName in (null,'')
   	begin
      		select @msg='No FileName supplied', @rcode=1
   		goto bspexit
   	end
   
if @Application = 'Crystal'
   	begin
		select @validcnt = 1 
   	       	where UPPER(@FileName) not like '%.RPT' and  UPPER(@FileName) not like '%.DOT'
   		if @validcnt <>0
   		begin
   			select @msg='All reports must end in .rpt or .dot', @rcode=1
   			goto bspexit
   		end
   	end
   
   --	select @byte=isnull(charIndex('.rpt',lower(@FileName)),0)
   --	if @byte<>Datalength(RTrim(@FileName))-3
   --	begin
   --		select @msg='Filename must end with '.rpt'', @rcode=1
   --		goto bspexit
   
   --	end
   	
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRPFileNameVal] TO [public]
GO
