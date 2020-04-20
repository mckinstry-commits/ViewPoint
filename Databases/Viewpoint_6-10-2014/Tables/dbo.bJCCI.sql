CREATE TABLE [dbo].[bJCCI]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Department] [dbo].[bDept] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[UM] [dbo].[bUM] NOT NULL,
[SIRegion] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[SICode] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[RetainPCT] [dbo].[bPct] NOT NULL CONSTRAINT [DF_bJCCI_RetainPCT] DEFAULT ((0)),
[OrigContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCI_OrigContractAmt] DEFAULT ((0)),
[OrigContractUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCI_OrigContractUnits] DEFAULT ((0)),
[OrigUnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCCI_OrigUnitPrice] DEFAULT ((0)),
[ContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCI_ContractAmt] DEFAULT ((0)),
[ContractUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCI_ContractUnits] DEFAULT ((0)),
[UnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCCI_UnitPrice] DEFAULT ((0)),
[BilledAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCI_BilledAmt] DEFAULT ((0)),
[BilledUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCI_BilledUnits] DEFAULT ((0)),
[ReceivedAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCI_ReceivedAmt] DEFAULT ((0)),
[CurrentRetainAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCI_CurrentRetainAmt] DEFAULT ((0)),
[BillType] [dbo].[bBillType] NULL,
[BillGroup] [dbo].[bBillingGroup] NULL,
[BillDescription] [dbo].[bItemDesc] NULL,
[BillOriginalUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCI_BillOriginalUnits] DEFAULT ((0)),
[BillOriginalAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCI_BillOriginalAmt] DEFAULT ((0)),
[BillCurrentUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCI_BillCurrentUnits] DEFAULT ((0)),
[BillCurrentAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCI_BillCurrentAmt] DEFAULT ((0)),
[BillUnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCCI_BillUnitPrice] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[InitSubs] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCI_InitSubs] DEFAULT ('Y'),
[UniqueAttchID] [uniqueidentifier] NULL,
[StartMonth] [dbo].[bMonth] NOT NULL,
[MarkUpRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bJCCI_MarkUpRate] DEFAULT ((0.000000)),
[ProjNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ProjPlug] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCI_ProjPlug] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[InitAsZero] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCI_InitAsZero] DEFAULT ('N'),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[udLockYN] [dbo].[bYN] NULL CONSTRAINT [DF__bJCCI__udLockYN__DEFAULT] DEFAULT ('N'),
[udRevType] [varchar] (3) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

