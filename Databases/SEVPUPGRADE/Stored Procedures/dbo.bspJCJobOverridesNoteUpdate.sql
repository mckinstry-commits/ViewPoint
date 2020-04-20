SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROCEDURE [dbo].[bspJCJobOverridesNoteUpdate]
   /**********************************************************************
   	Created By: DANF 02/22/2005
       Modified by: 
   
   	Usage: Used to update notes for the cost tab of the JC overrides form.
   
   	Input:
   		@JCCo - JCCo
   		@Job - Job
   		@Notes - Notes
   
   	Output:
   		@rcode
   		@errmsg
   
   
   
   
   
   **********************************************************************/
   (@JCCo bCompany = null, @Job bJob = null, @Notes varchar(8000), @errmsg varchar(255) = '' output)
   
    AS
   
   declare @rcode int, @separator varchar(30)
   
   select @rcode = 0, @separator = char(013) + char(010), @errmsg = '-'
   
   
   update dbo.JCJM
   set OverProjNotes=@Notes
   where JCCo=@JCCo and Job=@Job
   if @@rowcount<>1
   	begin
   		select @rcode = 1, @errmsg = 'An error has occurred updating Job Overrides Notes for ' + isnull(@Job,'') + '.'
   	end
   
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJobOverridesNoteUpdate] TO [public]
GO
