SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspAPURUniqueAttchIDs]
  
  /***********************************************************
   * CREATED BY: MV 02/21/08 - #29702 Unapproved Enhancement
   * MODIFIED By : JonathanP 07/23/09 - #134047 Now returns the UniqueAttachmentID, FormName, KeyField, and TableName
   *				GP 7/29/2011 - TK-07143 changed @PO from varchar(10) to varchar(30)
   *
   * Usage:
   *	called from APUnappInvRev to get all the PO related
   *	UniqueAttchIDs for an Unapproved Invoice.
   *
   * Input params:
   *			@apco
   *            @uimth
   *            @uiseq	
   *
   * Output params:
   *			UniqueAttchIds 
   *
   * Return code:
   *	0 = success, 1 = failure
   *****************************************************/
  (@apco bCompany,@uimth bMonth, @uiseq int, @msg varchar(255)=null output)
  as
  set nocount on

 declare @table TABLE(UniqueAttachID uniqueidentifier, FormName varchar(30), KeyField varchar(500), TableName varchar(20))
 declare @po varchar(30),@opencursor int
 
  select @opencursor = 0

 declare vcTableInsert cursor for
    select DISTINCT PO
    from bAPUL
    where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and LineType=6
    
    /* open cursor */
    open vcTableInsert
    select @opencursor = 1
    
    Insert_loop:
    	fetch next from vcTableInsert into @po
    	if @@fetch_status <> 0 goto vspexit
 
	insert into @table (UniqueAttachID, FormName, KeyField, TableName)
		select a.UniqueAttchID, a.FormName, a.KeyField, a.TableName from HQAI i
		join HQAT a on i.AttachmentID=a.AttachmentID and i.POPurchaseOrder=@po
	
	goto Insert_loop
  

  vspexit:
	if @opencursor = 1
		begin
		close vcTableInsert
		deallocate vcTableInsert
		end
	Select * From @table 		
  	return
GO
GRANT EXECUTE ON  [dbo].[vspAPURUniqueAttchIDs] TO [public]
GO