/****** Object:  Trigger dbo.btJCCId    Script Date: 8/28/99 9:37:41 AM ******/
CREATE trigger [dbo].[btJCCId] on [dbo].[bJCCI] for DELETE as
/*-----------------------------------------------------------------
* This trigger prevents deletes of bJCCI  (JC Contract Item)
* Created By:	JRE 11/15/96
* Modified By:	bc	05/10/00 - issue #14599
*				MV 10/04/01 - Issue 14599
*				GF 10/09/2002 - changed dbl quotes to single quotes
*				bc 11/12/02 - Issue 19330 Removed Interfaced status from the JBIN check. Note Danf Backout thie Issue
*				DANF 08/14/03 - Issue 21071 Do not validate Bills in JB if Contract is being purged.
*				GF 10/26/2004 - issue #25828 clean-up trigger performance
*				GP 06/04/2008 - Issue #123670 Allow delete of contract item when the item nets to zero in bJCID.
*
*
*
*	following error condition exists:
*
*              Item Detail Exists
*
*		Updates JCID
*
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int 
		
declare @ContractAmt bDollar, @BilledAmt bDollar, @ReceivedAmt bDollar, @CurrentRetainAmt bDollar, 
		@BilledTax bDollar, @ProjDollars bDollar, @ContractTotal bDollar, @mth bMonth -- bJCID parameters - Issue #123670

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- Check bJCOI for change order items assigned to contract item(s)
SELECT @validcnt = count(*) FROM deleted d
JOIN bJCCO c with (nolock) on c.JCCo = d.JCCo
JOIN bJCCM m with (nolock) on c.JCCo = d.JCCo and m.Contract = d.Contract
JOIN bJCOI i with (nolock) on i.JCCo = d.JCCo and i.Contract = d.Contract and i.Item = d.Item
WHERE m.ClosePurgeFlag <> 'Y'
IF @validcnt <> 0
BEGIN
	SELECT @errmsg = 'Approved Change Order Items exist'
	GOTO error
END

---- Check bJCJP for Job phases assigned to contract item(s)
SELECT @validcnt = count(*) FROM deleted d
JOIN bJCCM m with (nolock) on m.JCCo = d.JCCo and m.Contract = d.Contract
JOIN bJCJP i with (nolock) on i.JCCo = d.JCCo and i.Contract = d.Contract and i.Item = d.Item
WHERE m.ClosePurgeFlag <> 'Y'
IF @validcnt <> 0
BEGIN
	SELECT @errmsg = 'Job Phases exist'
	GOTO error
END

---- Check bPMOI for Job phases assigned to contract item(s) - Issue #123670
SELECT @validcnt = count(*) FROM deleted d
JOIN bJCCM m with (nolock) on m.JCCo = d.JCCo and m.Contract = d.Contract
JOIN bPMOI i with (nolock) on i.PMCo = d.JCCo and i.Contract = d.Contract and i.ContractItem = d.Item
WHERE m.ClosePurgeFlag <> 'Y'
IF @validcnt <> 0
BEGIN
	SELECT @errmsg = 'Contract Item exists in PM Change Order Items'
	GOTO error
END

---- Validate against bJBIT
select @validcnt = count(*) from deleted d
join bJCCM m with (nolock) on m.JCCo = d.JCCo and m.Contract = d.Contract
join bJBIN n with (nolock) on n.JBCo = d.JCCo and n.Contract = d.Contract and n.InvStatus in ('C','D','I','A')
join bJBIT t with (nolock) on t.JBCo = n.JBCo and t.BillMonth = n.BillMonth and t.BillNumber = n.BillNumber and t.Item = d.Item
where m.ClosePurgeFlag <> 'Y'
if @validcnt <> 0
	begin
	select @errmsg = 'Contract Item exists in Job Billing'
	goto error
	end

---- Check bARTL for Job phases assigned to contract item(s) - Issue #123670
SELECT @validcnt = count(*) FROM deleted d
JOIN bJCCO c with (nolock) on c.JCCo = d.JCCo
JOIN bJCCM m with (nolock) on c.JCCo = d.JCCo and m.Contract = d.Contract
JOIN bARTL a with (nolock) on a.ARCo = c.ARCo and a.Contract = d.Contract and a.Item = d.Item
WHERE m.ClosePurgeFlag <> 'Y'
IF @validcnt <> 0
BEGIN
	SELECT @errmsg = 'Contract Item exists in AR Transaction Lines'
	GOTO error
END


---- CURSOR BEGIN - Issue #123670
	declare bcContractTotal cursor LOCAL FAST_FORWARD for select Mth 
   	from bJCID j join deleted d on j.JCCo = d.JCCo and j.Contract = d.Contract and j.Item = d.Item
   
   	open bcContractTotal
   
   	FetchNext:
   	fetch next from bcContractTotal into @mth
   	if @@fetch_status <> 0  goto EndActual
   
   	---- Check bJCID to make sure that ContractAmt nets to zero before deleting record - Issue #123670
	SELECT @ContractAmt = SUM(j.ContractAmt), @BilledAmt = SUM(j.BilledAmt), @ReceivedAmt = SUM(j.ReceivedAmt), 
		@CurrentRetainAmt = SUM(j.CurrentRetainAmt), @BilledTax = SUM(j.BilledTax), 
		@ProjDollars = SUM(j.ProjDollars)
	FROM bJCID j with(nolock) JOIN deleted d on j.JCCo = d.JCCo and j.Contract = d.Contract and j.Item = d.Item and j.Mth = @mth
	WHERE j.JCTransType <> 'OC'
   
	---- Compute ContractTotal to see if it nets to zero
	SELECT @ContractTotal = @ContractAmt + @BilledAmt + @ReceivedAmt + @CurrentRetainAmt + @BilledTax + @ProjDollars

	IF @ContractTotal <> 0
	BEGIN
		SELECT @errmsg = 'Contract Item does not net to zero'
		GOTO error
	END
   
   	goto FetchNext
   
   	EndActual:
   	close bcContractTotal
   	deallocate bcContractTotal
---- CURSOR END


---- delete Original Contract bJCID
---- the only records left should be 'OC' which will now be deleted
delete bJCID
from bJCID join deleted d on d.JCCo=bJCID.JCCo and d.Contract=bJCID.Contract and d.Item=bJCID.Item

---- double check Item Detail  - nothing should be left
select @validcnt = count(*) from bJCID j with (nolock)
join deleted d on j.JCCo = d.JCCo and j.Contract = d.Contract and j.Item=d.Item
if @validcnt <> 0
	begin
	select @errmsg = 'Contract Item Detail exists'
	goto error
	end

---- delete bJCIP records - all amounts should be 0
delete bJCIP
from bJCIP j with (nolock) join deleted d on d.JCCo=j.JCCo and d.Contract=j.Contract and d.Item=j.Item


---- Audit deletes
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCCI', 'Co#: ' + convert(char(3), d.JCCo) + ' Cont: ' + d.Contract + ' Item: ' + d.Item,
d.JCCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted d join bJCCO c with (nolock) on d.JCCo=c.JCCo
where c.AuditContracts = 'Y'


return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete JC Contract Item!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCCIi    Script Date: 8/28/99 9:38:23 AM ******/
CREATE  TRIGGER [dbo].[btJCCIi] ON [dbo].[bJCCI] FOR INSERT AS
/**************************************************************
* Created By:   JRE 12/22/96
* Modified By:	JM 4/29/97 - Added validation of TaxCode by TaxGroup
*				JRE 5/5/97 - Removed cursor - causing trouble
*				GF 07/03/2001 - Use JCCO.AddJCSICode flag to insert new SI code into JCSI
*				DC 7/3/03  - Issue #21518 - Get trigger error if enter invalid std item code on existing item.
*				GF 10/26/2004 - issue #25828 clean-up trigger performance
*				GF 01/29/2008 - issue #126910 moved tax validation into cursor so contract item added to error msg
*				GF 02/05/2998 - issue #127025 fixed error in fetch next. deallocating cursor in wrong place
*				GF 11/18/2008 - issue #131??? minor changes for performance
*				GF 04/21/2009 - issue #132326 original estimates moved by JCCI start month
*				GF 06/30/2009 - issue #132326 set PostedDate = today's date in JCID
*
*
*
*
*	This trigger rejects insert in bJCCI (JC Cost Detail)
*	 if the following error condition exists:
*
*		invalid JCCM - Contract master
*              invalid JCDM - Department Master
*              invalid HQTX - TaxCode
*              invalid HQUM - Unit of Measure
*              invalid JCSI - Standard Item Code
*
*       UPDATEs JCID with Original Contract Amt, Units, UnitPrice
*
**************************************************************/
declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255),
		@jcco bCompany, @contract bContract, @item bContractItem,
		@itemtrans bTrans, @addjcsicode bYN, @siregion varchar(6), @sicode varchar(16), 
		@sidesc bDesc, @sium bUM, @siup bUnitCost, @opencursor tinyint,
		@taxcode bTaxCode, @taxgroup bGroup, @startmonth bMonth
   
