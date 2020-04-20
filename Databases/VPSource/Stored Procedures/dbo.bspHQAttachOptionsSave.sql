SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQAttachOptionsSave]
   /***********************************************
   	Created: RM 02/20/02
   	Modified: RM 06/03/03
   			  RT 08/16/04 - #21497, Renamed to bspHQAttachOptionsSave to reflect use for attachments, not just scanning.
   
   	Usage: Used to save the Attachment options for HQ.  
   			There is no key on this table, and it will only contain a single record,
   			so it cannot save using the standard methods.
   
   	
   ***********************************************/
   
   (@tempdir varchar(255),@permdir varchar(255),@coYN bYN, @modYN bYN,@formYN bYN,@monthYN bYN,
   @customYN bYN, @customstring varchar(255),@usejpg bYN,@usestruct bYN,@msg varchar(255) output)
   as
   
   declare @rcode int
   select @rcode=0
   
   if exists(select * from bHQAO)
   	update bHQAO Set 
   	TempDirectory=@tempdir,
   	PermanentDirectory=@permdir,
   	ByCompany=@coYN,
   	ByModule=@modYN,
   	ByForm=@formYN,
   	ByMonth=@monthYN,
   	Custom=@customYN,
   	CustomFormat=@customstring,
   	UseJPG=@usejpg,
   	UseStructForAttYN=@usestruct
   else
   	insert bHQAO(TempDirectory,	PermanentDirectory,ByCompany,ByModule,ByForm,
   				ByMonth,Custom,CustomFormat,UseJPG,UseStructForAttYN)
       values		(@tempdir,@permdir,@coYN,@modYN,@formYN,
   				@monthYN,@customYN,@customstring,@usejpg,@usestruct)
   
   if @@rowcount <> 1
   	select @msg = 'An error ocurred while saving the Attachment Settings.',@rcode = 1
   
   
   
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQAttachOptionsSave] TO [public]
GO
