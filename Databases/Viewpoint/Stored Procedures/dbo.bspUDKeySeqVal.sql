SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspUDKeySeqVal]
   /****************************************************
   	Created: 03/08/01 RM
   		
   	Usage:  Validates that a Key Seq # does not already exist from the particular form that the user is creating/modifying
   
   	
   
   
   
   ****************************************************/
   (@TableName varchar(30),@Column varchar(30),@KeySeq int,@errmsg varchar(255) output)
   
    AS
   
   declare @rcode int
   select @rcode = 0
   
   if exists(select * from bUDTC where KeySeq = @KeySeq and TableName = @TableName and ColumnName <> @Column)
   begin
   	select @rcode = 1,@errmsg = 'That Key Sequence already exists for this form'
   	goto bspexit
   end
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspUDKeySeqVal] TO [public]
GO