SELECT @numrows = @@rowcount
if @numrows = 0 return
SET nocount on

set @opencursor = 0

declare @PostedDate bDate

set @PostedDate=convert(varchar(8),getdate(),1)
   
-- -- -- validate JCCM
select @validcnt = count(1) FROM bJCCM j WITH (NOLOCK)   --  DC changed Count(*) and added WITH (NOLOCK)
	join inserted i on j.JCCo=i.JCCo AND j.Contract=i.Contract
if @validcnt<>@numrows
	begin
	SELECT @errmsg = 'Invalid Contract'
	goto error
	end

-- -- -- validate HQUM
SELECT @validcnt=count(1) FROM bHQUM h WITH (NOLOCK)   --  DC changed Count(*) and added WITH (NOLOCK)
	join inserted i on h.UM=i.UM
if @validcnt<>@numrows
	begin
	SELECT @errmsg = 'Invalid UM'
	goto error
	end

-- -- -- validate Department
SELECT @validcnt=count(1) FROM bJCDM j WITH (NOLOCK)   --  DC changed Count(*) and added WITH (NOLOCK)
	join inserted i on j.JCCo = i.JCCo AND j.Department = i.Department
if @validcnt<>@numrows
	begin
	SELECT @errmsg = 'Invalid Department'
	goto error
	end


/*-------------------------------------------------------------------
* UPDATE bJCID records
* note: this is an UPDATE instead of an insert because we do not wish
* to keep history of changes to original estimates
*-------------------------------------------------------------------*/

---- add any bJCID records that do not exist
if @numrows = 1
	begin
	select @jcco=JCCo, @contract=Contract, @item=Item, @siregion=SIRegion, @sicode=SICode,
			@taxcode=TaxCode, @taxgroup=TaxGroup, @sidesc=Description, @sium=UM,
			@siup=OrigUnitPrice, @startmonth=StartMonth
	from inserted
	end
else
	begin
	-- use a cursor to process each updated row
	declare bJCCI_insert cursor LOCAL FAST_FORWARD
		for select JCCo, Contract, Item, SIRegion, SICode, TaxCode, TaxGroup,
			Description, UM, OrigUnitPrice, StartMonth
	from inserted

	open bJCCI_insert
	set @opencursor = 1

	fetch next from bJCCI_insert into @jcco, @contract, @item, @siregion, @sicode,
			@taxcode, @taxgroup, @sidesc, @sium, @siup, @startmonth

	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end
   
   
bJCCI_insert:

---- validate Tax Code
if isnull(@taxcode,'') <> ''
	begin
	if not exists(select 1 from bHQTX with (nolock) where TaxGroup=@taxgroup and TaxCode=@taxcode)
		begin
		select @errmsg = 'Invalid Tax Code for Contract Item: ' + isnull(@item,'') + '.'
		goto error
		end
	end


