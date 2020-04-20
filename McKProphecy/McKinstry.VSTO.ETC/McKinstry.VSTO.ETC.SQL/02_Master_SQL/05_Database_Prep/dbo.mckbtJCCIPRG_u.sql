USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mckbtJCCIPRG_u]    Script Date: 8/16/2016 11:08:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/****** Object:  Trigger dbo.btJCCIi    Script Date: 8/28/99 9:38:23 AM ******/
ALTER  TRIGGER [dbo].[mckbtJCCIPRG_u] ON [dbo].[bJCCI] FOR UPDATE AS
/**************************************************************
* Created By:   Arun Thomas 07142016

**************************************************************/
declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255),
		@jcco bCompany, @contract bContract, @item bContractItem

  /* 
-- -- -- validate PRG
select @validcnt = count(1) FROM bJCCI j WITH (NOLOCK)   --  DC changed Count(*) and added WITH (NOLOCK)
	join inserted i on j.JCCo=i.JCCo AND j.Contract=i.Contract
	AND j.udPRGNumber = i.udPRGNumber AND j.Item = i.Item
if @validcnt >1
	begin
	SELECT @errmsg =  'Cannot assign a PRG Number which is assigned to Item ' + i.Item + ' ' + i.udPRGNumber from Inserted i
	goto error
	end


  */


/*BEGIN
  IF TRIGGER_NESTLEVEL() >1
     RETURN*/
	 IF (SELECT trigger_nestlevel()) < 2
	 BEGIN
update bJCCI 
set bJCCI.udPRGDescription = x.Description
from (select i.JCCo, i.Contract, i.Item,i.udPRGNumber, a.Description from 
inserted i , JCJM a where 
a.JCCo=i.JCCo and a.Contract=i.Contract 
 and a.Job = i.udPRGNumber
 and  a.JCCo=i.JCCo  ) x
 where bJCCI.JCCo = x.JCCo and bJCCI.Contract = x.Contract and
 bJCCI.Item = x.Item 
END

  

/*
error:
	   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Contract Item!'
   	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   
   
  */
 
