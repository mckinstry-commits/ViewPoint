USE [Viewpoint]
GO

/****** Object:  Trigger [dbo].[mckbtJCCIPRG_i]    Script Date: 8/16/2016 11:05:52 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/****** Object:  Trigger dbo.btJCCIi    Script Date: 8/28/99 9:38:23 AM ******/
ALTER  TRIGGER [dbo].[mckbtJCCIPRG_i] ON [dbo].[bJCCI] FOR INSERT AS
/**************************************************************
* Created By:   Arun Thomas 07142016

**************************************************************/
declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255),
		@jcco bCompany, @contract bContract, @item bContractItem

   
-- -- -- validate PRG
select @validcnt = count(1) FROM bJCCI j WITH (NOLOCK)   --  DC changed Count(*) and added WITH (NOLOCK)
	join inserted i on j.JCCo=i.JCCo AND j.Contract=i.Contract
	AND j.udPRGNumber = i.udPRGNumber AND j.Item = i.Item
if @validcnt >1
	begin
	SELECT @errmsg =  'Cannot assign a PRG Number which is assigned to Item ' + i.Item + ' ' + i.udPRGNumber from Inserted i
	goto error
	end
IF (SELECT trigger_nestlevel()) < 2
Begin
update bJCCI set bJCCI.udPRGDescription = JCJM.Description
from inserted i , JCJM where 
 bJCCI.JCCo=i.JCCo and bJCCI.Contract=i.Contract and bJCCI.Item=i.Item
 and bJCCI.udPRGNumber = i.udPRGNumber
 and 
 JCJM.JCCo=i.JCCo and JCJM.Contract=i.Contract     
 and JCJM.Job = i.udPRGNumber 
 END

error:
	   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Contract Item!'
   	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   
   
  
 






GO