---- if @siregion and @sicode is not null insert row into bJCSI if auto add state item code
---- validate std item code after doing insert if needed
if isnull(@siregion,'') <> '' and isnull(@sicode,'') <> ''
	begin
	---- get AddJCSICode flag from bJCCO
	select @addjcsicode=AddJCSICode from bJCCO with (nolock) where JCCo=@jcco
	---- insert JCSI row for std item code if needed
	if @addjcsicode = 'Y'
		begin
		-- insert JCSI row if does not exists
		if not exists(select 1 from bJCSI with (nolock) where SIRegion=@siregion and SICode=@sicode)
			begin
			insert into bJCSI (SIRegion, SICode, Description, UM, MUM, UnitPrice)
			select @siregion, @sicode, @sidesc, @sium, null, @siup
			end
		end

	---- validate SICode
	if not exists(select 1 from bJCSI j with (nolock) where j.SIRegion = @siregion and j.SICode = @sicode)
		begin
		select @errmsg = 'Invalid Standard Item Region/Code'
		goto error
		end
	end


---- check if the original estimate record exists
IF not exists(select 1 from bJCID with (nolock)where JCCo=@jcco AND Contract=@contract AND Item=@item
				AND TransSource='JC OrigEst' AND JCTransType='OC')
	begin
	exec @itemtrans = dbo.bspHQTCNextTrans 'bJCID', @jcco, @startmonth, @errmsg output
	IF @itemtrans=0 goto error  -- error message comes FROM bspHQTCNextTrans
	insert into bJCID (JCCo,Mth,ItemTrans,Contract,Item,JCTransType,TransSource,
			Description,PostedDate,ActualDate,ContractAmt,ContractUnits,UnitPrice)
	select @jcco, @startmonth, @itemtrans, @contract, @item, 'OC', 'JC OrigEst',
			'Original Contract Amount', @PostedDate, @startmonth, 0, 0, 0
	end


if @numrows > 1
	begin
	fetch next from bJCCI_insert into @jcco, @contract, @item, @siregion, @sicode,
			@taxcode, @taxgroup, @sidesc, @sium, @siup, @startmonth
	if @@fetch_status = 0 goto bJCCI_insert

	close bJCCI_insert
	deallocate bJCCI_insert
	set @opencursor = 0
	end


-- -- -- update bJCID for JCTransType = 'OC'
update bJCID set ContractAmt=i.OrigContractAmt,
			 ContractUnits=i.OrigContractUnits,
			 UnitPrice=i.OrigUnitPrice
from inserted i join bJCID d on d.JCCo=i.JCCo and d.Contract=i.Contract and d.Item=i.Item
where d.TransSource = 'JC OrigEst' and d.JCTransType = 'OC'

---- update bJCCI
update bJCCI set ContractAmt=i.OrigContractAmt,
			 ContractUnits=i.OrigContractUnits,
			 UnitPrice=i.OrigUnitPrice,
			 BillOriginalAmt = i.OrigContractAmt,
			 BillOriginalUnits = i.OrigContractUnits
from inserted i join bJCCI c on c.JCCo=i.JCCo and c.Contract=i.Contract and c.Item=i.Item




-- -- -- Audit inserts
---- HQMA inserts
if not exists(select top 1 1 from inserted i join bJCCO c with (nolock) on i.JCCo=c.JCCo and c.AuditContracts='Y')
	begin
  	return
	end

insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) + ' Cont: ' + i.Contract + ' Item: ' + i.Item,
                i.JCCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bJCCO c with (nolock) on c.JCCo=i.JCCo
where i.JCCo = c.JCCo AND c.AuditContracts = 'Y'


return



error:
	if @opencursor = 1
		begin
		close bJCCI_insert
		deallocate bJCCI_insert
		set @opencursor = 0
		end
   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Contract Item!'
   	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************************************/
CREATE  TRIGGER [dbo].[btJCCIu] ON [dbo].[bJCCI] FOR UPDATE AS
/**************************************************************
* Created By:  JRE 12/22/96
* Modified By: JM  4/29/97 - Added validation of TaxCode by TaxGroup
*              JRE 5/05/97 - Removed cursor - causing trouble
*              GF 07/03/2001 - Use JCCO.AddJCSICode flag to insert new SI code into JCSI
*				allenn 03/19/02- issue 15396/16696...can't change BillType to 'N' if exists in JBIN
*				DC 7/3/03  #21518  - Get trigger error if enter invalid std item code on existing item.
*				RBT 08/11/03 - Issue #22004, audit additional fields.
*				RBT 09/19/03 - #22004, added isnull() to nullable values to enable auditing of fields changing to/from null.
*				TJL 01/02/09 - Issue #120173, Add HQMA auditing for new column InitAsZero
*				GF 04/21/2009 - issue #132326 original estimates moved by JCCI start month
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
*
*
*
*
* This trigger rejects insert in bJCCI (JC Cost Detail)
* if the following error condition exists:
*
* invalid JCCM - Contract master
*      invalid JCDM - Department Master
*      invalid HQTX - TaxCode
*      invalid HQUM - Unit of Measure
*      invalid JCSI - Standard Item Code
*
* UPDATEs JCID with Original Contract Amt, Units, UnitPrice
*
**************************************************************/
declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255), @opencursor tinyint,
		@JCCo tinyint, @Contract bContract, @Item bContractItem, @itemtrans bTrans,
		@addjcsicode bYN, @siregion varchar(6), @sicode varchar(16), @sidesc bDesc, @sium bUM,
		@siup bUnitCost, @startmonth bMonth, @oldstartmonth bMonth, @oldjcidtrans bTrans,
		@jcidtrans bTrans
--#142350 - renaming - @PostedDateOnly
declare @openjccd tinyint, @thrumonth bMonth, @jccdtrans bTrans, @oldjccdtrans bTrans,
		@job bJob, @phasegroup bGroup, @phase bPhase, @costtype bJCCType, @source bSource,
		@um bUM, @esthours bHrs, @estunits bUnits, @estcost bDollar, @postedum bUM,
		@deleteflag bYN, @jbbillstatus char(1), @jbbillmonth bMonth, @jbbillnumber int,
		@jccdmonth bMonth, @posteddate bDate, @jctranstype varchar(2), @description bTransDesc,
		@PostedDateOnly bDate


select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @opencursor = 0, @openjccd = 0

set @PostedDateOnly=convert(varchar(8),getdate(),1)

---- test if primarykey has changed
select @validcnt=count(1) from inserted i  --DC Removed Count(*)
               join deleted d on d.JCCo=i.JCCo and d.Contract=i.Contract and d.Item = i.Item
if @validcnt <> @numrows
	begin
	select @errmsg='Cannot change the Company, Contract, or Item'
	goto error
	end

---- validate JCCM
IF UPDATE(Contract)
	BEGIN
   SELECT @validcnt=count(1) FROM bJCCM j WITH (NOLOCK) --DC Removed Count(*) and added nolock
 		join inserted i on j.JCCo=i.JCCo AND j.Contract=i.Contract
 	if @validcnt<>@numrows
       begin
 		SELECT @errmsg = 'Invalid Contract'
 		goto error
 		end
	END

---- validate HQUM
if update(UM)
	BEGIN
 	if exists (select top 1 1 from bJCID j WITH (NOLOCK) join inserted i on j.JCCo=i.JCCo and j.Contract=i.Contract and j.Item=i.Item  --DC Removed Count(*) and added nolock
 	                 where JCTransType<>'OC' Having isnull(sum(j.BilledUnits),0) <> 0)
 		begin
 		select @errmsg = 'Item detail exist and Billed Units does not net to zero, cannot change the unit of measure'
 		goto error
 		end

   SELECT @validcnt=count(1) FROM bHQUM h WITH (NOLOCK) join inserted i on h.UM=i.UM  --DC Removed Count(*) and added nolock
   if @validcnt<>@numrows
 		begin
 		SELECT @errmsg = 'Invalid UM'
 		goto error
 		end
	END

---- validate Department
if update(Department)
   BEGIN
 	SELECT @validcnt=count(1) FROM bJCDM j WITH (NOLOCK)  --DC Removed Count(*) and added nolock
 		join inserted i on j.JCCo = i.JCCo AND j.Department = i.Department
 	if @validcnt<>@numrows
 		begin
 		SELECT @errmsg = 'Invalid Department'
 		goto error
 		end
 	end

----- validate Tax Code
if update(TaxGroup) or update(TaxCode)
	begin
	select @nullcnt=count(1) from inserted where TaxCode is NULL  --DC Removed Count(*)
	select @validcnt=count(1) from bHQTX h with (nolock) --DC Removed Count(*) and added nolock
	join inserted i on h.TaxGroup = i.TaxGroup AND h.TaxCode = i.TaxCode
	if @nullcnt + @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Tax Code'
		goto error
		end
	end



---- begin cursor
if @numrows = 1
	begin
	select @JCCo = i.JCCo, @Contract = i.Contract, @Item = i.Item,
			@startmonth = i.StartMonth, @oldstartmonth = d.StartMonth
	from inserted i join deleted d on d.JCCo=i.JCCo and d.Contract=i.Contract and d.Item=i.Item
	end
else
	begin
	-- use a cursor to process each updated row
	declare bJCCI_update cursor LOCAL FAST_FORWARD
			for select i.JCCo, i.Contract, i.Item, i.StartMonth, d.StartMonth
	from inserted i join deleted d on d.JCCo=i.JCCo and d.Contract=i.Contract and d.Item=i.Item

	open bJCCI_update
	set @opencursor = 0

	fetch next from bJCCI_update into @JCCo, @Contract, @Item, @startmonth, @oldstartmonth
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end

update_check:

---- get AddJCSICode flag from JCCO
select @addjcsicode=AddJCSICode from bJCCO with (nolock) where JCCo=@JCCo
---- insert JCSI row for std item code if needed
if @addjcsicode = 'Y'
	begin
	select @siregion=SIRegion, @sicode=SICode, @sidesc=Description, @sium=UM, @siup=OrigUnitPrice
	from inserted where JCCo=@JCCo and Contract=@Contract and Item=@Item
	if isnull(@siregion,'') <> '' and isnull(@sicode,'') <> ''
		begin
		-- -- -- insert JCSI row if does not exists
		if not exists(select top 1 1 from bJCSI with (nolock) where SIRegion=@siregion and SICode=@sicode)  --DC #21518
			begin
			insert into bJCSI (SIRegion, SICode, Description, UM, MUM, UnitPrice)
			select @siregion, @sicode, @sidesc, @sium, null, @siup
			end
		end
	end



/*************************************************************
* This section will move original estimates in JCID and JCCD *
* from the old start month to the new start monht            *
*************************************************************/
---- only update JCID & JCCD Original Estimates if StartMonth has changed
if @startmonth <> @oldstartmonth
	begin
	---- need to insert a new JCID row for the new month
	select @oldjcidtrans=ItemTrans from bJCID with (nolock)
	where JCCo=@JCCo and Contract=@Contract and Item=@Item and Mth=@oldstartmonth
	and TransSource='JC OrigEst' and JCTransType='OC'
	if @@rowcount <> 0
		begin
		---- get next JCID transaction
		exec @jcidtrans = dbo.bspHQTCNextTrans 'bJCID', @JCCo, @startmonth, @errmsg output
		if @jcidtrans = 0 goto error
		---- insert JCID record for new start month
		insert into bJCID (JCCo, Mth, ItemTrans, Contract, Item, JCTransType, TransSource,
				Description, PostedDate, ActualDate, ContractAmt, ContractUnits, UnitPrice,
				BilledUnits, BilledAmt, ReceivedAmt, CurrentRetainAmt, ReversalStatus)
		select @JCCo, @startmonth, @jcidtrans, @Contract, @Item, o.JCTransType, o.TransSource,
				o.Description, @PostedDateOnly, @startmonth, o.ContractAmt, o.ContractUnits, o.UnitPrice,
				o.BilledUnits, o.BilledAmt, o.ReceivedAmt, o.CurrentRetainAmt, o.ReversalStatus
		from bJCID o with (nolock)
		where o.JCCo=@JCCo and o.Contract=@Contract and o.Item=@Item and o.Mth=@oldstartmonth
		and o.TransSource='JC OrigEst' and o.JCTransType='OC'
		IF @@ERROR <> 0 goto error

		---- delete JCID record for old start month
		delete bJCID where JCCo=@JCCo and Contract=@Contract and Item=@Item
		and Mth=@oldstartmonth and ItemTrans=@oldjcidtrans
		if @@ERROR <> 0 goto error
		end

    if @oldstartmonth < @startmonth
		begin
        select @thrumonth = @startmonth
		end
    else
		begin
        select @thrumonth = @oldstartmonth
		end

    ---- create cursor on JCCD to update original estimates for change in start month
    ---- for all jobs that are assigned to the contract. Need to move all 'OE' records
    ---- that are <= new start month to new start month
    declare jccd_cursor cursor local fast_forward for
        select a.Mth, a.CostTrans, a.Job, a.PhaseGroup, a.Phase, a.CostType,
               a.JCTransType, a.Source, a.Description, a.UM, a.EstHours, a.EstUnits, a.EstCost,
               a.PostedUM, a.JBBillStatus, a.JBBillMonth, a.JBBillNumber, a.PostedDate
 	from bJCCD a
	join bJCJM b with (nolock) on b.JCCo=a.JCCo and b.Job=a.Job
	join bJCJP p with (nolock) on p.JCCo=a.JCCo and p.Job=a.Job and p.PhaseGroup=a.PhaseGroup and p.Phase=a.Phase
    where a.JCCo=@JCCo and a.Mth<=@thrumonth and a.JCTransType='OE' and b.Contract=@Contract
    and p.Item=@Item and (a.Source='JC OrigEst' or a.Source='PM Intface')

    open jccd_cursor
    select @openjccd = 1

    jccd_cursor_loop:
    fetch next from jccd_cursor into @jccdmonth, @oldjccdtrans, @job, @phasegroup, @phase,
			@costtype, @jctranstype, @source, @description, @um, @esthours, @estunits,
			@estcost, @postedum, @jbbillstatus, @jbbillmonth, @jbbillnumber, @posteddate

    if @@fetch_status <> 0 goto jccd_cursor_end

    ---- get if month has changed
    if @jccdmonth = @startmonth goto jccd_cursor_loop

    ---- get next JCCD transaction
    exec @jccdtrans = dbo.bspHQTCNextTrans 'bJCCD', @JCCo, @startmonth, @errmsg output
    if @jccdtrans = 0 goto error

    ---- insert JCCD record for new start month
    insert into bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
			ActualDate, JCTransType, Source, Description, ReversalStatus, UM, EstHours,
			EstUnits, EstCost, PostedUM, DeleteFlag, JBBillStatus, JBBillMonth, JBBillNumber)
    select @JCCo, @startmonth, @jccdtrans, @job, @phasegroup, @phase, @costtype, @PostedDateOnly,
			@startmonth, @jctranstype, @source, @description, 0, @um, @esthours, @estunits,
			@estcost, @postedum, 'N', @jbbillstatus, @jbbillmonth, @jbbillnumber
    IF @@ERROR <> 0 goto error

	---- delete JCCD record for old start month
	delete from bJCCD where JCCo=@JCCo and Mth=@jccdmonth and CostTrans=@oldjccdtrans
	if @@ERROR <> 0 goto error

	goto jccd_cursor_loop

    jccd_cursor_end:
        if @openjccd = 1
            begin
            close jccd_cursor
            deallocate jccd_cursor
            select @openjccd = 0
            end
	end



---- check if the original estimate reocrd exists in JCID for the item
if not exists(select top 1 1 from bJCID with (nolock) where JCCo=@JCCo and Contract=@Contract 
		and Item=@Item and TransSource='JC OrigEst' and JCTransType='OC')
	begin
	exec @itemtrans = dbo.bspHQTCNextTrans 'bJCID', @JCCo, @startmonth, @errmsg output
	if @itemtrans=0 goto error  -- error message comes FROM bspHQTCNextTrans
	---- insert JCID row
	insert into bJCID (JCCo, Mth, ItemTrans, Contract, Item, JCTransType, TransSource,
			Description, PostedDate, ActualDate, ContractAmt, ContractUnits, UnitPrice)
	select @JCCo, @startmonth, @itemtrans, @Contract, @Item, 'OC', 'JC OrigEst', 'Original Contract Amount',
			@PostedDateOnly, @startmonth, 0, 0, 0
	end



if @numrows > 1
	begin
	fetch next from bJCCI_update into @JCCo, @Contract, @Item, @startmonth, @oldstartmonth
	if @@fetch_status = 0 goto update_check
	---- close cursor
	close bJCCI_update
	deallocate bJCCI_update
	set @opencursor = 0
	end






---- now update JCID
update bJCID set ContractAmt=OrigContractAmt,
			 ContractUnits=OrigContractUnits,
			 UnitPrice=OrigUnitPrice
from inserted i
where bJCID.JCCo=i.JCCo and bJCID.Contract=i.Contract and bJCID.Item=i.Item
and bJCID.TransSource='JC OrigEst' and bJCID.JCTransType='OC'

---- now update JCCI
update bJCCI
set ContractAmt = bJCCI.ContractAmt + i.OrigContractAmt - d.OrigContractAmt,
	ContractUnits = bJCCI.ContractUnits + i.OrigContractUnits - d.OrigContractUnits,
	UnitPrice = i.OrigUnitPrice,
	BillOriginalAmt = bJCCI.BillOriginalAmt + i.OrigContractAmt - d.OrigContractAmt,
	BillOriginalUnits = bJCCI.BillOriginalUnits + i.OrigContractUnits - d.OrigContractUnits
from inserted i, deleted d
where bJCCI.JCCo=i.JCCo and bJCCI.Contract=i.Contract and bJCCI.Item=i.Item
and d.JCCo=i.JCCo and d.Contract=i.Contract and d.Item=i.Item
   
   
   
   
---- Audit inserts
IF UPDATE(Description)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.Description,'')<>isnull(i.Description,'')
	END

IF UPDATE(Department)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'Department',  d.Department, i.Department, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.Department,'')<>isnull(i.Department,'')
	END

IF UPDATE(TaxGroup)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'TaxGroup',  convert(varchar(30),d.TaxGroup), convert(varchar(30),i.TaxGroup), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.TaxGroup,0)<>isnull(i.TaxGroup,0)
	END

IF UPDATE(TaxCode)
	BEGIN
	INSERT INTO bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'TaxCode',  d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.TaxCode,'')<>isnull(i.TaxCode,'')
	END

IF UPDATE(UM)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'UM',  d.UM, i.UM, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.UM,'')<>isnull(i.UM,'')
	END

IF UPDATE(SIRegion)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 		SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
						  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
 		'SIRegion',  d.SIRegion, i.SIRegion, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.SIRegion,'')<>isnull(i.SIRegion,'')
	END

IF UPDATE(SICode)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'SICode',  d.SICode, i.SICode, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.SICode,'')<>isnull(i.SICode,'')
	END

IF UPDATE(RetainPCT)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'RetainPCT',  convert(varchar(30),d.RetainPCT), convert(varchar(30),i.RetainPCT), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.RetainPCT<>i.RetainPCT
	END

IF UPDATE(OrigContractAmt)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'OrigContractAmt',  convert(varchar(30),d.OrigContractAmt), convert(varchar(30),i.OrigContractAmt), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.OrigContractAmt<>i.OrigContractAmt
	END

IF UPDATE(OrigContractUnits)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'OrigContractUnits',  convert(varchar(30),d.OrigContractUnits), convert(varchar(30),i.OrigContractUnits), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.OrigContractUnits<>i.OrigContractUnits
	END

IF UPDATE(OrigUnitPrice)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'OrigUnitPrice',  convert(varchar(30),d.OrigUnitPrice), convert(varchar(30),i.OrigUnitPrice), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.OrigUnitPrice<>i.OrigUnitPrice
	END

IF UPDATE(BillType)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'BillType',  d.BillType, i.BillType, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.BillType,'')<>isnull(i.BillType,'')
	END

IF UPDATE(BillGroup)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'BillGroup',  d.BillGroup, i.BillGroup, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.BillGroup,'')<>isnull(i.BillGroup,'')
	END

IF UPDATE(BillDescription)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'BillDescription',  d.BillDescription, i.BillDescription, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.BillDescription,'')<>isnull(i.BillDescription,'')
	END

IF UPDATE(BillOriginalUnits)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'BillOriginalUnits',  convert(varchar(30),d.BillOriginalUnits), convert(varchar(30),i.BillOriginalUnits), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.BillOriginalUnits<>i.BillOriginalUnits
	END

IF UPDATE(BillOriginalAmt)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'BillOriginalAmt',  convert(varchar(30),d.BillOriginalAmt), convert(varchar(30),i.BillOriginalAmt), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.BillOriginalAmt<>i.BillOriginalAmt
	END

IF UPDATE(BillCurrentUnits)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'BillCurrentUnits',  convert(varchar(30),d.BillCurrentUnits), convert(varchar(30),i.BillCurrentUnits), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.BillCurrentUnits<>i.BillCurrentUnits
	END

IF UPDATE(BillCurrentAmt)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'BillCurrentAmt',  convert(varchar(30),d.BillCurrentAmt), convert(varchar(30),i.BillCurrentAmt), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.BillCurrentAmt<>i.BillCurrentAmt
	END

IF UPDATE(BillUnitPrice)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'BillUnitPrice',  convert(varchar(30),d.BillUnitPrice), convert(varchar(30),i.BillUnitPrice), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.BillUnitPrice<>i.BillUnitPrice
	END

IF UPDATE(UnitPrice)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'UnitPrice',  convert(varchar(30),d.UnitPrice), convert(varchar(30),i.UnitPrice), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE d.UnitPrice<>i.UnitPrice
	END

IF UPDATE(InitSubs)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'InitSubs',  d.InitSubs, i.InitSubs, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.InitSubs,'') <> isnull(i.InitSubs,'')
	END

IF UPDATE(StartMonth)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
					  ' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
	'StartMonth',  convert(varchar(30),d.StartMonth), convert(varchar(30),i.StartMonth), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.StartMonth,'')<>isnull(i.StartMonth,'')
	END

IF UPDATE(MarkUpRate)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) + ' Contract: ' + isnull(i.Contract,'') +' Item: ' + isnull(i.Item,''),
		i.JCCo, 'C', 'MarkUpRate', isnull(convert(varchar(16),d.MarkUpRate),''), isnull(convert(varchar(16),i.MarkUpRate),''), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.MarkUpRate,'') <> isnull(i.MarkUpRate,'')
	END

IF UPDATE(InitAsZero)
	BEGIN
	INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCCI','JC Co#: ' + convert(char(3), i.JCCo) +
			' Cont: ' + i.Contract +' Item: ' + i.Item, i.JCCo, 'C',
			'InitAsZero',  d.InitAsZero, i.InitAsZero, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract AND d.Item=i.Item
	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.InitAsZero,'') <> isnull(i.InitAsZero,'')
	END



return


error:
	if @opencursor = 1
		begin
		close bJCCI_update
		deallocate bJCCI_update
   		set @opencursor = 0
		end

	SELECT @errmsg = isnull(@errmsg,'') + ' - cannot update JCCI!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
   
   
  
 




GO
ALTER TABLE [dbo].[bJCCI] WITH NOCHECK ADD CONSTRAINT [CK_bJCCI_BillType] CHECK (([BillType]='T' OR [BillType]='P' OR [BillType]='B' OR [BillType]='N' OR [BillType] IS NULL))
GO
ALTER TABLE [dbo].[bJCCI] WITH NOCHECK ADD CONSTRAINT [CK_bJCCI_InitSubs] CHECK (([InitSubs]='Y' OR [InitSubs]='N'))
GO
ALTER TABLE [dbo].[bJCCI] WITH NOCHECK ADD CONSTRAINT [CK_bJCCI_ProjPlug] CHECK (([ProjPlug]='Y' OR [ProjPlug]='N'))
GO
CREATE NONCLUSTERED INDEX [IX_bJCCI_ItemContract] ON [dbo].[bJCCI] ([Contract], [Item]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCCI] ON [dbo].[bJCCI] ([JCCo], [Contract], [Item]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCCI] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
